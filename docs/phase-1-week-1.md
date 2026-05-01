# Fase 1 — Semana 1: Walking Skeleton

> Plan detallado, día por día. Cada día es ~2-4 horas de trabajo.
> El objetivo de la semana es: **ver una transacción de Notion en una página
> web propia, end-to-end**.

## Definition of Done de la semana

Al terminar la semana, debe pasar lo siguiente desde un terminal limpio:

```bash
git clone <tu repo>
cd lifehub
cp .env.example .env  # llenar valores
docker compose up -d
cd apps/pipelines && uv sync && uv run python -m lifehub_pipelines.finance.main
cd ../api && uv sync && uv run uvicorn lifehub_api.main:app --reload &
cd ../web && pnpm install && pnpm dev
# Abrir http://localhost:3000/finance/transactions
# Ver tabla con tus transacciones reales de Notion
```

Si eso funciona: semana cerrada con éxito. Si no: refactor el sábado.

## Pre-requisitos antes del Día 1

- [ ] Docker Desktop instalado y corriendo.
- [ ] Python 3.12+ instalado (recomendado vía `uv` o `pyenv`).
- [ ] Node 20+ instalado.
- [ ] `uv` instalado (`curl -LsSf https://astral.sh/uv/install.sh | sh`).
- [ ] `pnpm` instalado (`npm install -g pnpm`).
- [ ] Cuenta de GitHub lista.
- [ ] Una integración interna de Notion creada con acceso a Life Hub 2.0
  (https://www.notion.so/profile/integrations).
- [ ] Token de la integración guardado en lugar seguro.

## Día 1 — Repo + Infraestructura local (2-3 hrs)

### Tarea 1.1 — Crear repo

```bash
mkdir lifehub && cd lifehub
git init
gh repo create lifehub --private --source=. --remote=origin
```

(Si prefieres GitHub web UI, también está bien.)

### Tarea 1.2 — Estructura inicial de carpetas

```bash
mkdir -p apps/api/src apps/web apps/pipelines/src docs/adr packages/db/migrations
touch README.md .gitignore .env.example
```

### Tarea 1.3 — Copiar archivos de documentación

Copiar a la raíz del repo:

- `CLAUDE.md`
- `docs/roadmap.md`
- `docs/architecture.md`
- `docs/data-model.md`
- `docs/progress.md`
- `docs/phase-1-week-1.md` (este archivo)

### Tarea 1.4 — `.gitignore`

Mínimo necesario:

```
# Python
__pycache__/
*.pyc
.venv/
.uv-cache/

# Node
node_modules/
.next/
dist/

# Env
.env
.env.local

# IDE
.vscode/
.idea/

# OS
.DS_Store
```

### Tarea 1.5 — `docker-compose.yml`

En la raíz:

```yaml
services:
  postgres:
    image: postgres:16
    container_name: lifehub_postgres
    environment:
      POSTGRES_DB: lifehub_dev
      POSTGRES_USER: lifehub
      POSTGRES_PASSWORD: lifehub_dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  adminer:
    image: adminer:latest
    container_name: lifehub_adminer
    ports:
      - "8080:8080"
    depends_on:
      - postgres

volumes:
  postgres_data:
```

### Tarea 1.6 — `.env.example`

```
# Postgres
DATABASE_URL=postgresql://lifehub:lifehub_dev_password@localhost:5432/lifehub_dev

# Notion
NOTION_TOKEN=secret_xxxxxxxxxxxxx
NOTION_DB_TRANSACTIONS=32adeebec9b180029cbbf7cfc614bbec

# API
API_HOST=0.0.0.0
API_PORT=8000

# Web
NEXT_PUBLIC_API_URL=http://localhost:8000
```

Crear `.env` localmente con los valores reales (sin commitear).

### Tarea 1.7 — Levantar Postgres

```bash
docker compose up -d
docker compose ps  # verificar que ambos servicios están up
```

Abrir Adminer en http://localhost:8080:
- Sistema: `PostgreSQL`
- Servidor: `postgres`
- Usuario: `lifehub`
- Contraseña: `lifehub_dev_password`
- Base de datos: `lifehub_dev`

### Tarea 1.8 — Migración inicial

Crear `packages/db/migrations/001_initial.sql` con el contenido de
`docs/data-model.md` (sección Postgres → schemas `shared` y `finance`,
solo `users`, `dim_accounts`, `fact_transactions`).

Aplicar manualmente desde Adminer o:

```bash
docker exec -i lifehub_postgres psql -U lifehub -d lifehub_dev < packages/db/migrations/001_initial.sql
```

### Commit del día

```bash
git add .
git commit -m "chore: initial repo setup with docker compose and docs"
git push -u origin main
```

## Día 2 — Pipeline mínimo Notion → JSON (3-4 hrs)

### Tarea 2.1 — Setup proyecto Python

```bash
cd apps/pipelines
uv init --package lifehub-pipelines
uv add notion-client python-dotenv pydantic
uv add --dev ruff
```

Estructura:

```
apps/pipelines/
├── pyproject.toml
├── README.md
└── src/
    └── lifehub_pipelines/
        ├── __init__.py
        └── finance/
            ├── __init__.py
            ├── notion_extractor.py
            └── main.py
```

### Tarea 2.2 — Cliente de Notion

`src/lifehub_pipelines/finance/notion_extractor.py`:

```python
import os
from notion_client import Client
from dotenv import load_dotenv

load_dotenv()

def get_notion_client() -> Client:
    token = os.getenv("NOTION_TOKEN")
    if not token:
        raise ValueError("NOTION_TOKEN no está configurado en .env")
    return Client(auth=token)

def fetch_transactions(client: Client, db_id: str) -> list[dict]:
    """Trae todas las transacciones de la base de Notion (sin paginación todavía)."""
    response = client.databases.query(database_id=db_id)
    return response["results"]
```

### Tarea 2.3 — Main script

`src/lifehub_pipelines/finance/main.py`:

```python
import json
import os
from pathlib import Path
from .notion_extractor import get_notion_client, fetch_transactions

def main():
    client = get_notion_client()
    db_id = os.getenv("NOTION_DB_TRANSACTIONS")
    if not db_id:
        raise ValueError("NOTION_DB_TRANSACTIONS no está configurado")

    transactions = fetch_transactions(client, db_id)

    output_path = Path("output_raw.json")
    with output_path.open("w") as f:
        json.dump(transactions, f, indent=2, default=str)

    print(f"Extraídas {len(transactions)} transacciones a {output_path}")

if __name__ == "__main__":
    main()
```

### Tarea 2.4 — Correr y validar

```bash
cd apps/pipelines
uv run python -m lifehub_pipelines.finance.main
```

Debería generar `output_raw.json` con tus transacciones reales. Inspeccionar
el JSON para entender la estructura que devuelve la Notion API.

### Commit del día

```bash
git add apps/pipelines
git commit -m "feat(pipelines): minimal Notion transaction extractor"
git push
```

## Día 3 — Pipeline → Postgres con SQLAlchemy (3-4 hrs)

### Tarea 3.1 — Agregar dependencias

```bash
cd apps/pipelines
uv add sqlalchemy psycopg[binary]
```

### Tarea 3.2 — Modelo SQLAlchemy

`src/lifehub_pipelines/finance/models.py`:

```python
from datetime import date, datetime
from uuid import UUID, uuid4
from sqlalchemy import String, Date, Numeric, SmallInteger, ForeignKey, DateTime
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase):
    pass

class FactTransaction(Base):
    __tablename__ = "fact_transactions"
    __table_args__ = {"schema": "finance"}

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID]
    notion_id: Mapped[str] = mapped_column(String, unique=True)
    transaction_code: Mapped[str]
    transaction_date: Mapped[date]
    transaction_type: Mapped[str]
    place: Mapped[str | None]
    installments: Mapped[int | None] = mapped_column(SmallInteger)
    amount: Mapped[float | None] = mapped_column(Numeric(12, 2))
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
```

### Tarea 3.3 — Transformación

`src/lifehub_pipelines/finance/transformer.py`:

```python
from datetime import datetime

TYPE_MAP = {
    "Income": "income",
    "Withholding": "withholding",
    "Payment - Full": "payment_full",
    "Payment - MSI": "payment_msi",
    "Payment - MCI": "payment_mci",
}

OWNER_USER_ID = "00000000-0000-0000-0000-000000000001"

def transform_transaction(notion_page: dict) -> dict:
    """Convierte una página de Notion en un dict listo para insertar."""
    props = notion_page["properties"]

    return {
        "user_id": OWNER_USER_ID,
        "notion_id": notion_page["id"],
        "transaction_code": _get_title(props.get("TransactionId")),
        "transaction_date": _get_date(props.get("Date")),
        "transaction_type": TYPE_MAP.get(_get_select(props.get("Type"))),
        "place": _get_rich_text(props.get("Place")),
        "installments": _get_number(props.get("Installments")),
        "amount": _get_formula_number(props.get("Amount")),
    }

def _get_title(prop: dict | None) -> str | None:
    if not prop or not prop.get("title"):
        return None
    return "".join(t["plain_text"] for t in prop["title"])

def _get_select(prop: dict | None) -> str | None:
    if not prop or not prop.get("select"):
        return None
    return prop["select"]["name"]

def _get_date(prop: dict | None):
    if not prop or not prop.get("date"):
        return None
    start = prop["date"]["start"]
    return datetime.fromisoformat(start).date()

def _get_rich_text(prop: dict | None) -> str | None:
    if not prop or not prop.get("rich_text"):
        return None
    return "".join(t["plain_text"] for t in prop["rich_text"])

def _get_number(prop: dict | None) -> int | None:
    if not prop:
        return None
    return prop.get("number")

def _get_formula_number(prop: dict | None) -> float | None:
    if not prop or not prop.get("formula"):
        return None
    return prop["formula"].get("number")
```

### Tarea 3.4 — Loader idempotente

`src/lifehub_pipelines/finance/loader.py`:

```python
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.dialects.postgresql import insert
from .models import FactTransaction

def get_engine():
    url = os.getenv("DATABASE_URL")
    if not url:
        raise ValueError("DATABASE_URL no configurado")
    return create_engine(url)

def upsert_transactions(rows: list[dict]) -> int:
    engine = get_engine()
    with Session(engine) as session:
        stmt = insert(FactTransaction).values(rows)
        stmt = stmt.on_conflict_do_update(
            index_elements=["notion_id"],
            set_={
                "transaction_code": stmt.excluded.transaction_code,
                "transaction_date": stmt.excluded.transaction_date,
                "transaction_type": stmt.excluded.transaction_type,
                "place": stmt.excluded.place,
                "installments": stmt.excluded.installments,
                "amount": stmt.excluded.amount,
            }
        )
        result = session.execute(stmt)
        session.commit()
        return result.rowcount
```

### Tarea 3.5 — Actualizar `main.py`

```python
import os
from .notion_extractor import get_notion_client, fetch_transactions
from .transformer import transform_transaction
from .loader import upsert_transactions

def main():
    client = get_notion_client()
    db_id = os.getenv("NOTION_DB_TRANSACTIONS")
    raw = fetch_transactions(client, db_id)

    rows = [transform_transaction(page) for page in raw]
    rows = [r for r in rows if r["transaction_code"]]  # filtrar incompletos

    count = upsert_transactions(rows)
    print(f"Upsertadas {count} transacciones")

if __name__ == "__main__":
    main()
```

### Tarea 3.6 — Correr y validar en Adminer

```bash
uv run python -m lifehub_pipelines.finance.main
```

Abrir Adminer → tabla `finance.fact_transactions` → ver datos.

### Commit del día

```bash
git commit -am "feat(pipelines): load transactions to Postgres with upsert"
```

## Día 4 — API mínima con FastAPI (2-3 hrs)

### Tarea 4.1 — Setup proyecto API

```bash
cd apps/api
uv init --package lifehub-api
uv add fastapi uvicorn[standard] sqlalchemy psycopg[binary] python-dotenv
```

### Tarea 4.2 — Estructura

```
apps/api/src/lifehub_api/
├── __init__.py
├── main.py
├── core/
│   ├── __init__.py
│   ├── config.py
│   └── db.py
└── modules/
    ├── __init__.py
    └── finance/
        ├── __init__.py
        ├── router.py
        └── schemas.py
```

### Tarea 4.3 — Config y DB

`core/config.py`:

```python
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
```

`core/db.py`:

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from .config import DATABASE_URL

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### Tarea 4.4 — Schemas (Pydantic)

`modules/finance/schemas.py`:

```python
from datetime import date, datetime
from uuid import UUID
from pydantic import BaseModel

class TransactionRead(BaseModel):
    id: UUID
    transaction_code: str
    transaction_date: date
    transaction_type: str
    place: str | None
    installments: int | None
    amount: float | None
    created_at: datetime

    class Config:
        from_attributes = True
```

### Tarea 4.5 — Router

`modules/finance/router.py`:

```python
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ...core.db import get_db
from .schemas import TransactionRead

router = APIRouter(prefix="/api/finance", tags=["finance"])

@router.get("/transactions", response_model=list[TransactionRead])
def list_transactions(db: Session = Depends(get_db)):
    rows = db.execute(text("""
        SELECT id, transaction_code, transaction_date, transaction_type,
               place, installments, amount, created_at
        FROM finance.fact_transactions
        ORDER BY transaction_date DESC
        LIMIT 50
    """)).mappings().all()
    return [dict(r) for r in rows]
```

### Tarea 4.6 — Main app

`main.py`:

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .modules.finance.router import router as finance_router

app = FastAPI(title="LifeHub API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(finance_router)

@app.get("/health")
def health():
    return {"status": "ok"}
```

### Tarea 4.7 — Correr y validar

```bash
uv run uvicorn lifehub_api.main:app --reload
```

Abrir:
- http://localhost:8000/health → `{"status": "ok"}`
- http://localhost:8000/api/finance/transactions → JSON con tus datos
- http://localhost:8000/docs → Swagger UI auto-generado

### Commit del día

```bash
git commit -am "feat(api): minimal FastAPI with finance transactions endpoint"
```

## Día 5 — Frontend mínimo Next.js (3-4 hrs)

### Tarea 5.1 — Setup Next.js

```bash
cd apps
pnpm create next-app@latest web
# Yes a TypeScript, Tailwind, App Router, src/, no a Turbopack/customizado
cd web
pnpm add @tanstack/react-query
```

### Tarea 5.2 — Provider de React Query

`src/app/providers.tsx`:

```tsx
"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useState } from "react";

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());
  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
}
```

`src/app/layout.tsx` — envolver children con `<Providers>`.

### Tarea 5.3 — Página de transacciones

`src/app/finance/transactions/page.tsx`:

```tsx
"use client";

