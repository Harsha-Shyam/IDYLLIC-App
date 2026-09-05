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

router.post('/upload', upload.single('document'), async (req, res) => {
    return res.json({ id: 2, message: "Uploaded successfully (Mocked)" });
});

router.get('/', async (req, res) => {
    return res.json([{ id: 1, original_filename: "Mock_Doc.pdf", category: "identity", uploaded_at: new Date() }]);
});

module.exports = router;
