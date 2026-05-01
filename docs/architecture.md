# LifeHub — Arquitectura

> Decisiones arquitectónicas tomadas y su razón. Decisiones nuevas grandes
> deben ir como ADR en `docs/adr/`. Este documento es la vista resumida.

## Diagrama mental

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌─────────────┐
│   Notion    │───▶│  Pipeline    │───▶│  PostgreSQL  │───▶│  FastAPI    │
│  (captura)  │    │   (Python)   │    │   (Docker)   │    │  (Python)   │
└─────────────┘    └──────────────┘    └──────────────┘    └──────┬──────┘
                                                                   │
                                                                   ▼
                                                            ┌─────────────┐
                                                            │   Next.js   │
                                                            │  (cliente)  │
                                                            └─────────────┘

Fase 2 añade:
                  ┌──────────────┐
   Telegram ────▶ │  LLM extract │ ─┐
                  └──────────────┘  │
                                    ▼
                            (escribe a Notion)
```

## Decisiones clave

### 1. Notion como capa de captura, NO fuente única analítica

**Razón:** Notion es excelente para input humano (UI bonita, móvil, fórmulas
visuales) pero limitado para análisis (sin SQL real, sin joins complejos,
rate limits en API).

**Implicaciones:**

- Toda lógica derivada (fechas de pago de tarjetas, agregaciones, KPIs)
  se calcula en SQL/ETL, no en Notion.
- Notion no se enriquece con datos del backend; el flujo es one-way:
  Notion → DB.
- En Fase 2, el bot también escribe a Notion (no directo a la DB), para
  mantener Notion como single point of input.

### 2. Monolito modular, no microservicios

**Razón:** Single user, scope acotado, no hay justificación para overhead
de microservicios.

**Implicaciones:**

- Un solo proyecto FastAPI con routers separados por módulo (`/api/finance/*`).
- Una sola DB Postgres con schemas separados (`finance`, `nutrition`, `shared`).
- Un solo proyecto Next.js con sub-rutas por módulo (`/finance/*`).

### 3. Schemas separados en Postgres por módulo

**Razón:** Aislamiento lógico sin la complejidad de múltiples DBs. Postgres
soporta schemas nativamente. Migrar a DBs separadas después es trivial si
las queries no cruzan schemas innecesariamente.

**Implicaciones:**

- Foreign keys cruzan schemas solo cuando son hacia `shared` (usuarios, tags, dim_date).
- Cada módulo puede evolucionar su schema independientemente.

### 4. `user_id` en toda tabla de hechos desde el día uno

**Razón:** Single user hoy, posible multi-user mañana. El costo de agregarlo
al inicio es ~3 minutos; el costo de retrofitear después es altísimo.

**Implicaciones:**

- Tabla `shared.users` desde la primera migración.
- Hardcode `user_id = '00000000-0000-0000-0000-000000000001'` (UUID fijo del
  owner) en todo lado en Fase 1, sin auth real.
- Auth se introduce en Fase 3.

### 5. Idempotencia en ETL vía `notion_id` como llave natural

**Razón:** Correr el pipeline N veces no debe duplicar datos. Notion expone
un `id` único y estable por página.

**Implicaciones:**

- Cada tabla de hechos tiene una columna `notion_id` con índice único.
- Inserción usa `INSERT ... ON CONFLICT (notion_id) DO UPDATE`.
- El `id` interno de Postgres es un UUID separado del `notion_id`.

### 6. Vertical slice antes que capa horizontal completa

**Razón:** Construir todo el ETL antes de tocar el frontend genera proyectos
abandonados. Un slice end-to-end aunque sea trivial valida la arquitectura
completa pronto.

**Implicaciones:**

- Semana 1 toca DB, ETL, API y frontend, aunque cada uno sea mínimo.
- Las features se engrosan en sprints siguientes, no se completan capa por capa.

### 7. Notion `Type` se mantiene en Title Case; mayúsculas se aplican en ETL si se requieren

**Razón:** Notion es una interfaz visual que el usuario lee a diario. La
convención de "MAYÚSCULAS para enums" aplica a sistemas SQL, no a UIs. La
normalización es responsabilidad del ETL.

**Implicaciones:**

- `Income`, `Payment - Full`, etc. en Notion.
- Si la DB destino requiere mayúsculas, el pipeline aplica `str.upper()` o
  un mapping explícito a una tabla de catálogos.

### 8. Stack elegido por demanda de mercado

**Razón:** El proyecto es también portafolio. El stack debe coincidir con
lo que se pide en ofertas de trabajo de data engineering / full-stack.

**Implicaciones:** ver tabla en `CLAUDE.md`.

### 9. Identidades digitales separadas: personal vs producto

**Razón:** La reputación del creador y la del producto son cosas distintas.
Un producto puede morir; la identidad personal acumula reputación con el
tiempo. Detalle completo en ADR 0002.

**Implicaciones:**

- `curbsidenigma.com` = identidad personal (blog, portafolio).
- `lifehub.curbsidenigma.com` = LifeHub temporalmente, hasta Fase 4+.
- Cada app se despliega independiente bajo su propio subdominio.
- Migración futura a dominio propio = cambio de DNS + redirect 301.

## Decisiones diferidas (revisitar cuando aplique)

| Decisión | Cuándo revisarla |
|---|---|
| ¿Notion sigue siendo la captura, o pasa a ser solo input móvil mientras la captura primaria es la app web? | Después de Fase 3 |
| ¿ORM SQLAlchemy o queries SQL crudas con `psycopg`? | Si SQLAlchemy se siente pesado en Fase 1 |
| ¿Auth con NextAuth, Clerk, o roll-your-own? | Inicio de Fase 3 |
| ¿Mantener monorepo o separar en repos? | Si los dos apps empiezan a tener ciclos de release distintos |
| ¿Migrar a dbt para transformaciones? | Cuando haya >10 modelos derivados o >2 módulos |

## Decisiones explícitamente rechazadas

| Propuesta | Por qué se rechaza |
|---|---|
| Agregar `CutoffDay`/`DueDay` a `FIN_DIMACCOUNTS` en Notion | Lógica derivada vive en DB |
| Tabla `FIN_DIMPAYMENTPERIOD` en Notion | Misma razón |
| GraphQL en Fase 1 | Overhead innecesario, REST suficiente |
| Microservicios | Single user, sin justificación |
| Kubernetes en Fase 1 | Docker Compose suficiente para local |
| Tests exhaustivos en Fase 1 | El código aún cambia mucho; tests vendrán cuando estabilice |
| Framework genérico de "módulos pluggables" | Sobreingeniería para 1-3 módulos |
