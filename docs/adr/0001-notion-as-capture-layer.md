# ADR 0001 — Notion como capa de captura, lógica derivada en Postgres

**Fecha:** 2026-04-30
**Estado:** Aceptada
**Decisores:** Owner del proyecto

## Contexto

Al modelar finanzas personales en Notion, surgió la pregunta de dónde
debería vivir la lógica de cálculo de fechas de afectación de transacciones
de tarjeta de crédito (que dependen de fechas de corte y pago).

Tres alternativas se consideraron:

1. **Capturar fechas de corte/pago en `FIN_DIMACCOUNTS` en Notion**, con
   columnas `CutoffDay`, `DueDay`, `DueMonthOffset`, y calcular la fecha
   de afectación con una fórmula de Notion en `FIN_FACTTRANSACTIONS`.

2. **Crear una tabla `FIN_DIMPAYMENTPERIOD` en Notion**, donde el usuario
   captura mes a mes las fechas reales de corte/pago de cada tarjeta y las
   transacciones se asocian a un periodo vía relación.

3. **Capturar mínimo en Notion (lo que un humano necesita capturar) y
   calcular las fechas de afectación en SQL en la DB destino**, una vez
   que los datos llegan vía ETL.

## Decisión

Se adopta la opción **3**. Notion se mantiene como capa de captura humana:
solo guarda lo que un humano debe capturar (transacciones, cuentas con
metadatos básicos). Toda lógica derivada (fechas de afectación, agregaciones,
KPIs) se calcula en SQL/ETL.

## Razones

- **Una sola fuente de verdad** para la lógica de negocio. Si vive en dos
  lados (Notion + SQL), tarde o temprano divergen.
- **SQL es mucho más expresivo** que las fórmulas de Notion para lógica
  con dependencias entre tablas, condicionales múltiples, manejo de fechas.
- **Las fórmulas de Notion son frágiles** y difíciles de versionar/auditar.
- **El ETL ya va a existir** por otras razones (alimentar el dashboard de
  Power BI / Next.js), así que es natural meter la lógica derivada ahí.
- **Notion API tiene rate limits** y latencia. Hacer cálculos complejos
  ahí (que requieren leer relaciones múltiples) es lento.

## Consecuencias

### Positivas

- Lógica centralizada y versionada en migraciones SQL.
- Notion se mantiene simple y rápido de capturar.
- La lógica se puede testear (con SQL test fixtures).
- Si las reglas cambian (ej. el banco cambia las fechas), se actualiza
  un solo lugar y se recalcula todo el histórico.

### Negativas

- El usuario no ve la fecha de afectación dentro de Notion. Si quiere
  consultarla, tiene que ir al frontend de LifeHub (o a Power BI).
  Mitigación: el frontend va a tener una vista de "próximos pagos"
  precisamente para esto.
- Hay un retraso entre capturar en Notion y ver el cálculo (depende de
  cuándo corra el ETL). Mitigación: en Fase 4 se puede agregar un trigger
  manual desde el frontend para correr el ETL on-demand.

### Neutras

- Notion `FIN_DIMACCOUNTS` no necesita columnas nuevas para esto.

## Notas de implementación

La lógica vivirá en una vista o columna calculada en
`finance.fact_transactions`, posiblemente como vista materializada si la
performance lo amerita. Detalle pendiente para Semana 3 de Fase 1.
