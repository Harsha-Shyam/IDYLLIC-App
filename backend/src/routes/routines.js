const express = require('express');
const router = express.Router();

router.get('/', async (req, res) => {
    return res.json([{ routine_id: 1, title: "Drink Water", time_of_day: "12:00", description: "Stay hydrated", is_completed: false }]);
});

router.post('/confirm', async (req, res) => {
    return res.json({ message: "Confirmed (Mocked)" });
});

module.exports = router;
