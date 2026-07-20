# Personajes — SoldierCarer

**Proyecto:** SoldierCarer · Grupo 6
**Motor:** Godot 4.6.2 + OpenXR
**Documento:** Diseño de personajes, comportamientos, herramientas y acciones
**Versión:** 1.0

> Tres entidades: **Médico de combate** (jugador), **Soldado herido** (aliado NPC) y **Oposición** (enemigos). La IA de enemigos ya está prototipada en `feature/ia-enemigos-demo`.

---

## 1. Médico de combate (Jugador)

### 1.1 Descripción
El jugador encarna a un médico de combate desplegado en la ciudad en conflicto. Al ser VR en primera persona, **no hay avatar visible completo**: solo se ven las manos y parte del uniforme al mirar hacia abajo. Identidad **fija**, sin personalización (refuerza la inmersión y la coherencia narrativa).

### 1.2 Atributos

| Atributo | Detalle |
|---|---|
| Perspectiva | Primera persona VR (manos + uniforme parcial) |
| Uniforme | Traje militar verde oscuro con cruz roja de médico en el pecho |
| Mano izquierda | Levantada activa el mapa 2D; abre la mochila del kit médico |
| Mano derecha | Extrae y opera la pistola; interactúa con el kit médico |
| Salud | Sin barra numérica: la pantalla se **tiñe de rojo** al recibir daño / salud crítica |
| Personalización | Ninguna (identidad fija) |
| Locomoción | Solo teletransporte (sin desplazamiento continuo) |

### 1.3 Acciones y gestos (contrato de interacción VR)

| Acción | Gesto / Input VR | Resultado | RF |
|---|---|---|---|
| Abrir mapa | Levantar mano izquierda | Proyecta mapa 2D en la muñeca | RF-06 |
| Teletransportarse | Apuntar+seleccionar destino en el mapa | Reposiciona frente al objetivo | RF-08 |
| Abrir kit médico | Mano izquierda a la mochila | Despliega los ítems | RF-17 |
| Vendar | Movimiento **circular** del controlador sobre la herida | Detiene hemorragia (paso base) | RF-18 |
| Aplicar morfina | Sacar jeringa y aplicarla en el brazo | Reduce tiempo de estabilización / alivia dolor | RF-19 |
| Desinfectar | Gesto de **inclinación** para volcar alcohol | Desinfecta (requerido antes de suturar) | RF-20 |
| Suturar | Gesto de **presión** con la grapadora | Cierra heridas profundas (gesto más técnico) | RF-21 |
| Dar analgésico oral | Acercar pastilla al paciente | Alivia dolor moderado (uso simple) | RF-22 |
| Extraer pistola | Mano derecha a la cadera derecha | Saca la pistola de la funda | RF-25 |
| Disparar | Presionar gatillo | Dispara (raycast); emite `disparo_realizado(rayo)` | RF-26 |
| Recargar | Gesto/acción de recarga | Cambia de cargador (munición limitada) | RF-28 |

### 1.4 Notas de implementación (jugador)
- La demo trae un jugador **no-VR** (rota con mouse, dispara con clic) que ya expone `disparo_realizado(rayo)` y `recibir_dano()`. En **S1** se evoluciona a **rig OpenXR** (`XROrigin3D` + controladores) **conservando esos contratos** para no romper la IA de enemigos.
- El jugador está **fijo** (no traslada libremente); solo rota. Al teletransportarse, se reposiciona el origen VR.
- Feedback de daño ya implementado como `ColorRect` rojo + `Tween`; reutilizar para RF-05.

---

## 2. Soldado herido (Paciente / Aliado)

### 2.1 Descripción
NPC aliado inmovilizado en un **punto de rescate fijo**, señalado por un **foco de emergencia**. Su salud **decae por temporizador interno**, generando la presión de triaje. El jugador llega vía teletransporte y lo estabiliza con el kit.

### 2.2 Atributos

| Atributo | Detalle |
|---|---|
| Apariencia | Uniforme militar similar al jugador; heridas visibles (vendajes ensangrentados, postura de dolor) |
| Comportamiento IA | Estático; su salud decrece por temporizador |
| Señal de ubicación | Foco de emergencia sobre el punto de rescate, visible a distancia |
| Audio | Gemidos, peticiones de ayuda, confirmación de rescate exitoso |
| Interacción | El jugador lo selecciona en el mapa, se teletransporta y aplica tratamiento |

### 2.3 Estados de salud del herido (FSM)

```
ESTABLE (verde) ──t──► CRITICO (amarillo) ──t──► AGONIZANTE (rojo parpadeante) ──t──► MUERTO
```

| Estado | Color | Comportamiento | Efecto en juego |
|---|---|---|---|
| `ESTABLE` | Verde `#228B22` | Salud alta; decae lento | El jugador puede priorizar otro herido |
| `CRITICO` | Amarillo `#DAA520` | Decae más rápido | Requiere atención próxima |
| `AGONIZANTE` | Rojo `#CC0000` (parpadea) | Decae acelerado | Morirá pronto si no se actúa |
| `MUERTO` | Foco apagado | Inerte | No rescatable; icono se desactiva en el mapa (RF-14) |
| `ESTABILIZADO` | Verde fijo | Rescate exitoso | Suma puntuación (+RESCATE) y sale del bucle de decaimiento |

- El estado se refleja simultáneamente en el **foco de emergencia**, en el **icono del mapa** (RF-13) y en el audio del herido.
- Tiempos de decaimiento por estado **parametrizables con `@export`** (balanceo en S10/S11).

### 2.4 Secuencia de tratamiento (FSM)
Cada herido define la secuencia requerida según su herida. Patrón general:

```
SIN_ATENDER ──vendas──► LIMPIANDO ──alcohol──► SUTURANDO ──suturas──► ESTABILIZADO
                                   (+ morfina reduce tiempo; analgésico alivia dolor moderado)
```
- Completar la secuencia correcta emite `herido_estabilizado(id)` → suma score y detiene el decaimiento.
- Orden incorrecto o incompleto → penalización de tiempo / feedback de fallo (RF-24).

### 2.5 Placeholder actual
En la demo, el herido es una **cápsula placeholder** (`scripts/Herido/herido.gd`) con curación rudimentaria gateada por (a) zona despejada (`enemigos_activos == 0`) y (b) enfoque del jugador (comparación de **rumbo horizontal**). El sistema real de salud/decaimiento y secuencia de tratamiento se implementa en S4/S3. **Reemplazo sin refactor** cuando llegue el modelo final.

---

## 3. Oposición (Enemigos)

### 3.1 Descripción y tono
La Oposición son **civiles** que rechazan el implante de IA gubernamental. No son monstruos: tienen motivaciones comprensibles, lo que sostiene la **ambigüedad moral**. **Regla de diseño:** ningún enemigo porta equipamiento militar completo; la asimetría visual refuerza que son civiles (RNF-18). Al ser derrotados caen sin animaciones excesivas (el foco es la medicina, no el combate).

### 3.2 Arquetipos

| Tipo | Apariencia | Comportamiento | Peligro |
|---|---|---|---|
| **Opositor con pistola** | Ropa civil desgastada, pistola en mano | Avanza y dispara a distancia media al detectar al jugador | Medio: ataca de lejos, hay margen de reacción |
| **Opositor con navaja** | Ropa civil oscura, navaja, postura agresiva | Avanza rápido y **esquiva reactivamente**; embiste en cuerpo a cuerpo | Alto: debe neutralizarse antes de que entre en rango |

### 3.3 FSM — Opositor con pistola (`enemigo_arma.gd`, existente)

```
AVANCE ──(a rango medio)──► DISPARO ──(sin salud)──► NEUTRALIZADO
```
- `AVANCE`: se desplaza en línea recta hacia el jugador.
- `DISPARO`: se detiene a rango medio y dispara periódicamente.
- `NEUTRALIZADO`: salud 0 → inerte, emite `neutralizado`, se libera tras breve retardo.

### 3.4 FSM — Opositor con navaja (`enemigo_cuchillo.gd`, existente)

```
AVANCE ──(apuntado/impactado)──► ESQUIVA ──► AVANCE ──(a rango cuerpo a cuerpo)──► EMBESTIDA
   └──────────────────────────(sin salud)──────────────────────────► NEUTRALIZADO
```
- `AVANCE`: se acerca rápido en línea recta.
- `ESQUIVA`: **reactiva**; se dispara en `_al_recibir_disparo()` validando que el raycast del jugador lo apunta (`rayo.get_collider() == self`), suscrito a `disparo_realizado`.
- `EMBESTIDA`: ataque cuerpo a cuerpo al entrar en rango.
- `NEUTRALIZADO`: igual que el de pistola.

### 3.5 Director de oleadas (`director_de_oleadas.gd`, existente)
- Genera **parejas arma+cuchillo** por carril, separadas perpendicularmente a la línea carril–jugador.
- 4 carriles (`Marker3D`): Adelante / Atrás / Izquierda / Derecha.
- Activa "Adelante" al iniciar; mantiene `enemigos_activos` y `score`.
- **Escalado de dificultad:** activa un carril nuevo cada `umbral_escalado` (3) bajas (RF-32).
- Contrato: consume la señal `neutralizado` de cada enemigo.

### 3.6 Daño y neutralización
- Un mismo disparo del jugador (a) dispara la esquiva reactiva del cuchillo y (b) aplica daño vía `recibir_dano()` si el collider lo implementa. Sistema unificado (no hay dos rutas separadas).
- Salud a 0 → `NEUTRALIZADO`. Sin ragdoll ni animación elaborada.

### 3.7 Audio (S8)
- Enemigos con **audio espacial 3D**: el jugador oye la dirección de pasos y disparos antes de verlos (RF-33/RF-45), reforzando la mecánica de percepción en VR con visibilidad reducida.

---

## 4. Matriz de interacción entre entidades

| ↓ actúa sobre → | Jugador | Herido | Enemigo |
|---|---|---|---|
| **Jugador** | — | Estabiliza (kit médico) | Dispara / neutraliza |
| **Herido** | Emite audio/urgencia | Decae solo | — |
| **Enemigo (pistola)** | Dispara a distancia media | — (indirecto: bloquea curación) | — |
| **Enemigo (navaja)** | Embiste cuerpo a cuerpo | — (indirecto) | — |

> Los enemigos no atacan directamente al herido, pero su presencia **bloquea la curación** (la zona debe estar razonablemente despejada / el jugador debe poder concentrarse), lo que fuerza el dilema de triaje.

## 5. Placeholders de personajes (registrar en `Elementos_Faltantes.md`)

| Entidad | Placeholder actual | Asset final requerido |
|---|---|---|
| Jugador (manos/uniforme) | Rig sin manos VR (demo no-VR) | Modelo de manos + uniforme VR, animaciones de gesto |
| Herido | Cápsula `PH_` | Modelo con uniforme, heridas, posturas de dolor, set de audio |
| Opositor pistola | Cápsula naranja + `Label3D` | Modelo civil con pistola, animación de disparo |
| Opositor navaja | Cápsula roja + `Label3D` | Modelo civil con navaja, animación de embestida |
