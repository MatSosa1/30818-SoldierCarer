# Contexto — SoldierCarer

**Proyecto:** SoldierCarer · *“El campo de batalla desde los ojos del que salva vidas”*
**Equipo:** Grupo 6 — Desarrollo de Videojuegos
**Motor:** Godot 4.6.2 + OpenXR
**Documento:** Contexto general del proyecto (planificación y diseño)
**Versión:** 1.0

---

## 1. Visión del producto

SoldierCarer es un **videojuego de Realidad Virtual en primera persona** que invierte la premisa habitual de los shooters bélicos: el jugador **no es el que dispara, sino el que salva vidas**. Encarna a un médico de combate desplegado en una ciudad capital devastada en el año **2038**, durante el enfrentamiento entre un gobierno que ha implantado IA en la mente de sus ciudadanos y la Oposición que la rechaza.

El objetivo del jugador es **localizar, alcanzar y estabilizar** a soldados heridos usando un kit médico manipulado con gestos VR reales, mientras se defiende de la Oposición con recursos limitados. **Ganar no significa eliminar enemigos; significa que nadie muera bajo su cuidado.** Ese dilema moral —seguir curando a un herido crítico o detenerse a defenderse— es el corazón de la experiencia.

## 2. Pilares de diseño

Toda decisión de implementación debe reforzar al menos uno de estos pilares:

1. **La medicina es el eje.** El combate es un recurso de emergencia, nunca la actividad principal. El ritmo lo marca la urgencia de los heridos, no los enemigos.
2. **Inmersión VR diegética.** La información crítica vive dentro del mundo (mapa en la muñeca, focos de emergencia, pantalla que se tiñe de rojo) en lugar de un HUD sobrepuesto agresivo.
3. **Confort VR primero.** La navegación por teletransporte (mapa 2D) evita el mareo por movimiento; es requisito de usabilidad, no un extra.
4. **Tensión moral.** Recursos escasos, tiempo limitado y decisiones de triaje: a quién atender primero, cuándo defenderse, a quién abandonar.
5. **Legibilidad bajo presión.** Estética low-poly y código de color semafórico (verde/amarillo/rojo) para lectura instantánea.

## 3. Ficha técnica

| Campo | Valor |
|---|---|
| Género | VR FPS / Simulación médica de combate |
| Perspectiva | Primera persona (VR) |
| Modo | Un jugador (sin multijugador) |
| Año narrativo | 2038 |
| Localidad | Ciudad capital en zona de conflicto |
| Motor | Godot 4.6.2 |
| Framework VR | OpenXR |
| Escenarios | 2 áreas interconectadas por mapa 2D (E1 Calle, E2 Edificio) |
| Locomoción | Teletransporte por selección en mapa 2D de muñeca (sin movimiento continuo) |
| Plataforma objetivo | Headsets VR compatibles con OpenXR |
| Rendimiento objetivo | 90+ FPS (requisito VR) |

## 4. Alcance

### 4.1 Dentro de alcance (MVP jugable)
- Rig de jugador VR con OpenXR (manos, mirada, holster, mochila).
- Navegación por mapa 2D de muñeca con teletransporte entre E1 y E2.
- Kit médico con 5 ítems y sus gestos (vendas, morfina, alcohol, suturas, analgésicos).
- Sistema de heridos con estados de salud que decaen por temporizador y puntos de rescate.
- Combate defensivo: pistola con munición limitada (7/cargador, 3 cargadores).
- IA de enemigos (Opositor con pistola y Opositor con navaja) — **ya prototipada** (ver §5).
- HUD diegético/mínimo: pantalla roja de daño, temporizador, indicador de cargador, confirmación de rescate, focos de emergencia.
- Menús: principal, opciones, estado inicial, pausa.
- Audio espacial 3D, música por estado, SFX.
- Game loop: puntuación por rescates, condición de fin (tiempo agotado o jugador eliminado), pantalla de resultados.

