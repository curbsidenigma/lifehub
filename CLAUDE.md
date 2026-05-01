# LifeHub — Contexto del proyecto

> Este archivo se carga automáticamente como contexto en cada sesión de Claude Code.
> Mantenerlo actualizado es responsabilidad del owner del proyecto.

## Qué es LifeHub

LifeHub es un proyecto personal de "ERP para la vida": una plataforma modular para
trackear distintos dominios personales (finanzas, dieta, lectura, etc.).

El owner es **consultor de transformación digital**, así que el proyecto sirve a
dos objetivos simultáneos:

1. **Tracking real** de finanzas/hábitos personales.
2. **Aprendizaje y portafolio** end-to-end de data engineering, full-stack, y AI.

## Estado actual

- **Fase activa:** Fase 1 — ETL + Frontend mínimo del módulo de finanzas.
- **Módulo activo:** `finance` (único módulo en construcción).
- **Módulos futuros:** `nutrition`, `reading`, otros (no construir hasta que `finance` esté maduro).

Ver `docs/roadmap.md` para el plan completo y `docs/progress.md` para la bitácora.

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Source de captura | Notion (vía API) |
| Lenguaje backend | Python 3.12+ |
| Package manager Python | `uv` |
| ORM | SQLAlchemy 2.0 |
| API framework | FastAPI |
| Validación | Pydantic v2 |
| Base de datos | PostgreSQL 16 (Docker en local) |
| Frontend | Next.js 15 (App Router) + TypeScript |
| Styling | Tailwind CSS + shadcn/ui |
| Data fetching | TanStack Query |
| Validación frontend | Zod |
| Orquestación local | Docker Compose |

**Decisiones explícitas de NO usar (todavía):**

- TypeScript en backend (Python es backend; TS es frontend).
- GraphQL (REST es suficiente).
- Microservicios (monolito modular).
- Kubernetes (Docker Compose basta).
- ORMs JS como Prisma o Drizzle (SQLAlchemy maneja la DB).
- dbt, Airflow, Dagster (cron + scripts Python son suficientes en Fase 1).

## Convenciones de naming

### Base de datos (Postgres)

- **Schemas separados por módulo:** `finance`, `nutrition` (futuro), `reading` (futuro), etc.
- **Tablas:** `snake_case`, prefijo según tipo:
  - `fact_*` para tablas de hechos (transactions, transaction_items)
  - `dim_*` para dimensiones (accounts, categories)
- **Columnas:** `snake_case` (`account_id`, `created_at`, `transaction_date`)
- **Primary keys:** `id` (UUID o serial según el caso, decisión por tabla)
- **Foreign keys:** `<tabla_singular>_id` (`account_id`, `transaction_id`)
- **Timestamps estándar:** `created_at`, `updated_at` en toda tabla mutable

### Notion

- **Tablas (databases):** `MAYÚSCULAS_CON_PREFIJO`, ej. `FIN_FACTTRANSACTIONS`, `FIN_DIMACCOUNTS`
- **Columnas (properties):** `PascalCase`, ej. `TransactionId`, `AccountType`
- **Valores de selects:** `Title Case` (legibles); la normalización a mayúsculas ocurre en ETL si se requiere

### Código

- **Python:** PEP 8, `snake_case` para funciones/variables, `PascalCase` para clases.
- **TypeScript:** `camelCase` para variables/funciones, `PascalCase` para componentes/tipos.
- **Archivos Python:** `snake_case.py`
- **Componentes React:** `PascalCase.tsx`

### Git

- **Branches:** `feature/<corto>`, `fix/<corto>`, `chore/<corto>`
- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`)

## Estructura del repo

```
lifehub/
├── CLAUDE.md                   # Este archivo
├── README.md                   # Setup y comandos
├── docker-compose.yml          # Postgres + Adminer
├── .env.example
│
├── docs/
│   ├── roadmap.md              # Plan por fases
│   ├── architecture.md         # Decisiones arquitectónicas
│   ├── data-model.md           # Modelo de datos
│   ├── progress.md             # Bitácora viva
│   ├── phase-1-week-1.md       # Plan detallado de la semana actual
│   └── adr/                    # Architecture Decision Records
│
├── apps/
│   ├── api/                    # FastAPI backend
│   │   ├── pyproject.toml
│   │   └── src/
│   │       └── lifehub_api/
│   │           ├── core/       # Auth, config, db
│   │           └── modules/
│   │               └── finance/
│   ├── web/                    # Next.js frontend
│   │   ├── package.json
│   │   └── src/
│   │       └── app/
│   │           ├── (core)/
│   │           └── finance/
│   └── pipelines/              # ETL scripts
│       ├── pyproject.toml
│       └── src/
│           └── lifehub_pipelines/
│               └── finance/
│
└── packages/                   # Código compartido (futuro si crece)
    └── db/
        └── migrations/
```

## Principios arquitectónicos clave

1. **Modular desde el día 1, sin sobreingeniería.** Schemas separados, sub-rutas
   separadas, routers separados. Pero NO un "framework de plugins" abstracto.

2. **`user_id` en toda tabla de hechos desde el inicio.** Aunque sea single-user
   hoy, deja la puerta abierta a multi-usuario.

3. **Notion como capa de captura humana, no fuente única de verdad analítica.**
   Lo derivado (fechas de afectación, agregaciones) se calcula en SQL/ETL,
   no en Notion.

4. **Vertical slice delgada antes que capa horizontal completa.** Mejor un end-to-end
   feo que funcione, que un backend perfecto sin frontend.

5. **Idempotencia en ETL.** Correr el pipeline dos veces no debe duplicar datos.
   Usar `INSERT ... ON CONFLICT DO UPDATE` con un identificador estable de Notion.

6. **Cheap optionality.** Decisiones que cuestan poco hoy pero abren puertas
   futuras (schemas separados, sub-rutas separadas) sí. Decisiones que
   cuestan mucho hoy "por si acaso" no.

## Comandos comunes

> Esta sección se actualiza conforme se establecen los comandos del proyecto.
> Por ahora está vacía porque estamos en setup.

```bash
# Levantar infraestructura local
docker compose up -d

# Pipeline de finanzas (Notion → Postgres)
cd apps/pipelines && uv run python -m lifehub_pipelines.finance.main

# API
cd apps/api && uv run uvicorn lifehub_api.main:app --reload

# Frontend
cd apps/web && pnpm dev
```

## Cómo trabajar con Claude (Code o web)

1. **Antes de pedir cambios grandes:** revisar `docs/roadmap.md` y `docs/progress.md`.
2. **Después de tomar una decisión arquitectónica:** crear un ADR en `docs/adr/`.
3. **Al final de una sesión productiva:** actualizar `docs/progress.md` con lo hecho.
4. **Si Claude propone algo que rompe convenciones de este archivo:** corregirlo.
   Las convenciones aquí son la fuente de verdad.

## Anti-patrones a evitar

- ❌ Diseñar 7 tablas de un módulo antes de empezar a construirlo.
- ❌ Tratar de hacer dos módulos en paralelo.
- ❌ Construir abstracciones genéricas para "cuando crezca".
- ❌ Subir el scope de una feature a mitad de implementación.
- ❌ Posponer commits hasta tener "algo presentable".
- ❌ Reproducir lógica en Notion que ya existe (o existirá) en SQL.
