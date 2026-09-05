const express = require('express');
const router = express.Router();
const db = require('../db');
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Configure multer for disk storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, path.join(__dirname, '../../uploads'));
    },
    filename: (req, file, cb) => {
        cb(null, uuidv4() + path.extname(file.originalname));
    }
});
const upload = multer({ storage });

router.post('/add', upload.single('photo'), async (req, res) => {
    try {
        const userId = req.headers['x-user-id'];
        const { name, relation_label } = req.body;
        const photo_ref = req.file ? `/uploads/${req.file.filename}` : null;

        if (!userId || !name || !relation_label) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Get user's self_person_id
        const userRes = await db.query('SELECT self_person_id FROM users WHERE user_id = $1', [userId]);
        const selfPersonId = userRes.rows[0]?.self_person_id;

        if (!selfPersonId) {
            return res.status(400).json({ error: 'User does not have a self_person_id assigned' });
        }

        // Insert into people table
        const personRes = await db.query(
            `INSERT INTO people (owner_user_id, name, photo_ref) 
             VALUES ($1, $2, $3) RETURNING person_id`,
            [userId, name, photo_ref]
        );
        const newPersonId = personRes.rows[0].person_id;

        // Insert into relationships table (Patient -> New Person)
        await db.query(
            `INSERT INTO relationships (owner_user_id, from_person_id, to_person_id, relation_label) 
             VALUES ($1, $2, $3, $4)`,
            [userId, selfPersonId, newPersonId, relation_label]
        );

        res.status(201).json({ 
            success: true, 
            person_id: newPersonId,
            message: 'Person and relationship added successfully'
        });
    } catch (error) {
        console.error('Error adding family member:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.get('/', async (req, res) => {
    try {
        const userId = req.headers['x-user-id'];
        if (!userId) return res.status(401).json({ error: 'Unauthorized' });

        const query = `
            SELECT p.person_id, p.name, p.photo_ref, r.relation_label
            FROM people p
            JOIN relationships r ON p.person_id = r.to_person_id
            WHERE p.owner_user_id = $1 AND r.from_person_id = (SELECT self_person_id FROM users WHERE user_id = $1)
        `;
        const result = await db.query(query, [userId]);
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching family:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
