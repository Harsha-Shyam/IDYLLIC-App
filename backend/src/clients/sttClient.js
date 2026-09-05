class STTClient {
    async transcribeAudio(audioBuffer) {
        // Mock Whisper API call
        // In reality, this would send the audioBuffer to OpenAI Whisper or similar
        return "I went to the park with my daughter Anu today. It was a beautiful sunny day.";
    }
}
module.exports = new STTClient();
