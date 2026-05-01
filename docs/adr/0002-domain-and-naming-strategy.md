# ADR 0002 — Estrategia de naming y dominio: subdominio bajo identidad personal

**Fecha:** 2026-04-30
**Estado:** Aceptada
**Decisores:** Owner del proyecto

## Contexto

`lifehub.com` está tomado, lo cual abrió la pregunta sobre qué nombre y
dominio usar para el proyecto. Se consideraron varias estrategias:

1. Comprar una variante (`lifehub.app`, `lifehub.dev`, `mylifehub.com`).
2. Hacer brainstorm de un nombre completamente nuevo.
3. Diferir la decisión y operar como `lifehub` interno sin dominio.
4. Hospedar bajo un dominio personal del owner (`curbsidenigma.com`),
   ya sea como subdirectorio (`curbsidenigma.com/lifehub`) o subdominio
   (`lifehub.curbsidenigma.com`).

El owner ya usa `curbsidenigma` como su username habitual, y el dominio
`curbsidenigma.com` está disponible.

## Decisión

Se adopta una estrategia de **dos identidades digitales separadas**:

1. **Identidad personal del creador:** `curbsidenigma.com`. Acompaña al
   owner toda su carrera. Hospeda blog, portafolio, y eventualmente sirve
   de paraguas para sus productos.

2. **Identidad de producto:** LifeHub vive temporalmente como subdominio
   bajo el dominio personal: `lifehub.curbsidenigma.com`. Cuando el
   producto madure (Fase 4+), se evaluará migrar a un dominio propio.

**Nombre interno del proyecto y repo:** `lifehub` (no cambia). El nombre
público se decide en Fase 4 si hay razones para cambiarlo.

## Razones

### Por qué dos identidades separadas

- **Reputación personal vs reputación de producto** son cosas distintas.
  Un producto puede morir; la identidad personal del creador acumula
  reputación con el tiempo independientemente.
- Es la práctica estándar de indie hackers y developers profesionales
  (ej. levels.io con sus múltiples productos como sub-marcas).
- Permite que `curbsidenigma.com` sea portafolio activo a través del blog,
  documentando aprendizajes del proyecto LifeHub.

### Por qué subdominio en lugar de subdirectorio

- **Simplicidad de hosting:** cada app (blog estático + LifeHub Next.js +
  API FastAPI) tiene su propio deployment independiente. No requiere
  reverse proxy ni rewrites complejos.
- **Despliegues independientes:** romper LifeHub no afecta el blog y
  viceversa.
- **Migración futura trivial:** el día que LifeHub merezca dominio propio,
  un cambio de DNS + redirect 301 resuelve todo en minutos.
- **SEO no es prioritario** para LifeHub (es una app personal, no busca
  tráfico orgánico). Si lo fuera, subdirectorio sería preferible.

### Por qué no comprar un dominio nuevo solo para LifeHub

- **Bloquear el arranque del proyecto en una decisión de naming es
  procrastinación de diseño.** El proyecto puede empezar y avanzar sin
  ese commitment.
- **El nombre final tendrá más información en 6 meses** que ahora.
- **Para aprendizaje y portafolio, el nombre importa muy poco.** Lo que
  importa es lo que se construye.

## Consecuencias

### Positivas

- Identidad personal arranca desde el día uno con un dominio que
  representa al owner.
- Blog técnico documentando el proyecto se vuelve palanca de portafolio.
- LifeHub no carga la decisión de nombre/dominio público; puede iterar
  libremente.
- Migración futura del nombre público es barata.

### Negativas

- LifeHub no tiene "marca propia" mientras viva como subdominio. Si en
  algún punto se quisiera convertir en SaaS público con identidad
  comercial, requeriría rebrand y migración.
- SEO de LifeHub vive bajo `curbsidenigma.com`, lo que en el futuro
  podría ser limitante si se quisiera posicionarlo independientemente.

### Neutras

- El owner debe decidir si comprar `.com`, `.dev`, u otro TLD para
  `curbsidenigma`. Recomendación: `.com` por universalidad. Registrar
  recomendado: Cloudflare o Porkbun.

## Cronograma

| Cuándo | Acción |
|---|---|
| Esta semana | Comprar `curbsidenigma.com` (~$10-15 USD/año en Cloudflare o Porkbun). Dejar dominio estacionado. |
| Fase 1 (semanas 1-4) | Todo en `localhost`. No tocar DNS. |
| Fase 4 (mes 3-4) | Configurar `lifehub.curbsidenigma.com` apuntando al hosting (probablemente Vercel para frontend, Railway/Render para backend). |
| Fase 4+ (post-blog) | Levantar blog en raíz `curbsidenigma.com` con Astro/Next.js. |
| Mes 6+ | Reevaluar si LifeHub merece dominio propio. |

## Anti-patrones a evitar

- ❌ Empezar a configurar DNS antes de Fase 4. No hay nada que apuntar.
- ❌ Comprar múltiples TLDs "por si acaso" (`.com`, `.dev`, `.io`,
  `.app`). Uno basta.
- ❌ Tratar de hospedar el blog y LifeHub bajo el mismo subdominio raíz
  con reverse proxy custom. Subdominios separados son más simples.
- ❌ Posponer el primer post del blog hasta tener "algo presentable".
  El primer post puede ser sobre la decisión de stack, antes de escribir
  una línea de código.
