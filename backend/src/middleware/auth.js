// Mock auth middleware
// In a real app, this would verify a JWT and fetch the user.
const authMiddleware = (req, res, next) => {
    const authHeader = req.headers.authorization;
    // For MVP slice, mock a user if an ID is provided, else use a hardcoded dev UUID
    req.user = {
        id: req.headers['x-user-id'] || '00000000-0000-0000-0000-000000000001',
        self_person_id: '00000000-0000-0000-0000-000000000002', 
    };
    next();
};

module.exports = authMiddleware;
