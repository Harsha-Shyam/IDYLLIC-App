const db = require('../db/pool');

class EntityResolutionService {
    /**
     * Resolves a named entity (person) from a memory context.
     * Uses pg_trgm for fuzzy string matching against name and aliases.
     * If not found, creates a new person record.
     */
    async resolvePerson(name, userId, client = db) {
        // Algorithm 6.4: Entity Resolution
        // 1. pg_trgm fuzzy match
        const result = await client.query(
            `SELECT person_id, name, similarity(name, $1) as sim 
             FROM people 
             WHERE owner_user_id = $2 
               AND (name % $1 OR $1 = ANY(aliases))
             ORDER BY sim DESC LIMIT 1`,
            [name, userId]
        );

        if (result.rows.length > 0) {
            const bestMatch = result.rows[0];
            // If the similarity is above a threshold, return existing person_id
            if (bestMatch.sim > 0.6) {
                return bestMatch.person_id;
            }
        }

        // 2. If no confident match, fallback logic: embedding-similarity cross-check 
        // (Stubbed for MVP: we go straight to creating a new person)
        
        // 3. Create new person
        const insertResult = await client.query(
            `INSERT INTO people (owner_user_id, name, aliases) 
             VALUES ($1, $2, ARRAY[$2]) RETURNING person_id`,
            [userId, name]
        );

        return insertResult.rows[0].person_id;
    }
}

module.exports = new EntityResolutionService();
