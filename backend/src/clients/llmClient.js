class LLMClient {
    async extractMemoryDetails(transcript) {
        // Mock LLM function calling
        // In reality, this would call Claude or GPT-4 with a tool schema to extract {what, when, where, who, why}
        return {
            what: "Went to the park",
            when: "Today",
            where: "The park",
            who: ["Anu"],
            why: "Enjoying a beautiful sunny day",
            title: "Park with Anu"
        };
    }
}
module.exports = new LLMClient();
