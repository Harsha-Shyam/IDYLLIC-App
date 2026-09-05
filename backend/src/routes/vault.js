const express = require('express');
const router = express.Router();
const db = require('../db');
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, path.join(__dirname, '../../uploads'));
    },
    filename: (req, file, cb) => {
        cb(null, uuidv4() + path.extname(file.originalname));
    }
});
const upload = multer({ storage });

router.post('/upload', upload.single('document'), async (req, res) => {
    try {
        const userId = req.headers['x-user-id'];
        const { label, document_type } = req.body;
        
        if (!userId || !label || !document_type || !req.file) {
            return res.status(400).json({ error: 'Missing required fields or document' });
        }

        const storage_ref = `/uploads/${req.file.filename}`;

        const docRes = await db.query(
            `INSERT INTO vault_documents (user_id, document_type, label, storage_ref) 
             VALUES ($1, $2, $3, $4) RETURNING document_id`,
            [userId, document_type, label, storage_ref]
        );

        res.status(201).json({ 
            success: true, 
            document_id: docRes.rows[0].document_id,
            message: 'Document securely uploaded to vault'
        });
    } catch (error) {
        console.error('Error uploading to vault:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.get('/', async (req, res) => {
    try {
        const userId = req.headers['x-user-id'];
        if (!userId) return res.status(401).json({ error: 'Unauthorized' });

        const result = await db.query(
            `SELECT * FROM vault_documents WHERE user_id = $1 ORDER BY created_at DESC`,
            [userId]
        );
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching vault docs:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