import { useQuery } from "@tanstack/react-query";

type Transaction = {
  id: string;
  transaction_code: string;
  transaction_date: string;
  transaction_type: string;
  place: string | null;
  amount: number | null;
};

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

async function fetchTransactions(): Promise<Transaction[]> {
  const res = await fetch(`${API_URL}/api/finance/transactions`);
  if (!res.ok) throw new Error("Failed to fetch");
  return res.json();
}

export default function TransactionsPage() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["transactions"],
    queryFn: fetchTransactions,
  });

  if (isLoading) return <div className="p-8">Cargando...</div>;
  if (error) return <div className="p-8">Error: {(error as Error).message}</div>;

  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold mb-4">Transacciones</h1>
      <table className="w-full border-collapse">
        <thead>
          <tr className="border-b">
            <th className="text-left p-2">Código</th>
            <th className="text-left p-2">Fecha</th>
            <th className="text-left p-2">Tipo</th>
            <th className="text-left p-2">Lugar</th>
            <th className="text-right p-2">Monto</th>
          </tr>
        </thead>
        <tbody>
          {data?.map((tx) => (
            <tr key={tx.id} className="border-b">
              <td className="p-2 font-mono text-sm">{tx.transaction_code}</td>
              <td className="p-2">{tx.transaction_date}</td>
              <td className="p-2">{tx.transaction_type}</td>
              <td className="p-2">{tx.place ?? "—"}</td>
              <td className="p-2 text-right">
                {tx.amount?.toLocaleString("es-MX", {
                  style: "currency",
                  currency: "MXN",
                }) ?? "—"}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
```

### Tarea 5.4 — Validar end-to-end

1. Asegurarse de que Postgres está corriendo (`docker compose ps`).
2. Correr el ETL si la DB está vacía.
3. Levantar la API en una terminal: `cd apps/api && uv run uvicorn ...`.
4. Levantar Next.js en otra terminal: `cd apps/web && pnpm dev`.
5. Abrir `http://localhost:3000/finance/transactions`.

**Si ves la tabla con tus transacciones reales: la semana está cerrada con éxito.**

### Commit del día

```bash
git commit -am "feat(web): minimal transactions list page"
git push
```

## Día 6 (sábado) — Cleanup, README, retro

### Tarea 6.1 — README en la raíz

Documentar:
- Qué es el proyecto (resumen de 2 líneas).
- Cómo levantarlo (los pasos completos del DoD de la semana).
- Estructura del repo.
- Link al `roadmap.md`.

### Tarea 6.2 — README por app

`apps/api/README.md`, `apps/web/README.md`, `apps/pipelines/README.md` con
cómo correr cada uno individualmente.

### Tarea 6.3 — Tag

```bash
git tag v0.1.0-week1 -m "End of week 1: walking skeleton"
git push --tags
```

### Tarea 6.4 — Actualizar `progress.md`

Agregar entrada con:
- Qué se logró.
- Decisiones tomadas que merecen un ADR.
- Bugs encontrados.
- Lo que sorprendió.
- Plan para Semana 2.

## Si algo se complica

**Postgres no levanta:** `docker compose down -v && docker compose up -d`.
Verificar puerto 5432 no esté ocupado.

**Notion API devuelve vacío:** verificar que la integración tenga acceso
a la página `Life Hub 2.0` (compartirla desde la UI de Notion).

**SQLAlchemy se queja del schema:** correr la migración inicial primero
desde Adminer.

**CORS error en el browser:** verificar que `CORSMiddleware` está configurado
y `NEXT_PUBLIC_API_URL` apunta al puerto correcto.

**Tipos en TypeScript:** si tienes prisa, `any` es aceptable en Semana 1.
Refactor en Semana 2.

## Trampas a evitar

- ❌ Agregar más columnas o tablas "para que esté completo".
  *Solo lo del DoD. Lo demás es Semana 2.*
- ❌ Pulir estilos del frontend.
  *Tabla HTML básica con Tailwind mínimo. Punto.*
- ❌ Configurar CI/CD.
  *Semana 4.*
- ❌ Escribir tests.
  *Semana 4.*
- ❌ Agregar autenticación.
  *Fase 3.*
