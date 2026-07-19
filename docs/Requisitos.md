# Requisitos — SoldierCarer

**Proyecto:** SoldierCarer · Grupo 6
**Motor:** Godot 4.6.2 + OpenXR
**Documento:** Requisitos funcionales (RF) y no funcionales (RNF)
**Versión:** 1.0

> Convención de IDs: `RF-XX` funcionales, `RNF-XX` no funcionales. Cada requisito tiene **prioridad** (Alta / Media / Baja) y **sprint** de referencia (ver `Planificacion_Sprints.md`). Los IDs son estables: no se renumeran, solo se agregan.

---

## 1. Requisitos funcionales

### 1.1 Sistema VR y jugador

| ID | Requisito | Prioridad | Sprint |
|---|---|---|---|
| RF-01 | El juego debe inicializar OpenXR y detectar el headset y controladores VR al arrancar. | Alta | S1 |
| RF-02 | El jugador ve en primera persona sus **manos** y parte del **uniforme** al mirar hacia abajo; no existe cuerpo completo visible. | Alta | S1 |
| RF-03 | El jugador **no se desplaza físicamente de forma continua**; la posición cambia solo por teletransporte. | Alta | S1/S2 |
| RF-04 | Las manos VR replican gestos del jugador (rotación, agarre) mapeados a los controladores. | Alta | S1 |
| RF-05 | El jugador puede recibir daño; su estado crítico se comunica **tiñendo la pantalla de rojo** (sin barra numérica). | Alta | S6 |

### 1.2 Navegación (mapa 2D)

| ID | Requisito | Prioridad | Sprint |
|---|---|---|---|
| RF-06 | Al **levantar la mano izquierda**, se proyecta un **mapa 2D** en la muñeca. | Alta | S2 |
| RF-07 | El mapa muestra la **posición del jugador** y los **iconos de soldados heridos** con indicador de urgencia (verde/amarillo/rojo). | Alta | S2 |
| RF-08 | El jugador selecciona un destino con el controlador y es **teletransportado** frente al objetivo dentro del escenario correspondiente. | Alta | S2 |
| RF-09 | El mapa permite moverse **entre los dos escenarios** (E1 Calle, E2 Edificio) sin desplazamiento físico. | Alta | S2 |
| RF-10 | Un icono de herido se **desactiva/atenúa** en el mapa si el soldado muere. | Media | S2/S4 |

### 1.3 Sistema de heridos

| ID | Requisito | Prioridad | Sprint |
|---|---|---|---|
| RF-11 | Los soldados heridos aparecen en **puntos de rescate fijos**, marcados con **focos de emergencia**. | Alta | S4 |
| RF-12 | Cada herido tiene un estado de salud que **decae por temporizador interno**: Estable → Crítico → Agonizante → Muerto. | Alta | S4 |
| RF-13 | El estado del herido se comunica visualmente por color semafórico (verde/amarillo/rojo parpadeante) en el foco y en el mapa. | Alta | S4 |
| RF-14 | Si el temporizador de un herido llega a 0 sin estabilización, el herido **muere** y ya no puede rescatarse; su foco se apaga. | Alta | S4 |
| RF-15 | El herido emite **audio** (gemidos, peticiones de ayuda, confirmación de rescate exitoso). | Media | S4/S8 |
| RF-16 | Estabilizar exitosamente a un herido **suma puntuación** y muestra confirmación (+RESCATE). | Alta | S4/S10 |

### 1.4 Kit médico y curación

| ID | Requisito | Prioridad | Sprint |
|---|---|---|---|
| RF-17 | El jugador abre el **kit médico** (mochila) con la mano izquierda, mostrando los implementos disponibles. | Alta | S3 |
| RF-18 | **Vendas:** gesto de movimiento circular alrededor de la herida; detiene hemorragias externas (paso base). | Alta | S3 |
| RF-19 | **Morfina (jeringa):** sacar del kit y aplicar en el brazo; reduce el tiempo necesario para estabilizar y alivia dolor. | Alta | S3 |
| RF-20 | **Alcohol:** gesto de inclinación para volcar sobre la herida; desinfecta (requerido antes de suturar para evitar penalización de tiempo). | Media | S3 |
| RF-21 | **Suturas (grapadora):** gesto de presión para grapar; cierra heridas profundas; es el gesto más técnico (requiere precisión). | Media | S3 |
| RF-22 | **Analgésicos orales:** acercar al paciente; uso simple para heridos conscientes con dolor moderado. | Baja | S3 |
| RF-23 | Cada herido requiere una **secuencia de tratamiento** según su tipo de herida; completarla correctamente lo estabiliza. | Alta | S3/S4 |
| RF-24 | El sistema da **feedback de éxito/fallo** por cada gesto (visual y sonoro). | Alta | S3 |