### 4.2 Fuera de alcance (esta versión)
- Multijugador.
- Personalización/creación de personaje.
- Mapa abierto de mundo o desplazamiento físico continuo.
- Más de 2 escenarios.
- Animaciones cinemáticas complejas o físicas avanzadas de ragdoll.

## 5. Estado actual del proyecto

Existe una demo funcional de **IA de enemigos** en la rama **`feature/ia-enemigos-demo`** (no mergeada a `main`). **El desarrollo continúa desde ahí, no desde cero.**

Lo ya implementado y verificado en la demo:
- Jugador fijo que solo rota en yaw; disparo por raycast con mira y trazador visual.
- 4 carriles de spawn (Adelante/Atrás/Izquierda/Derecha) y `DirectorDeOleadas`.
- Pareja arma+cuchillo por carril; ambos avanzan hacia el jugador.
- FSM del **Opositor con pistola** (`AVANCE → DISPARO`) y del **Opositor con navaja** (esquiva reactiva al ser apuntado/impactado, embestida).
- Salud a 0 → estado `NEUTRALIZADO` y desactivación.
- Escalado de dificultad: cada 3 bajas se activa un carril nuevo.
- Placeholder de herido con curación rudimentaria (barra de progreso condicionada a zona despejada + enfoque del jugador).

Todo está construido con **primitivas de Godot y colores planos** (sin assets finales), lo cual es coherente con la política de placeholders de este proyecto. El detalle de archivos, señales y convenciones está en `Arquitectura.md`.

## 6. Política de placeholders (OBLIGATORIA para Claude Code)

> Esta sección es de cumplimiento obligatorio. Se referencia desde `CLAUDE.md §3.1`.

El proyecto se desarrolla en paralelo a la producción de assets. **En ningún caso Claude Code debe detener el desarrollo, esperar assets, ni inventar un asset final** por su cuenta. En su lugar:

### 6.1 Regla general
Si al implementar una funcionalidad falta cualquier **asset, escenario o elemento** (modelo 3D, textura, material, animación, sprite de UI, clip de audio, fuente, icono, etc.) porque el encargado aún no lo ha entregado o se olvidó:

1. **Continúa con un placeholder funcional** que permita probar la mecánica.
2. Registra el faltante en `Elementos_Faltantes.md` (ver §7).

### 6.2 Cómo debe ser un placeholder
- **Geometría:** primitivas de Godot (`BoxMesh`, `CapsuleMesh`, `CylinderMesh`, `SphereMesh`, `PlaneMesh`) con `StandardMaterial3D` de color plano.
- **Color:** usa la paleta funcional del juego cuando comunique estado (rojo/amarillo/verde para heridos; azul eléctrico para tecnología/UI 2038). Para props neutros, gris.
- **Identificación:** el nodo raíz del placeholder se nombra con prefijo **`PH_`** (ej. `PH_KitMedico`, `PH_SoldadoHerido`) y lleva un `Label3D` con el nombre cuando ayude a la prueba.
- **Comentario en código/escena:** todo placeholder lleva un comentario `# PLACEHOLDER: <descripción de lo que falta y qué debe reemplazarlo>`.
- **Audio faltante:** deja el `AudioStreamPlayer3D` cableado y conectado en la lógica, pero **sin stream** (o con un beep genérico marcado como placeholder), de modo que solo falte asignar el clip final.
- **UI faltante:** usa `ColorRect`, `Label` y `Panel` con la fuente por defecto; deja los nodos y anclas listos para intercambiar por el arte final.

### 6.3 Principio de "swap sin refactor"
El placeholder debe estar montado de forma que **reemplazarlo por el asset final no requiera reescribir la lógica**: misma jerarquía de nodos, mismos nombres, mismas señales y puntos de anclaje. El asset final solo debería sustituir el `Mesh`/`Texture`/`Stream`.

## 7. Reporte de elementos faltantes (OBLIGATORIO)

Al **finalizar cada sprint** (y siempre que se introduzca un placeholder nuevo), Claude Code debe **crear o actualizar `Elementos_Faltantes.md`** con una entrada por cada elemento pendiente. Formato de cada entrada:

