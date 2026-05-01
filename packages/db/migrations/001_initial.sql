-- ============================================================================
-- LifeHub — Migración inicial
-- ============================================================================
-- Crea schemas `shared` y `finance` con las tablas mínimas para Semana 1.
-- Tablas adicionales (items, categories) se agregan en Semana 2.
-- ============================================================================

-- Habilitar extensión para gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- SCHEMA: shared
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS shared;

CREATE TABLE IF NOT EXISTS shared.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    display_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Owner por defecto (single-user mode en Fase 1)
INSERT INTO shared.users (id, email, display_name)
VALUES ('00000000-0000-0000-0000-000000000001', 'owner@local', 'Owner')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SCHEMA: finance
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS finance;

-- ----------------------------------------------------------------------------
-- DIM: accounts
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS finance.dim_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES shared.users(id),
    notion_id TEXT UNIQUE NOT NULL,
    account_name TEXT NOT NULL,
    account_type TEXT NOT NULL CHECK (account_type IN ('debit', 'credit')),
    bank_number TEXT,
    physical_card_number TEXT,
    virtual_card_number TEXT,
    credit_limit NUMERIC(12, 2),
    status TEXT CHECK (status IN ('active', 'inactive', 'blocked')),
    -- Reglas de pago para tarjetas de crédito
    -- (calculadas en DB, NO capturadas en Notion — ver ADR 0001)
    cutoff_day SMALLINT CHECK (cutoff_day BETWEEN 1 AND 31),
    due_day SMALLINT CHECK (due_day BETWEEN 1 AND 31),
    due_month_offset SMALLINT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_dim_accounts_user
    ON finance.dim_accounts(user_id);

-- ----------------------------------------------------------------------------
-- FACT: transactions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS finance.fact_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES shared.users(id),
    notion_id TEXT UNIQUE NOT NULL,
    transaction_code TEXT NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_type TEXT NOT NULL CHECK (
        transaction_type IN (
            'income',
            'withholding',
            'payment_full',
            'payment_msi',
            'payment_mci'
        )
    ),
    account_id UUID REFERENCES finance.dim_accounts(id),
    place TEXT,
    installments SMALLINT,
    amount NUMERIC(12, 2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_date
    ON finance.fact_transactions(transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_account
    ON finance.fact_transactions(account_id);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_user
    ON finance.fact_transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_fact_transactions_type
    ON finance.fact_transactions(transaction_type);

-- ============================================================================
-- Verificación
-- ============================================================================
-- Después de aplicar esta migración, deberías ver:
--   SELECT schema_name FROM information_schema.schemata
--   WHERE schema_name IN ('shared', 'finance');
-- (2 filas)
--
--   SELECT table_schema, table_name FROM information_schema.tables
--   WHERE table_schema IN ('shared', 'finance');
-- (3 filas: shared.users, finance.dim_accounts, finance.fact_transactions)