### 1.5 Combate y arma

| ID | Requisito | Prioridad | Sprint |
|---|---|---|---|
| RF-25 | El jugador extrae la **pistola** de la funda de la cadera derecha con el controlador derecho (gesto físico). | Alta | S5 |
| RF-26 | La pistola dispara por raycast; munición limitada a **7 balas por cargador**, **3 cargadores** (21 balas) al inicio. | Alta | S5 |
| RF-27 | El indicador de cargador (X/7) es visible **solo cuando la pistola está en mano**. | Media | S5/S6 |
| RF-28 | Existe recarga de cargador con un gesto/acción del controlador. | Media | S5 |

### 1.6 IA de enemigos (Oposición) — base ya implementada en `feature/ia-enemigos-demo`

| ID | Requisito | Prioridad | Sprint |
|---|---|---|---|
| RF-29 | **Opositor con pistola:** avanza y se detiene a rango medio para disparar al jugador (FSM `AVANCE → DISPARO`). | Alta | S0 (hecho) / S5 |
| RF-30 | **Opositor con navaja:** avanza y **esquiva de forma reactiva** al ser apuntado/impactado; embiste en cuerpo a cuerpo. | Alta | S0 (hecho) / S5 |
| RF-31 | Al llegar la salud de un enemigo a 0, pasa a estado **`NEUTRALIZADO`** y se desactiva sin animaciones excesivas. | Alta | S0 (hecho) |
| RF-32 | El **`DirectorDeOleadas`** genera enemigos por carriles y **escala dificultad** activando un carril nuevo cada N bajas. | Media | S0 (hecho) / S10 |
| RF-33 | Los enemigos usan **audio espacial 3D** para que el jugador perciba su dirección antes de verlos. | Alta | S8 |

### 1.7 HUD y feedback

| ID | Requisito | Prioridad | Sprint |
|---|---|---|---|
| RF-34 | **Temporizador de misión** visible (esquina superior derecha); se acelera visualmente en los últimos minutos. | Alta | S6/S10 |
| RF-35 | **Confirmación de rescate** (+RESCATE) aparece brevemente al centro y desaparece rápido, con sonido. | Media | S6 |
| RF-36 | El HUD prioriza lo **diegético y mínimo**; durante el tratamiento no hay elementos agresivos que distraigan del gesto. | Alta | S6 |

### 1.8 Menús y navegación de UI

| ID | Requisito | Prioridad | Sprint |
|---|---|---|---|
| RF-37 | **Menú principal** con estética de documento clasificado: carpeta CONFIDENTIAL + notas adhesivas (Jugar, Opciones, Salir). Interacción por apuntar+seleccionar. | Alta | S9 |
| RF-38 | **Menú de opciones**: Audio, Gráficos, Controles, Accesibilidad (confort VR: intensidad de teletransporte, etc.), Volver. | Media | S9 |
| RF-39 | **Pantalla de estado inicial** como transición narrativa (documentos sobre la mesa) antes de iniciar la misión. | Baja | S9 |
| RF-40 | **Menú de pausa** flotante centrado con fondo desenfocado; estética tecnológica 2038 (azul eléctrico); mapa táctico a la izquierda; Reanudar, Opciones, Salir. | Media | S9 |

### 1.9 Game loop y puntuación

| ID | Requisito | Prioridad | Sprint |
|---|---|---|---|
| RF-41 | La misión inicia con el despliegue del jugador en la zona de combate. | Media | S10 |
| RF-42 | El tiempo de misión se contabiliza de forma **diferenciada**: normal frente a un herido; calculado por distancia al desplazarse por el mapa. | Media | S10 |
| RF-43 | La misión **termina** cuando se agota el tiempo **o** el jugador pierde toda su salud. | Alta | S10 |
| RF-44 | Al finalizar se muestra una **puntuación** basada en el número de soldados rescatados con éxito. | Alta | S10 |

### 1.10 Audio