| Campo | Contenido |
|---|---|
| ID | `PH-###` correlativo |
| Elemento | Nombre del asset/escenario faltante |
| Tipo | Modelo 3D / Textura / Audio / Animación / UI / Fuente / Escenario / Otro |
| Dónde se usa | Escena(s) y nodo(s) donde vive el placeholder |
| Placeholder actual | Qué primitiva/color/marcador se dejó |
| Qué se necesita para reemplazar | Especificación mínima del asset final |
| Sprint | En qué sprint se detectó |
| Responsable | Encargado del asset (a completar por el equipo) |
| Estado | Pendiente / En producción / Resuelto |

Este es un **documento vivo**: cuando un asset final llega y se integra, su entrada pasa a `Resuelto` en lugar de borrarse, para mantener la trazabilidad.

## 8. Decisiones a confirmar (inconsistencias detectadas en los documentos base)

Como parte del rol de producción, se detectaron discrepancias entre los documentos fuente. Se proponen decisiones por defecto para no bloquear el desarrollo; **marcar con el encargado para confirmar**.

| # | Discrepancia | Fuentes en conflicto | Decisión propuesta (a confirmar) |
|---|---|---|---|
| D1 | **Duración de la misión.** | Concepto dice **20 min**; Arte Visual (HUD §4.1) dice **10 min**. | Usar **10 min** como base parametrizable (`export`), con conteo diferenciado (tiempo normal frente a herido, tiempo calculado por distancia al desplazarse en el mapa). Confirmar valor final. |
| D2 | **Número de escenarios.** | Entorno §1 menciona "tres escenarios"; el resto describe **2** (E1 Calle, E2 Edificio) y la ficha dice "2 áreas". | Trabajar con **2 escenarios** (E1, E2). "Tres" se toma como error de redacción. |
| D3 | **Paleta cromática: HEX no coinciden con etiquetas.** | Arte Visual §1.2: "Verde militar apagado = #E7A17B" (es salmón), "Gris urbano = #1D6000" (es verde). | Ver paleta corregida propuesta en `UI_ART_Design.md §2`. Confirmar con el encargado de arte. |
| D4 | **Amarillo tiene dos códigos.** | "Amarillo nota #F0C040" (menús) vs "Amarillo #DAA520" (HUD crítico). | Mantener **ambos por función**: `#F0C040` sticky notes, `#DAA520` estado crítico del HUD. Documentado en `UI_ART_Design.md §2`. |
| D5 | **Alcance del herido en la demo.** | El documento de IA excluía kit médico/curación, pero se añadió un placeholder de curación. | Aceptado como placeholder; el sistema real de curación se implementa en su sprint dedicado (ver `Planificacion_Sprints.md`). |

## 9. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Mareo por movimiento (motion sickness) | Alto (usabilidad VR) | Locomoción exclusiva por teletransporte; ajustes de confort en opciones. |
| Caída de framerate por debajo de 90 FPS | Alto | Estilo low-poly, materiales simples, límite de instancias, perfilado por sprint. |
| Assets no listos a tiempo | Medio | Política de placeholders (§6) + reporte de faltantes (§7). |
| Gestos VR poco fiables (vendaje/sutura) | Medio | Prototipar y ajustar tolerancias temprano; feedback claro de éxito/fallo. |
| Complejidad del triaje mal balanceada | Medio | Temporizadores y umbrales parametrizables (`export`) para ajuste fino en sprint de balanceo. |

## 10. Documentos relacionados

- `Requisitos.md` — RF y RNF.
- `Arquitectura.md` — estructura técnica y convenciones.
- `Personajes.md` — entidades y comportamientos.
- `UI_ART_Design.md` — interfaces, HUD, escenarios, paleta.
- `Planificacion_Sprints.md` — roadmap Scrum + GitFlow.
- `Elementos_Faltantes.md` — placeholders pendientes (vivo).
