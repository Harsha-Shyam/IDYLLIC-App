const express = require('express');
const dotenv = require('dotenv');
const memoryRoutes = require('./routes/memories');
const familyRoutes = require('./routes/family');
const vaultRoutes = require('./routes/vault');
const routinesRoutes = require('./routes/routines');
const path = require('path');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Routes
app.use('/memories', memoryRoutes);
app.use('/family', familyRoutes);
app.use('/vault', vaultRoutes);
app.use('/routines', routinesRoutes);

app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
