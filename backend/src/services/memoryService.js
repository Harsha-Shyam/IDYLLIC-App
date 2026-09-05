const geminiClient = require('../clients/geminiClient');
const llmClient = require('../clients/llmClient');

class MemoryService {
    async captureMemory(userId, actorPersonId, audioBuffer) {
        try {
            // 1. Use Gemini to transcribe the audio!
            const transcript = await geminiClient.transcribeAudio(audioBuffer);
            console.log("Transcribed:", transcript);

            // 2. Return the transcript as the memory ID so the UI can show it for now
            return transcript;
        } catch (error) {
            console.error("Error capturing memory:", error);
            throw error;
        }
    }

    async recallMemory(userId, query) {
        return "Database is currently disabled. (Mocked Recall for: " + query + ")";
    }
}

module.exports = new MemoryService();
