class EmbeddingClient {
    async generateEmbedding(text) {
        // Mock Embedding API call
        // Returns an array of 1536 floats
        return Array.from({ length: 1536 }, () => Math.random() * 2 - 1);
    }
}
module.exports = new EmbeddingClient();
