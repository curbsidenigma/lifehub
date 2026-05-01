# LifeHub — Modelo de datos

> Estado actual del modelo en Notion y plan de migración a Postgres.

## Notion (estado actual — fuente de captura)

Ubicación: `Life Hub 2.0 → Finances`.

### `FIN_FACTTRANSACTIONS`

Tabla de hechos: una transacción por renglón.

| Columna | Tipo | Notas |
|---|---|---|
| `TransactionId` | title | Ej. `TRN2026042411` |
| `Date` | date (DD/MM/YYYY) | Fecha de la transacción |
| `Type` | select | `Income`, `Withholding`, `Payment - Full`, `Payment - MSI`, `Payment - MCI` |
| `Amount` | formula | Calculado a partir de `AmountSum` y `Type` |
| `AmountSum` | rollup (sum) | Suma de `Amount` desde `Items` |
| `Account` | relation → `FIN_DIMACCOUNTS` | Cuenta asociada (limit 1) |
| `Category` | relation → `FIN_DIMCATEGORY` | Categoría (limit 1) |
| `Items` | relation → `FIN_FACTTRANSACTIONSITEMS` | Items de la transacción |
| `Place` | text | Lugar |
| `Installments` | number | Número de mensualidades (vacío o 1 = pago único) |

### `FIN_FACTTRANSACTIONSITEMS`

Detalle de la transacción. Una compra a 12 MSI puede tener 12 items.

(Esquema completo pendiente de documentar; revisar al iniciar Fase 1 Semana 2.)

### `FIN_DIMACCOUNTS`

Dimensión de cuentas (débito y crédito).

| Columna | Tipo | Notas |
|---|---|---|
| `Account` | title | Nombre |
| `AccountId` | number | |
| `AccountType` | select | `Debit`, `Credit` |
| `BankNumber` | text | |
| `PhysicalCardNumber` | text | |
| `VirtualCardNumber` | text | |
| `CreditLimit` | number (MXN) | Solo aplica a Credit |
| `Blocked` | status | `ACTIVE`, `INACTIVE`, `BLOCKED` |
| `AvailableAmount` | formula | Calculado |
| `Balance` | rollup (sum) | Suma desde transacciones |
| `Transactions` | relation | Inversa |

### `FIN_DIMCATEGORY`

(Pendiente de documentar.)

### Otras tablas

- `FIN_FACTPERDIEM`
- `FIN_FACTEXTRAPERDIEM`
- `FIN_FACTFIXEDSAVINGS`

(Pendientes de documentar; revisar cuando entren en scope del ETL.)

## Postgres (target — modelo destino)

### Schema `shared`

```sql
CREATE SCHEMA IF NOT EXISTS shared;

CREATE TABLE shared.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    display_name TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Owner por defecto en single-user mode
INSERT INTO shared.users (id, email, display_name)
VALUES ('00000000-0000-0000-0000-000000000001', 'owner@local', 'Owner');
```

### Schema `finance`

```sql
CREATE SCHEMA IF NOT EXISTS finance;

CREATE TABLE finance.dim_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES shared.users(id),
    notion_id TEXT UNIQUE NOT NULL,
    account_name TEXT NOT NULL,
    account_type TEXT NOT NULL CHECK (account_type IN ('debit', 'credit')),
    bank_number TEXT,
    credit_limit NUMERIC(12, 2),
    status TEXT CHECK (status IN ('active', 'inactive', 'blocked')),
    -- Reglas de pago de tarjeta de crédito (calculadas/asignadas en DB, no en Notion)
    cutoff_day SMALLINT CHECK (cutoff_day BETWEEN 1 AND 31),
    due_day SMALLINT CHECK (due_day BETWEEN 1 AND 31),
    due_month_offset SMALLINT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE finance.fact_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES shared.users(id),
    notion_id TEXT UNIQUE NOT NULL,
    transaction_code TEXT NOT NULL,  -- ej. TRN2026042411
    transaction_date DATE NOT NULL,
    transaction_type TEXT NOT NULL CHECK (
        transaction_type IN ('income', 'withholding', 'payment_full', 'payment_msi', 'payment_mci')
    ),
    account_id UUID REFERENCES finance.dim_accounts(id),
    place TEXT,
    installments SMALLINT,
    amount NUMERIC(12, 2),  -- denormalizado del rollup de Notion para queries rápidos
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_transactions_date ON finance.fact_transactions(transaction_date);
CREATE INDEX idx_transactions_account ON finance.fact_transactions(account_id);
```

(Tabla `fact_transaction_items` y `dim_categories` se agregan en Semana 2.)

### Vistas / lógica derivada

Estas se construyen en Semana 3, no en la migración inicial:

- `finance.v_transactions_with_payment_date`: vista que calcula la fecha
  de afectación real según `account_type`, `cutoff_day`, `due_day`, etc.
- `finance.v_monthly_summary`: agregaciones por mes/quincena.

## Mapping Notion → Postgres

| Notion (FIN_FACTTRANSACTIONS) | Postgres (finance.fact_transactions) | Transformación |
|---|---|---|
| `TransactionId` | `transaction_code` | Directo |
| `Date` | `transaction_date` | Parse a DATE |
| `Type` | `transaction_type` | `lower()` + reemplazar ` - ` por `_` |
| `Amount` (formula) | `amount` | Directo |
| `Account` (relation) | `account_id` | Resolver `notion_id` → UUID interno |
| `Place` | `place` | Directo |
| `Installments` | `installments` | Directo |
| (page id de Notion) | `notion_id` | Identificador estable |

## Reglas de transformación específicas

### Mapping de `Type`

```python
TYPE_MAP = {
    "Income": "income",
    "Withholding": "withholding",
    "Payment - Full": "payment_full",
    "Payment - MSI": "payment_msi",
    "Payment - MCI": "payment_mci",
}
```

### Cálculo de fecha de afectación (Semana 3)

Pseudocódigo de lo que vivirá en SQL:

```
Si account.account_type = 'debit':
    payment_date = transaction_date

Si account.account_type = 'credit':
    Si transaction_date.day <= account.cutoff_day:
        ciclo_mes = transaction_date.month
    Si no:
        ciclo_mes = transaction_date.month + 1

    payment_date = fecha(
        año = ciclo_mes_año + (1 si due_day < cutoff_day else 0) + due_month_offset,
        mes = ciclo_mes + (1 si due_day < cutoff_day else 0) + due_month_offset,
        día = due_day
    )
```

(Edge cases de fin de mes y fines de semana: pendiente de definir, va en
ADR cuando se implemente.)
