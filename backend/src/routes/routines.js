const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/', async (req, res) => {
    try {
        const userId = req.headers['x-user-id'];
        if (!userId) return res.status(401).json({ error: 'Unauthorized' });

        // Fetch active routines
        const result = await db.query(
            `SELECT * FROM routines WHERE user_id = $1 AND active = true`,
            [userId]
        );
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching routines:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.post('/confirm', async (req, res) => {
    try {
        const userId = req.headers['x-user-id'];
        const { routine_id } = req.body;

        if (!userId || !routine_id) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Just insert a generic confirmation for now
        await db.query(
            `INSERT INTO routine_confirmations (routine_id, scheduled_at, confirmed, responded_at) 
             VALUES ($1, NOW(), true, NOW())`,
            [routine_id]
        );

        res.status(200).json({ success: true, message: 'Routine confirmed' });
    } catch (error) {
        console.error('Error confirming routine:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.post('/add', async (req, res) => {
    try {
        const userId = req.headers['x-user-id'];
        const { label, routine_type, schedule_cron } = req.body;

        if (!userId || !label || !routine_type || !schedule_cron) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        const result = await db.query(
            `INSERT INTO routines (user_id, label, routine_type, schedule_cron) 
             VALUES ($1, $2, $3, $4) RETURNING routine_id`,
            [userId, label, routine_type, schedule_cron]
        );

        res.status(201).json({ success: true, routine_id: result.rows[0].routine_id });
    } catch (error) {
        console.error('Error adding routine:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
