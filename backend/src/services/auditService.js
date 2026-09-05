const db = require('../db/pool');

class AuditService {
    /**
     * Logs an access or action to the append-only audit_log table.
     */
    async logAccess(userId, actorPersonId, actorRole, resourceScope, action, decision, resourceId = null) {
        try {
            await db.query(
                `INSERT INTO audit_log (user_id, actor_person_id, actor_role, resource_scope, action, decision, resource_id)
                 VALUES ($1, $2, $3, $4, $5, $6, $7)`,
                [userId, actorPersonId, actorRole, resourceScope, action, decision, resourceId]
            );
        } catch (error) {
            console.error('Audit Log Error:', error);
            // In a strict environment, failing to audit might halt the request.
            // For MVP, we log and continue.
        }
    }
}

module.exports = new AuditService();
