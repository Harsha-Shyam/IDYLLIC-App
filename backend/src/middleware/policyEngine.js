const db = require('../db/pool');
const auditService = require('../services/auditService');

class PolicyEngine {
    /**
     * Checks if the actor is allowed to perform the action on the resource_scope.
     */
    async check(userId, actorPersonId, resourceScope, action) {
        // Simplified check for the MVP: owner is always allowed.
        // If actorPersonId is null or matches the owner's self_person_id, allow.
        // In a full implementation, we query `access_policies`.
        
        let decision = 'deny';
        try {
            const { rows } = await db.query(
                `SELECT self_person_id FROM users WHERE user_id = $1`,
                [userId]
            );
            
            const selfPersonId = rows[0]?.self_person_id;
            
            if (!actorPersonId || actorPersonId === selfPersonId) {
                decision = 'allow';
            } else {
                // Check access_policies
                const policyResult = await db.query(
                    `SELECT granted FROM access_policies ap
                     JOIN trusted_network tn ON tn.network_id = ap.network_id
                     WHERE ap.user_id = $1 AND tn.person_id = $2 
                       AND ap.resource_scope = $3 AND ap.action = $4
                       AND ap.revoked_at IS NULL`,
                    [userId, actorPersonId, resourceScope, action]
                );
                
                if (policyResult.rows.length > 0 && policyResult.rows[0].granted) {
                    decision = 'allow';
                }
            }
        } catch (error) {
            console.error('Policy Engine Error:', error);
            decision = 'deny';
        }

        // Always log the decision
        await auditService.logAccess(userId, actorPersonId, null, resourceScope, action, decision);
        
        return decision === 'allow';
    }
}

module.exports = new PolicyEngine();
