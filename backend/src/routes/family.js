const express = require('express');
const router = express.Router();
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

router.post('/add', upload.single('photo'), async (req, res) => {
    return res.json({ id: 2, name: req.body.name, message: "Added successfully (Mocked)" });
});

router.get('/', async (req, res) => {
    return res.json([{ id: 1, name: "Anu", relation_label: "Daughter" }]);
});

module.exports = router;
