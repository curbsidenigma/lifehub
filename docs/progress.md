# LifeHub — Bitácora de progreso

> Bitácora viva. Se actualiza al final de cada sesión productiva.
> Formato: lo más reciente arriba.

## Cómo usar este archivo

- **Sección "Avances":** qué se construyó hoy, decisiones tomadas, blockers encontrados.
- **Sección "Parking lot":** ideas/features que surgen pero NO entran a la fase actual.
- **Sección "Aprendizajes":** lecciones técnicas o conceptuales del trayecto.

---

## Parking lot

Ideas que surgen durante la construcción pero NO entran al sprint actual.
Se revisan al planear cada nueva fase.

- *(vacío por ahora)*

## Aprendizajes

Lecciones técnicas o conceptuales que valen la pena recordar.

- *(vacío por ahora)*

---

## Avances

### YYYY-MM-DD — Plantilla de entrada

**Hecho hoy:**

- Punto 1
- Punto 2

**Decisiones:**

- Decisión X porque Y. (Si es grande, va en ADR.)

**Pendientes / blockers:**

- Pendiente A.
- Blocker B.

**Próximo paso:**

- Qué sigue mañana.

---

### 2026-04-30 — Setup inicial de documentación

**Hecho hoy:**

- Conversación de planeación inicial con Claude.
- Decidida arquitectura modular (LifeHub con módulos: finance primero).
- Decidido stack: Python + FastAPI + Postgres + Next.js + TypeScript.
- Generados archivos de contexto: `CLAUDE.md`, `docs/roadmap.md`,
  `docs/architecture.md`, `docs/data-model.md`, `docs/progress.md`,
  `docs/phase-1-week-1.md`.
- En Notion: actualizada columna `Type` de `FIN_FACTTRANSACTIONS` con 5
  opciones (Income, Withholding, Payment - Full, Payment - MSI, Payment - MCI).
- Decidida estrategia de dominio: `curbsidenigma.com` como identidad
  personal, LifeHub vivirá temporalmente como `lifehub.curbsidenigma.com`.
  ADR 0002 creado.

**Decisiones:**

- Notion se queda como capa de captura, lógica derivada vive en DB (ADR 0001).
- No agregar `CutoffDay`/`DueDay` a Notion; se modela en Postgres.
- Stack final: Python + FastAPI + Postgres + Next.js (justificado por demanda de mercado).
- Empezar con vertical slice mínima en lugar de capa horizontal completa.
- Repo se llama `lifehub` desde el día 1 (no `finhub`).
- Dos identidades digitales separadas: `curbsidenigma.com` (personal,
  blog, portafolio) y `lifehub.curbsidenigma.com` (subdominio para la
  app). ADR 0002.
- Subdominio en lugar de subdirectorio para evitar complejidad de
  reverse proxy.

**Pendientes / blockers:**

- Comprar `curbsidenigma.com` en Cloudflare o Porkbun (~$10-15 USD/año).
  Dejar estacionado, sin configurar DNS hasta Fase 4.
- Crear el repo de GitHub.
- Migrar transacciones existentes con `Type = Payment` (huérfanas) a las nuevas opciones.
- Validar que Docker está instalado en la máquina local.

**Próximo paso:**

- Ejecutar Día 1 de `docs/phase-1-week-1.md`: setup del repo y Docker Compose.
