<!--
  Plantilla automática de PR. Completa cada sección antes de pedir review.
  Si una sección no aplica, escribe "N/A" — no la borres. Mantener la estructura
  hace que el historial de PRs sea uniforme y leíble en 6 meses.
-->

## Qué cambia

<!-- 1-3 viñetas en presente. WHY más que WHAT cuando sea posible. -->

-
-

## Por qué

<!-- Contexto: qué problema resuelve, qué decisión apoya, link a issue/ADR. -->

Closes #

## Cómo se probó

- [ ] Local: <!-- comando exacto que corriste y resultado -->
- [ ] Migración aplicada (si aplica)
- [ ] (Cuando exista CI) Status checks verdes

## Riesgos / consideraciones

<!--
  Migrations destructivas, breaking changes, dependencias nuevas, secretos
  agregados, cambios de schema, costo de inferencia. Si no aplica: "Ninguno".
-->

## Checklist

- [ ] El cambio respeta las convenciones de `CLAUDE.md`
- [ ] Si introduce decisión arquitectónica grande, hay un ADR en `docs/adr/`
- [ ] `docs/progress.md` actualizado si la sesión fue productiva
- [ ] Conventional Commits respetado (subject + body si la subject es densa)
