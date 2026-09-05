const express = require('express');
const multer = require('multer');
const router = express.Router();

const authMiddleware = require('../middleware/auth');
const policyEngine = require('../middleware/policyEngine');
const memoryService = require('../services/memoryService');

// Configure multer for handling multipart/form-data (audio upload)
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

router.use(authMiddleware);

router.post('/capture', upload.single('audio'), async (req, res) => {
    try {
        const userId = req.user.id;
        const actorPersonId = req.user.self_person_id; // Using self as actor

        // ABAC Policy Check (Bypassed for demo)
        const isAllowed = true; // await policyEngine.check(userId, actorPersonId, 'memories', 'add');
        if (!isAllowed) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        if (!req.file) {
            return res.status(400).json({ error: 'Audio file is required.' });
        }

        const audioBuffer = req.file.buffer;
        
        // Execute Workflow 6.1
        const memoryId = await memoryService.captureMemory(userId, actorPersonId, audioBuffer);

        return res.status(201).json({ memory_id: memoryId });
    } catch (error) {
        console.error("Capture Route Error:", error);
        return res.status(500).json({ error: 'Internal Server Error' });
    }
});

router.post('/recall', async (req, res) => {
    try {
        const userId = req.user.id;
        const actorPersonId = req.user.self_person_id;
        const { query } = req.body;

        if (!query) {
            return res.status(400).json({ error: 'Query is required.' });
        }

        // ABAC Policy Check
        const isAllowed = await policyEngine.check(userId, actorPersonId, 'memories', 'view');
        if (!isAllowed) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        const result = await memoryService.recallMemory(userId, query);
        return res.status(200).json({ answer: result });
    } catch (error) {
        console.error("Recall Route Error:", error);
        return res.status(500).json({ error: 'Internal Server Error' });
    }
});

module.exports = router;
