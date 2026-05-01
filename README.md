# LifeHub

> ERP modular para la vida. Captura en Notion, procesa en Postgres,
> consume en Next.js. Fase 1: módulo de finanzas personales.

## Estado

🔵 **En construcción** — Fase 1, Semana 1: walking skeleton.

Ver `docs/roadmap.md` para el plan completo y `docs/progress.md` para el
estado actual.

## Stack

- **Captura:** Notion (vía API)
- **Pipeline:** Python 3.12 + `uv` + SQLAlchemy 2.0
- **Base de datos:** PostgreSQL 16 (Docker en local)
- **API:** FastAPI + Pydantic v2
- **Frontend:** Next.js 15 (App Router) + TypeScript + Tailwind + shadcn/ui
- **Data fetching:** TanStack Query

Ver `docs/architecture.md` para el detalle y `CLAUDE.md` para convenciones.

## Cómo levantar el proyecto

> **Pre-requisitos:** Docker, Python 3.12+, Node 20+, `uv`, `pnpm`,
> token de Notion.

```bash
# 1. Clonar y configurar
git clone <url-del-repo>
cd lifehub
cp .env.example .env  # editar con tu NOTION_TOKEN

# 2. Levantar infraestructura
docker compose up -d
docker exec -i lifehub_postgres psql -U lifehub -d lifehub_dev \
  < packages/db/migrations/001_initial.sql

# 3. Pipeline (Notion → Postgres)
cd apps/pipelines
uv sync
uv run python -m lifehub_pipelines.finance.main

# 4. API (en otra terminal)
cd apps/api
uv sync
uv run uvicorn lifehub_api.main:app --reload

# 5. Frontend (en otra terminal)
cd apps/web
pnpm install
pnpm dev

# Abrir: http://localhost:3000/finance/transactions
```

## Estructura del repo

```
lifehub/
├── CLAUDE.md                   # Contexto auto-cargado por Claude Code
├── README.md                   # Este archivo
├── docker-compose.yml
├── .env.example
│
├── docs/                       # Toda la documentación viva
│   ├── roadmap.md
│   ├── architecture.md
│   ├── data-model.md
│   ├── progress.md
│   ├── phase-1-week-1.md
│   └── adr/                    # Architecture Decision Records
│
├── apps/
│   ├── api/                    # FastAPI backend
│   ├── web/                    # Next.js frontend
│   └── pipelines/              # ETL scripts (Python)
│
└── packages/
    └── db/
        └── migrations/         # SQL migrations
```

## Documentación

- **`CLAUDE.md`** — convenciones del proyecto (auto-cargado por Claude Code).
- **`docs/roadmap.md`** — fases del proyecto.
- **`docs/architecture.md`** — decisiones arquitectónicas.
- **`docs/data-model.md`** — modelo de datos.
- **`docs/progress.md`** — bitácora de avances.
- **`docs/adr/`** — decisiones individuales (ADRs).

## Licencia

Proyecto personal. Sin licencia pública por ahora.
