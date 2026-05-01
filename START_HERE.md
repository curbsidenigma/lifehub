# 🚀 START HERE — LifeHub Bootstrap Package

> **Léeme primero.** Este archivo te explica qué tienes en este paquete,
> cómo usarlo, y los pasos exactos para arrancar el proyecto.

## 📦 Qué hay en este paquete

```
lifehub-bootstrap/
├── START_HERE.md                    ← Este archivo
├── CLAUDE.md                        ← Contexto auto-cargado por Claude Code
├── README.md                        ← README del repo (será la cara pública)
├── .gitignore                       ← Reglas de git
├── .env.example                     ← Plantilla de variables de entorno
├── docker-compose.yml               ← Postgres + Adminer
├── bootstrap.sh                     ← Script para crear estructura inicial
│
├── docs/
│   ├── roadmap.md                   ← Plan completo por fases
│   ├── architecture.md              ← Decisiones arquitectónicas
│   ├── data-model.md                ← Modelo de datos (Notion + Postgres)
│   ├── progress.md                  ← Bitácora viva (actualizar siempre)
│   ├── phase-1-week-1.md            ← Plan paso por paso de la Semana 1
│   └── adr/
│       ├── 0001-notion-as-capture-layer.md
│       └── 0002-domain-and-naming-strategy.md
│
└── packages/
    └── db/
        └── migrations/
            └── 001_initial.sql      ← Schema inicial de Postgres
```

## 🧭 Cómo está estructurada la documentación

Hay **dos capas** de docs, separadas a propósito:

### Capa permanente (cambia poco)

| Archivo | Para qué sirve |
|---|---|
| `CLAUDE.md` | **Auto-cargado por Claude Code en cada sesión.** Contexto base: stack, convenciones, anti-patrones. |
| `docs/architecture.md` | Decisiones arquitectónicas resumidas. |
| `docs/data-model.md` | Esquemas de DB, mapping Notion → Postgres. |
| `docs/adr/` | Architecture Decision Records: una decisión grande por archivo. |

### Capa viva (se actualiza constantemente)

| Archivo | Para qué sirve |
|---|---|
| `docs/roadmap.md` | Plan por fases. Se actualiza al cerrar fase o ajustar scope. |
| `docs/progress.md` | Bitácora del día a día. Se actualiza al cerrar cada sesión productiva. |
| `docs/phase-X-week-Y.md` | Plan detallado del sprint actual. Uno por semana de trabajo. |

## ✅ Checklist completo para arrancar

### Fase 0 — Pre-requisitos del entorno

Antes de tocar el código, asegúrate de tener:

- [ ] **Docker Desktop** instalado y corriendo.
  Verificar: `docker --version` y `docker compose version`
- [ ] **Python 3.12+**. Verificar: `python3 --version`
- [ ] **Node 20+**. Verificar: `node --version`
- [ ] **`uv`** (gestor de paquetes Python).
  Instalar: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- [ ] **`pnpm`**. Instalar: `npm install -g pnpm`
- [ ] **`gh` CLI** (opcional pero recomendado). Instalar: ver https://cli.github.com
- [ ] **Cuenta de GitHub** lista.
- [ ] **Integración interna de Notion** creada con acceso a "Life Hub 2.0".
  - Ir a https://www.notion.so/profile/integrations
  - Crear nueva integración interna
  - Guardar el token (empieza con `secret_...` o `ntn_...`)
  - **Importante:** abrir la página "Life Hub 2.0" en Notion → menú de los 3 puntos → Connections → agregar tu integración.
- [ ] **Comprar `curbsidenigma.com`** en Cloudflare Registrar o Porkbun (~$10-15 USD/año).
  - Solo comprar y dejar estacionado. No configurar DNS.
  - Ver `docs/adr/0002-domain-and-naming-strategy.md` para el porqué.

### Fase 1 — Setup del repo (15 minutos)

```bash
# 1. Crear carpeta y meterte
mkdir lifehub && cd lifehub

# 2. Copiar TODOS los archivos de este paquete a la raíz
#    (CLAUDE.md, README.md, .gitignore, .env.example, docker-compose.yml,
#     bootstrap.sh, y la carpeta docs/ y packages/)

# 3. Hacer ejecutable el bootstrap
chmod +x bootstrap.sh

# 4. Correr el bootstrap (crea las carpetas vacías de apps/)
./bootstrap.sh

# 5. Configurar tu .env local
cp .env.example .env
# Editar .env con:
#   - NOTION_TOKEN: tu token real de la integración
#   - NOTION_DB_TRANSACTIONS: 32adeebec9b180029cbbf7cfc614bbec (ya viene)

# 6. Inicializar git
git init
git add .
git commit -m "chore: initial repo setup with docs and bootstrap"

# 7. Crear repo en GitHub (opción A con gh CLI)
gh repo create lifehub --private --source=. --remote=origin --push

# (opción B sin gh CLI: crear repo manualmente en github.com/new
#  y luego: git remote add origin <url> && git push -u origin main)
```

### Fase 2 — Levantar infraestructura local (10 minutos)

