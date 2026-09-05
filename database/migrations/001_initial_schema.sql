-- ============================================================
-- IDYLLIC — PostgreSQL-only Schema (Flutter + Node.js stack)
-- Requires: CREATE EXTENSION IF NOT EXISTS vector;   -- pgvector
--           CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid()
-- ============================================================

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------
-- 1. USERS
-- ------------------------------------------------------------
CREATE TABLE users (
    user_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name    TEXT NOT NULL,
    date_of_birth   DATE,
    primary_language TEXT DEFAULT 'en',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- 2. PEOPLE (replaces Neo4j Person nodes)
-- ------------------------------------------------------------
CREATE TABLE people (
    person_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id   UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    aliases         TEXT[],              -- ["Mom", "Anu Krishnan"] — entity resolution
    photo_ref       TEXT,
    professional_role TEXT,              -- 'lawyer','doctor','financial_advisor', NULL
    known_from      TEXT,                -- free text
    is_deceased     BOOLEAN DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_people_owner ON people(owner_user_id);
-- Trigram index for fuzzy alias matching (Algorithm 10)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_people_name_trgm ON people USING gin (name gin_trgm_ops);

-- ------------------------------------------------------------
-- 3. RELATIONSHIPS (replaces Neo4j edges — adjacency-list pattern)
-- Self-referencing edge table; direction matters (from -> to).
-- ------------------------------------------------------------
CREATE TABLE relationships (
    relationship_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id   UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    from_person_id  UUID NOT NULL REFERENCES people(person_id) ON DELETE CASCADE,
    to_person_id    UUID NOT NULL REFERENCES people(person_id) ON DELETE CASCADE,
    relation_label  TEXT NOT NULL,        -- "daughter","son","lawyer_of","trusts"
    scope           TEXT[],               -- for TRUSTS-type edges: ["medical","legal"]
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (from_person_id, to_person_id, relation_label)
);
CREATE INDEX idx_relationships_from ON relationships(from_person_id);
CREATE INDEX idx_relationships_to ON relationships(to_person_id);

-- Convention: give every user a self-referencing row in people
ALTER TABLE users ADD COLUMN self_person_id UUID REFERENCES people(person_id);

-- ------------------------------------------------------------
-- 4. EVENTS + PLACES
-- ------------------------------------------------------------
CREATE TABLE meaningful_places (
    place_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    label           TEXT NOT NULL,
    place_type      TEXT CHECK (place_type IN
                        ('home','hospital','clinic','legal_office','family_home',
                         'restaurant','recreation','childhood','bucket_list','other')),
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    radius_meters   INTEGER NOT NULL DEFAULT 100,
    linked_person_id UUID REFERENCES people(person_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_places_user ON meaningful_places(user_id);

CREATE TABLE events (
    event_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    label           TEXT NOT NULL,
    event_type      TEXT,                 -- 'celebration','medical','visit','milestone','legal'
    occurred_on     DATE,
    place_id        UUID REFERENCES meaningful_places(place_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE event_participants (
    event_id        UUID NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
    person_id       UUID NOT NULL REFERENCES people(person_id) ON DELETE CASCADE,
    role_in_event   TEXT,
    PRIMARY KEY (event_id, person_id)
);

-- ------------------------------------------------------------
-- 5. MEMORIES + EMBEDDINGS (pgvector replaces external Vector DB)
-- ------------------------------------------------------------
CREATE TABLE memories (
    memory_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    title           TEXT,
    transcript      TEXT NOT NULL,
    occurred_on     DATE,
    location_text   TEXT,
    place_id        UUID REFERENCES meaningful_places(place_id),
    importance      TEXT NOT NULL DEFAULT 'ordinary'
                        CHECK (importance IN ('legacy','important','useful','ordinary')),
    embedding       VECTOR(1536),          -- dimension depends on embedding model chosen
    audio_vault_ref TEXT,                  -- pointer to encrypted original recording
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- IVFFlat or HNSW index for approximate nearest-neighbor search:
CREATE INDEX idx_memories_embedding ON memories
    USING hnsw (embedding vector_cosine_ops);

CREATE TABLE memory_people (
    memory_id       UUID NOT NULL REFERENCES memories(memory_id) ON DELETE CASCADE,
    person_id       UUID NOT NULL REFERENCES people(person_id) ON DELETE CASCADE,
    role_in_memory  TEXT,
    PRIMARY KEY (memory_id, person_id)
);

-- ------------------------------------------------------------
-- 6. IDENTITY / PREFERENCES / BUCKET LIST
-- ------------------------------------------------------------
CREATE TABLE preferences (
    preference_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category        TEXT NOT NULL CHECK (category IN
                        ('song','movie','book','food','restaurant','place',
                         'hobby','sport','artist','drink','other')),
    value           TEXT NOT NULL,
    weight          NUMERIC(3,2) DEFAULT 1.0,
    context_tags    TEXT[],
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_preferences_user ON preferences(user_id);

CREATE TABLE bucket_list (
    item_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    description     TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'wishlist'
                        CHECK (status IN ('wishlist','planning','planned','completed')),
    linked_memory_id UUID REFERENCES memories(memory_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- 7. ROUTINES / REMINDERS
-- ------------------------------------------------------------
CREATE TABLE routines (
    routine_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    routine_type    TEXT NOT NULL CHECK (routine_type IN
                        ('medication','water','meal','appointment','custom')),
    label           TEXT NOT NULL,
    schedule_cron   TEXT NOT NULL,
    dosage_notes    TEXT,
    linked_person_id UUID REFERENCES people(person_id),
    start_date      DATE,
    end_date        DATE,
    active          BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_routines_user_active ON routines(user_id, active);

CREATE TABLE routine_confirmations (
    confirmation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    routine_id      UUID NOT NULL REFERENCES routines(routine_id) ON DELETE CASCADE,
    scheduled_at    TIMESTAMPTZ NOT NULL,
    confirmed       BOOLEAN,
    responded_at    TIMESTAMPTZ,
    escalated       BOOLEAN NOT NULL DEFAULT false
);

-- ------------------------------------------------------------
-- 8. WELLBEING CHECK-INS
-- ------------------------------------------------------------
CREATE TABLE checkin_config (
    user_id         UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    frequency_hours INTEGER NOT NULL DEFAULT 6,
    quiet_hours_start TIME,
    quiet_hours_end   TIME,
    max_checkins_per_day INTEGER DEFAULT 4
);

CREATE TABLE checkins (
    checkin_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    raw_response    TEXT,
    sentiment_score NUMERIC(4,3),
    topic_tags      TEXT[],
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_checkins_user_time ON checkins(user_id, created_at);

CREATE TABLE wellbeing_flags (
    flag_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    flag_type       TEXT NOT NULL,
    window_start    TIMESTAMPTZ NOT NULL,
    window_end      TIMESTAMPTZ NOT NULL,
    detail          JSONB,
    routed_to       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- 9. HEALTH ESCALATION
-- ------------------------------------------------------------
CREATE TABLE escalation_rules (
    rule_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    keyword_pattern TEXT NOT NULL,
    severity        TEXT NOT NULL CHECK (severity IN ('low','medium','high','critical')),
    route_to        TEXT[] NOT NULL,
    escalate_to_emergency BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE escalation_events (
    event_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    rule_id         UUID REFERENCES escalation_rules(rule_id),
    reported_text   TEXT NOT NULL,
    matched_severity TEXT,
    routed_to       TEXT[],
    dispatched_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    acknowledged_at TIMESTAMPTZ
);

-- ------------------------------------------------------------
-- 10. TRUSTED NETWORK + RBAC/ABAC
-- ------------------------------------------------------------
CREATE TABLE trusted_network (
    network_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    person_id       UUID NOT NULL REFERENCES people(person_id) ON DELETE CASCADE,
    role            TEXT NOT NULL CHECK (role IN
                        ('lawyer','doctor','financial_advisor','trusted_person','caregiver')),
    display_label   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE access_policies (
    policy_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    network_id      UUID NOT NULL REFERENCES trusted_network(network_id) ON DELETE CASCADE,
    resource_scope  TEXT NOT NULL CHECK (resource_scope IN
                        ('legal','medical','financial','memories','routines',
                         'wellbeing','location','emergency_alerts','summaries')),
    action          TEXT NOT NULL CHECK (action IN ('view','add','update','share','delete')),
    granted         BOOLEAN NOT NULL DEFAULT true,
    granted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at      TIMESTAMPTZ
);
CREATE INDEX idx_access_policies_lookup ON access_policies(user_id, network_id, resource_scope, action);

-- ------------------------------------------------------------
-- 11. SECURE VAULT (metadata; files in S3/Firebase Storage, encrypted)
-- ------------------------------------------------------------
CREATE TABLE vault_documents (
    document_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    document_type   TEXT NOT NULL CHECK (document_type IN
                        ('identity','legal','property','financial','medical','other')),
    label           TEXT NOT NULL,
    storage_ref     TEXT NOT NULL,
    uploaded_by_person_id UUID REFERENCES people(person_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_vault_user_type ON vault_documents(user_id, document_type);

-- ------------------------------------------------------------
-- 12. AUDIT LOG (append-only)
-- ------------------------------------------------------------
CREATE TABLE audit_log (
    audit_id        BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    actor_person_id UUID REFERENCES people(person_id),  -- NULL = system
    actor_role      TEXT,
    resource_scope  TEXT NOT NULL,
    resource_id     TEXT,
    action          TEXT NOT NULL,
    decision        TEXT NOT NULL CHECK (decision IN ('allow','deny')),
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_user_time ON audit_log(user_id, occurred_at);
