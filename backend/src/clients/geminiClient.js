const { GoogleGenAI } = require('@google/genai');

class GeminiClient {
    constructor() {
        // Fallback to a dummy key to prevent crashes if not provided
        this.ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || 'dummy_key' });
    }

    async transcribeAudio(audioBuffer) {
        try {
            if (!process.env.GEMINI_API_KEY) {
                return "Mocked Transcript: (Please set GEMINI_API_KEY in backend/.env to actually transcribe your speech!)";
            }
            
            const response = await this.ai.models.generateContent({
                model: 'gemini-2.5-flash',
                contents: [
                    {
                        role: 'user',
                        parts: [
                            { text: 'Please transcribe the following audio accurately.' },
                            { inlineData: { data: audioBuffer.toString('base64'), mimeType: 'audio/mp4' } }
                        ]
                    }
                ]
            });
            return response.text;
        } catch (error) {
            console.error("Gemini STT Error:", error);
            return "Failed to transcribe audio.";
        }
    }
}
module.exports = new GeminiClient();
