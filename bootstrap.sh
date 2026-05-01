#!/usr/bin/env bash
# ============================================================================
# LifeHub — Bootstrap script
# ============================================================================
# Crea la estructura de carpetas inicial para apps/ y packages/.
# Solo crea carpetas y archivos placeholder; NO instala dependencias.
# Las dependencias se instalan en su día correspondiente del Day-by-day plan.
# ============================================================================

set -euo pipefail

echo "🚀 Bootstrapping LifeHub..."

# --- Apps ---
mkdir -p apps/api/src/lifehub_api/core
mkdir -p apps/api/src/lifehub_api/modules/finance
mkdir -p apps/web
mkdir -p apps/pipelines/src/lifehub_pipelines/finance

# --- Packages ---
mkdir -p packages/db/migrations

# --- Placeholders para que git trackee las carpetas ---
touch apps/api/.gitkeep
touch apps/web/.gitkeep
touch apps/pipelines/.gitkeep

# --- READMEs por app (placeholders) ---
cat > apps/api/README.md <<'EOF'
# LifeHub API

FastAPI backend. Setup detallado en `docs/phase-1-week-1.md` (Día 4).

```bash
uv sync
uv run uvicorn lifehub_api.main:app --reload
```
EOF

cat > apps/pipelines/README.md <<'EOF'
# LifeHub Pipelines

ETL scripts. Setup detallado en `docs/phase-1-week-1.md` (Día 2-3).

```bash
uv sync
uv run python -m lifehub_pipelines.finance.main
```
EOF

cat > apps/web/README.md <<'EOF'
# LifeHub Web

Next.js frontend. Setup detallado en `docs/phase-1-week-1.md` (Día 5).

```bash
pnpm install
pnpm dev
```
EOF

echo "✅ Estructura creada:"
echo ""
find apps packages -type d | sort | sed 's/^/   /'
echo ""
echo "📝 Próximo paso: leer docs/phase-1-week-1.md y empezar el Día 1."
