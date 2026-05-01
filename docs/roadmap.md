# LifeHub — Roadmap

> Plan por fases. Se actualiza cuando una fase avanza o cambia de scope.
> El detalle semanal vive en archivos `docs/phase-X-week-Y.md`.

## Visión general

LifeHub se construye en **fases secuenciales**, no en paralelo. Cada fase
debe terminarse "lo suficientemente bien" antes de empezar la siguiente,
con scope explícitamente acotado.

## Fase 0 — Configuración del proyecto en Notion

**Estado:** ✅ Completada.

- Modelo dimensional inicial creado en Notion (Life Hub 2.0 → Finances).
- Tablas: `FIN_FACTTRANSACTIONS`, `FIN_FACTTRANSACTIONSITEMS`, `FIN_DIMACCOUNTS`,
  `FIN_DIMCATEGORY`, `FIN_FACTPERDIEM`, `FIN_FACTEXTRAPERDIEM`, `FIN_FACTFIXEDSAVINGS`.
- Columna `Type` actualizada con: `Income`, `Withholding`, `Payment - Full`,
  `Payment - MSI`, `Payment - MCI`.

**Decisiones diferidas (NO hacer en Notion):**

- ❌ Agregar `CutoffDay`, `DueDay`, `DueMonthOffset` a `FIN_DIMACCOUNTS`.
   Esa lógica vive en la DB destino, calculada, no capturada.
- ❌ Crear tabla `FIN_DIMPAYMENTPERIOD`. Misma razón.

## Fase 1 — Vertical slice mínima (finanzas)

**Estado:** 🔵 En progreso.
**Duración estimada:** 4 semanas.
**Objetivo:** Notion → Postgres → FastAPI → Next.js, todo en local, end-to-end funcionando.

### Semana 1 — Walking skeleton

Setup del repo, Docker Compose con Postgres, pipeline mínimo Python que lee
una tabla de Notion y la escribe a Postgres, FastAPI con un endpoint, Next.js
con una tabla básica.

Detalle: `docs/phase-1-week-1.md`.

### Semana 2 — Engrosar el modelado

- Tabla de cuentas (dimensión).
- Tabla de items (detalle de transacción).
- Resolución de relaciones de Notion en el ETL.
- Frontend: agrupar transacciones por cuenta.

### Semana 3 — Engrosar la vista

- Agregaciones (gasto por categoría, por mes).
- Cálculo de fechas de afectación según reglas de tarjetas (en SQL).
- Frontend: gráficas básicas con Recharts.

### Semana 4 — Engrosar el pipeline

- Schedule del ETL (cron local primero, GitHub Actions después).
- Cargas incrementales (no traer todo cada vez).
- Logs estructurados.
- README completo y commits ordenados.

**Definition of Done de Fase 1:**

- [ ] `docker compose up` levanta toda la infra local.
- [ ] Un comando corre el ETL completo de finanzas.
- [ ] El frontend muestra transacciones, cuentas y un dashboard básico.
- [ ] El código está en GitHub público (o privado, pero versionado).
- [ ] El README permite a otra persona levantar el proyecto desde cero.

## Fase 2 — Captura inteligente con LLM

**Estado:** ⏳ No iniciada.
**Duración estimada:** 3-4 semanas.
**Pre-requisito:** Fase 1 cerrada.

- Telegram bot que recibe foto/texto de tickets de consumo.
- Extracción estructurada con LLM (Claude o GPT) usando JSON schema.
- Validación posterior: verificar cuenta, categoría, formato de monto.
- Escritura a Notion vía API (mantenemos Notion como capa de captura).
- El ETL existente jala el dato a Postgres como cualquier otra captura.

**Aprendizajes objetivo:** structured output, manejo de errores de IA,
webhooks, costos de inferencia, prompt engineering.

## Fase 3 — API + Frontend custom maduro

**Estado:** ⏳ No iniciada.
**Duración estimada:** 6 semanas.
**Pre-requisito:** Fase 2 cerrada.

- Autenticación (NextAuth o Clerk).
- API completa con CRUD donde aplique.
- Frontend pulido: dashboards, formularios de captura directa, vista mensual
  con cálculo de pagos esperados, vista quincenal de flujo neto.
- Workflow de revisión de capturas hechas por la IA.

## Fase 4 — Productización

**Estado:** ⏳ No iniciada.
**Pre-requisito:** Fase 3 cerrada.

- Despliegue real (Vercel + Railway/Render + Postgres managed).
- Dominio propio.
- CI/CD con GitHub Actions.
- Observabilidad (Sentry, Logtail o similar).
- Tests automatizados de las rutas críticas.

## Fase 5 — Segundo módulo

**Estado:** ⏳ No iniciada.
**Pre-requisito:** Fase 4 cerrada y al menos 1 mes de uso real del módulo de finanzas.

Selección entre `nutrition`, `reading`, u otro según interés. Reutilizar
patrones establecidos. Documentar lo que tuvo que adaptarse del módulo base.

## Reglas para mover de fase

1. **No saltar fases.** Es tentador, pero se paga caro después.
2. **Si una fase tarda más de 1.5x lo estimado:** revisar scope, no extender ciegamente.
3. **No agregar features dentro de una fase activa que no estaban en el plan.**
   Anotarlas en `docs/progress.md#parking-lot` y considerarlas en la siguiente fase.
4. **Cada fase termina con un commit etiquetado** (`v0.1.0`, `v0.2.0`, etc.) y
   un retro corto en `docs/progress.md`.