```bash
# 1. Levantar Postgres + Adminer
docker compose up -d

# 2. Verificar que están corriendo
docker compose ps
# Deberías ver lifehub_postgres y lifehub_adminer en estado "Up"

# 3. Aplicar la migración inicial
docker exec -i lifehub_postgres psql -U lifehub -d lifehub_dev \
  < packages/db/migrations/001_initial.sql

# 4. Verificar en Adminer
# Abrir: http://localhost:8080
# - Sistema: PostgreSQL
# - Servidor: postgres
# - Usuario: lifehub
# - Contraseña: lifehub_dev_password
# - Base de datos: lifehub_dev
# Deberías ver los schemas: shared, finance
```

### Fase 3 — Empezar la Semana 1

A partir de aquí, sigue **`docs/phase-1-week-1.md`** día por día.

El plan está en 6 días (lunes a sábado), cada uno de ~2-4 horas:

- **Día 1:** ✅ ya hecho con los pasos de arriba.
- **Día 2:** Pipeline mínimo (Python lee Notion → JSON).
- **Día 3:** Pipeline → Postgres (carga idempotente).
- **Día 4:** API mínima (FastAPI con un endpoint).
- **Día 5:** Frontend mínimo (Next.js mostrando una tabla).
- **Día 6 (sábado):** Cleanup, README final, retro.

## 🤖 Cómo trabajar con Claude / Claude Code

### En Claude Code (recomendado para construcción)

Claude Code carga `CLAUDE.md` automáticamente. Para cada sesión:

```
1. Abrir terminal en la raíz del repo
2. Correr: claude  (o como tengas configurado)
3. Primer mensaje:
   "Lee docs/progress.md y docs/phase-1-week-1.md.
    Vamos a continuar con [Día N / Tarea X]."
```

Claude tendrá contexto completo: convenciones, dónde vas, qué sigue.

### En Claude.ai (web — para conversación / planeación)

Si usas Claude.ai sin Claude Code:

```
1. Sube los archivos relevantes al chat:
   - CLAUDE.md (siempre)
   - docs/progress.md (estado actual)
   - docs/phase-1-week-1.md (si estás en construcción)
   - docs/architecture.md (si vas a discutir arquitectura)
2. Primer mensaje: "Aquí está el contexto del proyecto. Quiero hablar sobre [X]."
```

### Reglas para mantener el contexto sano

1. **Al final de CADA sesión productiva** (no importa qué tan corta):
   pídele a Claude actualizar `docs/progress.md`.

2. **Cuando tomes una decisión grande** (cambiar stack, agregar dependencia
   importante, refactor arquitectónico): pídele crear un nuevo ADR en
   `docs/adr/NNNN-titulo.md`.

3. **Cuando termines una semana**: actualiza `docs/roadmap.md` marcando
   esa semana como completada y crea el archivo `phase-X-week-(Y+1).md`
   para la siguiente.

4. **Si Claude propone algo que rompe convenciones de `CLAUDE.md`**:
   recházalo. `CLAUDE.md` es la fuente de verdad. Si la convención está
   mal, cámbiala explícitamente en `CLAUDE.md` primero.

## 🚫 Lo que NO debes hacer

- ❌ **No saltarte fases del roadmap.** Es tentador porque "el bot con AI
  suena más cool", pero sin pipeline sólido el bot escribe basura.
- ❌ **No agregar features dentro de un sprint que no estaban en el plan.**
  Anótalas en `docs/progress.md#parking-lot`.
- ❌ **No pulir estilos de UI en Semana 1.** Tabla HTML básica. Punto.
- ❌ **No configurar CI/CD, tests exhaustivos, ni auth en Fase 1.** Eso es Fase 4.
- ❌ **No comprar más dominios "por si acaso".** Uno (`curbsidenigma.com`) basta.
- ❌ **No empezar el módulo de `nutrition` o `reading` antes de cerrar
  finance al menos hasta Fase 2.**

## 🆘 Si algo se complica

**Postgres no levanta:**
```bash
docker compose down -v
docker compose up -d
```
Verificar que el puerto 5432 no esté ocupado: `lsof -i :5432`

**Notion API devuelve `unauthorized`:**
Verificar que la integración tiene acceso a "Life Hub 2.0" en Notion
(menú de la página → Connections → agregar tu integración).

**`uv` o `pnpm` no encontrados:**
Reinstalarlos. En macOS, asegúrate que `~/.local/bin` está en tu `$PATH`.

**Cualquier otra cosa:**
Documenta el error en `docs/progress.md` y consulta con Claude.

## 📚 Próxima lectura recomendada

En este orden:

1. `CLAUDE.md` — para entender convenciones del proyecto.
2. `docs/roadmap.md` — para tener el mapa completo.
3. `docs/architecture.md` — para entender el porqué de las decisiones.
4. `docs/phase-1-week-1.md` — para empezar a construir.

Los ADR (`docs/adr/0001`, `docs/adr/0002`) los puedes leer cuando te
encuentres con la pregunta correspondiente; no necesitas leerlos de
entrada.

---

**Última actualización:** 2026-04-30
**Estado del proyecto:** Fase 1 — Semana 1 lista para arrancar.
