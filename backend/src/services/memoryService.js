const db = require('../db/pool');
const sttClient = require('../clients/sttClient');
const llmClient = require('../clients/llmClient');
const embeddingClient = require('../clients/embeddingClient');
const storageClient = require('../clients/storageClient');
const entityResolutionService = require('./entityResolutionService');
const auditService = require('./auditService');

class MemoryService {
    async captureMemory(userId, actorPersonId, audioBuffer) {
        const client = await db.getClient();
        try {
            await client.query('BEGIN');

            // 1. STT API -> transcript
            const transcript = await sttClient.transcribeAudio(audioBuffer);

            // 2. LLM API (function-calling) -> structured JSON
            const details = await llmClient.extractMemoryDetails(transcript);

            // 3. Embedding API -> vector
            const embeddingVector = await embeddingClient.generateEmbedding(transcript);

            // 4. Upload raw audio to Object Storage
            const storageRef = await storageClient.uploadAudio(audioBuffer, userId);

            // Convert array to pgvector string format '[v1, v2, ...]'
            const embeddingStr = `[${embeddingVector.join(',')}]`;

            // 5. Insert into memories
            const memoryResult = await client.query(
                `INSERT INTO memories (user_id, title, transcript, occurred_on, location_text, embedding, audio_vault_ref)
                 VALUES ($1, $2, $3, CURRENT_DATE, $4, $5, $6) RETURNING memory_id`,
                [userId, details.title, transcript, details.where, embeddingStr, storageRef]
            );
            const memoryId = memoryResult.rows[0].memory_id;

            // 6. Resolve each "who" via entity resolution and insert into memory_people
            if (details.who && details.who.length > 0) {
                for (const personName of details.who) {
                    const personId = await entityResolutionService.resolvePerson(personName, userId, client);
                    await client.query(
                        `INSERT INTO memory_people (memory_id, person_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
                        [memoryId, personId]
                    );
                }
            }

            // 7. Log audit
            await auditService.logAccess(userId, actorPersonId, null, 'memories', 'add', 'allow', memoryId);

            await client.query('COMMIT');
            return memoryId;
        } catch (error) {
            await client.query('ROLLBACK');
            console.error("Error capturing memory:", error);
            throw error;
        } finally {
            client.release();
        }
    }
    async recallMemory(userId, query) {
        const client = await db.getClient();
        try {
            // 1. Embed query
            const embeddingVector = await embeddingClient.generateEmbedding(query);
            const embeddingStr = `[${embeddingVector.join(',')}]`;

            // 2. Vector Search using <-> operator
            const result = await client.query(
                `SELECT transcript, title, occurred_on, location_text 
                 FROM memories 
                 WHERE user_id = $1 
                 ORDER BY embedding <-> $2 LIMIT 5`,
                [userId, embeddingStr]
            );

            // 3. Construct context
            const contextStr = result.rows.map(row => 
                `Date: ${row.occurred_on}, Location: ${row.location_text}\nTranscript: ${row.transcript}`
            ).join('\n\n');

            // 4. Synthesize answer with LLM
            const answer = await llmClient.synthesizeRecall(query, contextStr);
            return answer;
        } catch (error) {
            console.error("Error recalling memory:", error);
            throw error;
        } finally {
            client.release();
        }
    }
}

module.exports = new MemoryService();