| ID | Requisito | Prioridad | Sprint |
|---|---|---|---|
| RF-45 | **Audio espacial 3D** para efectos de enemigos y entorno (dirección de pasos, disparos). | Alta | S8 |
| RF-46 | Tres partituras musicales por estado: menú (calma), combate normal (tensión media), estado crítico (intenso, pulso cardíaco). | Media | S8 |
| RF-47 | SFX: disparos, pasos, explosiones lejanas, ambiente urbano, manipulación del kit, voz del herido, confirmación de rescate. | Media | S8 |

---

## 2. Requisitos no funcionales

### 2.1 Rendimiento
| ID | Requisito | Prioridad |
|---|---|---|
| RNF-01 | Mantener **90+ FPS** estables en el headset objetivo (requisito de confort VR). | Alta |
| RNF-02 | Estilo **low-poly** con materiales simples; presupuesto de polígonos y de draw calls controlado por escena. | Alta |
| RNF-03 | Tiempos de carga entre menú y misión razonables, con transición (fade a negro). | Media |

### 2.2 Usabilidad y confort VR
| ID | Requisito | Prioridad |
|---|---|---|
| RNF-04 | **Sin movimiento continuo de cámara**: locomoción exclusiva por teletransporte para minimizar mareo. | Alta |
| RNF-05 | Ajustes de **accesibilidad/confort** en opciones (intensidad de teletransporte, etc.). | Media |
| RNF-06 | Interacciones VR con **tolerancias de gesto** ajustables para no frustrar al jugador. | Media |
| RNF-07 | Feedback claro (visual + sonoro) en cada acción relevante. | Alta |

### 2.3 Compatibilidad
| ID | Requisito | Prioridad |
|---|---|---|
| RNF-08 | Compatibilidad con headsets principales vía **OpenXR** (no dependencias propietarias). | Alta |
| RNF-09 | Ejecutable en **Godot 4.6.2**; no usar APIs deprecadas ni de versiones futuras. | Alta |

### 2.4 Mantenibilidad y calidad de código
| ID | Requisito | Prioridad |
|---|---|---|
| RNF-10 | **Nomenclatura en español** consistente (nodos, scripts, señales, estados de FSM), coherente con la demo existente. | Alta |
| RNF-11 | Estructura de carpetas y escenas según `Arquitectura.md`; un sistema = un directorio bajo `scripts/`. | Alta |
| RNF-12 | Parámetros de balanceo expuestos con `@export` para ajuste sin tocar lógica. | Media |
| RNF-13 | **GitFlow** con ramas `feature/*`, **commits semánticos** y sin `push` automático (ver `Planificacion_Sprints.md`). | Alta |
| RNF-14 | Todo asset faltante se sustituye por **placeholder** trazable (ver `Contexto.md §6`) y se reporta en `Elementos_Faltantes.md`. | Alta |

### 2.5 Audio
| ID | Requisito | Prioridad |
|---|---|---|
| RNF-15 | SFX de **librerías libres de derechos**; música **original** del equipo. | Media |
| RNF-16 | Implementación de audio 3D con la API de audio de Godot 4 y `AudioListener3D`. | Alta |

### 2.6 Narrativa y coherencia
| ID | Requisito | Prioridad |
|---|---|---|
| RNF-17 | Toda UI, HUD y arte deben reforzar la identidad narrativa (2038, documento clasificado / tecnología de IA). | Media |
| RNF-18 | Los enemigos se representan como **civiles** (sin equipamiento militar completo) para sostener la ambigüedad moral. | Media |

---

## 3. Trazabilidad rápida (RF ↔ Sprint)

| Sprint | RF asociados |
|---|---|
| S0 (demo, hecho) | RF-29, RF-30, RF-31, RF-32 |
| S1 Core VR | RF-01, RF-02, RF-03, RF-04 |
| S2 Navegación | RF-06, RF-07, RF-08, RF-09, RF-10 |
| S3 Kit médico | RF-17..RF-24 |
| S4 Heridos | RF-11..RF-16, RF-23 |
| S5 Combate | RF-25, RF-26, RF-27, RF-28, RF-29, RF-30 |
| S6 HUD | RF-05, RF-27, RF-34, RF-35, RF-36 |
| S7 Escenarios | (soporte a RF-09, RF-11) |
| S8 Audio | RF-15, RF-33, RF-45, RF-46, RF-47 |
| S9 Menús | RF-37, RF-38, RF-39, RF-40 |
| S10 Game loop | RF-16, RF-32, RF-41, RF-42, RF-43, RF-44 |
| S11 Pulido | RNF-01..RNF-06 (verificación) |
