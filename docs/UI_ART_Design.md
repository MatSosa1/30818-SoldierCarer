# UI, Arte y Entornos — SoldierCarer

**Proyecto:** SoldierCarer · Grupo 6
**Motor:** Godot 4.6.2 + OpenXR
**Documento:** Identidad visual, interfaces, HUD y diseño de escenarios
**Versión:** 1.0

---

## 1. Identidad visual

SoldierCarer combina **dos lenguajes visuales**:

1. **Documento clasificado (analógico/militar):** menús como carpetas confidenciales, notas adhesivas, hojas de reporte a máquina de escribir, sellos de tinta. Transmite el rol militar y la narrativa de misión.
2. **Tecnología de IA 2038 (futurista):** mapa holográfico, menú de pausa con contornos en **azul eléctrico** neón sobre fondo oscuro. Marca la presencia del gobierno y su IA.

**Estilo de modelado 3D:** low-poly estilizado con bordes definidos (rendimiento VR + legibilidad). **Iluminación:** día nublado con humo; focos de emergencia como únicas fuentes de luz artificial en interiores, que además cumplen función de orientación.

## 2. Paleta cromática

> **Aviso (decisión D3, ver `Contexto.md §8`):** la tabla original en `ArteVisualSoldierCarer.md` tiene HEX que **no coinciden con sus etiquetas** (p.ej. "Verde militar apagado = #E7A17B" es salmón; "Gris urbano = #1D6000" es verde). A continuación la **paleta corregida propuesta**; confirmar con el encargado de arte. Los colores **funcionales del HUD** (rojo/verde/azul) sí eran coherentes y se conservan.

### 2.1 Paleta funcional (semafórica) — CONFIRMADA, no cambiar sin razón

Estos colores comunican estado y son críticos para la legibilidad:

| Función                | HEX       | Uso                                               |
| ---------------------- | --------- | ------------------------------------------------- |
| Rojo crítico           | `#CC0000` | Herido agonizante / salud del jugador crítica     |
| Amarillo crítico (HUD) | `#DAA520` | Herido en estado crítico                          |
| Verde estable          | `#228B22` | Herido estable / confirmación positiva            |
| Azul eléctrico         | `#00BFFF` | Tecnología de IA, mapa holográfico, menú de pausa |

### 2.2 Paleta ambiental / UI — CORREGIDA (a confirmar)

| Color                 | HEX original          | HEX propuesto | Uso                                       |
| --------------------- | --------------------- | ------------- | ----------------------------------------- |
| Verde militar apagado | `#E7A17B` (salmón ❌) | `#4B5320`     | Uniformes, elementos de UI militar        |
| Gris urbano           | `#1D6000` (verde ❌)  | `#5A5A5A`     | Estructuras, pavimento, elementos neutros |
| Ocre oxidado          | `#8B6914`             | `#8B6914` ✅  | Vehículos, puertas, objetos derruidos     |
| Beige gastado         | `#F5F2EB`             | `#F5F2EB` ✅  | Fondos de menú, papel, documentos         |
| Amarillo nota         | `#F0C040`             | `#F0C040` ✅  | Notas adhesivas, resaltado de selección   |

> Nota (D4): existen **dos amarillos por función** — `#F0C040` para sticky notes de menú y `#DAA520` para el estado crítico del HUD. Es intencional; no unificar.

### 2.3 Paleta por zona (entorno)

| Zona               | Paleta dominante                                      | Función comunicativa                                      |
| ------------------ | ----------------------------------------------------- | --------------------------------------------------------- |
| E1 Calle principal | Grises, beige desgastado, polvo                       | Ciudad abandonada, exposición al peligro en campo abierto |
| E2 Edificio        | Grises desintegrados, polvo blanco, negro carbonizado | Peligro, desorientación, tensión por baja visibilidad     |

## 3. Tipografía e iconografía

| Elemento                         | Decisión                                                                     |
| -------------------------------- | ---------------------------------------------------------------------------- |
| Tipografía UI                    | Fuente de máquina de escribir / militar (coherencia "documento clasificado") |
| Iconografía                      | Iconos simples, alto contraste, rojo/verde para lectura rápida bajo tensión  |
| Etiquetas de sección (dashboard) | Estilo monospace (coherente con la estética de desarrollo del equipo)        |

> **Placeholder:** hasta tener las fuentes finales, usar la fuente por defecto de Godot marcada como `# PLACEHOLDER: fuente máquina de escribir` y registrarla en `Elementos_Faltantes.md`.

## 4. HUD durante la misión

Filosofía: **mínimo intrusivo y diegético**. Solo se muestra la información crítica del momento; parte del HUD vive dentro del mundo del juego (refuerza inmersión VR).

| Elemento                | Tipo         | Posición                    | Función                                                                           | RF          |
| ----------------------- | ------------ | --------------------------- | --------------------------------------------------------------------------------- | ----------- |
| Mapa 2D de muñeca       | Diegético    | Muñeca izquierda            | Zona, posición del jugador e iconos de heridos con urgencia; selección de destino | RF-06/07/08 |
| Focos de emergencia     | Diegético    | Sobre cada punto de rescate | Estado del herido por color (verde/amarillo/rojo parpadeante); se apagan si muere | RF-11/13    |
| Salud del jugador       | Diegético    | Pantalla completa           | Tinte rojo creciente (sin barra numérica)                                         | RF-05       |
| Temporizador de misión  | No diegético | Esquina superior derecha    | Cuenta regresiva; se acelera visualmente en los últimos minutos                   | RF-34       |
| Indicador de cargador   | Diegético    | Inferior derecha            | Balas restantes (X/7); solo con pistola en mano                                   | RF-27       |
| Confirmación de rescate | No diegético | Centro (breve)              | Mensaje +RESCATE + sonido al estabilizar                                          | RF-35       |

### 4.1 Lógica de color del HUD (semáforo)

- **Verde `#228B22`:** soldado estable, sin riesgo inmediato → priorizar a otro.
- **Amarillo `#DAA520`:** soldado crítico → atención próxima.
- **Rojo `#CC0000`:** peligro máximo (herido agonizante / salud del jugador crítica).
- **Azul eléctrico `#00BFFF`:** tecnología de IA (menú de pausa, pantallas del entorno).

> **Discrepancia D1 (temporizador):** Concepto dice 20 min, HUD dice 10 min. Implementar como **valor `@export` parametrizable** (base propuesta 10 min) y confirmar.

## 5. Menús

### 5.1 Menú principal

Refugio temporal: sala destruida con mesa de trabajo. Sobre una **carpeta gris con sello "CONFIDENTIAL" en rojo** aparecen **notas adhesivas** amarillas como botones: **JUGAR / CONTROLES / OPCIONES / CREDITOS / SALIR**, en dos columnas alternadas sobre la tapa de la carpeta. Props: kit de primeros auxilios abierto, bidón de alcohol, escombros, ventana rota. Interacción: apuntar+seleccionar con controlador VR.

- Estado: **ya implementado en Godot 4.6.2** (según Arte Visual, Fig. 2). Botón Play enlazado a `views/Mision.tscn`.
- **CONTROLES** y **CREDITOS** (agregadas en el pulido de S11) no abren la carpeta: cambian a `views/Controles.tscn` y `views/Creditos.tscn` (ver §5.5), que vuelven al menú con su propio botón.

### 5.2 Menú de opciones

La carpeta se despliega revelando una hoja de reporte militar con: **AUDIO, GRÁFICOS, CONTROLES, ACCESIBILIDAD** (confort VR: intensidad de teletransporte, etc.), **VOLVER**. Continuidad visual con el menú principal (mismo fondo y mesa).

### 5.3 Pantalla de estado inicial

Transición narrativa: documentos asentados sobre la mesa "antes de la misión". Puente entre menú e inicio de misión.

### 5.4 Menú de pausa

Panel flotante centrado, fondo desenfocado. Estética **tecnológica 2038**: contornos azul eléctrico sobre fondo oscuro semitransparente. A la izquierda, **mapa táctico 2D** estilo neón (posición del jugador/heridos); a la derecha, botones **REANUDAR / OPCIONES / SALIR** (mayúsculas bold). En producción.

### 5.5 Pantallas de consulta: controles y créditos

Dos pantallas de **solo lectura** que comparten script (`scripts/Menus/pantalla_documento.gd`) y estética "documento clasificado": hojas de papel beige `#F5F2EB` iluminadas sobre el fondo de pared derruida, títulos en la tipografía manuscrita del menú (Caveat) y un único botón **VOLVER AL MENU (o ESC)**. Entran y salen con fundido a negro, igual que el resto de las transiciones.

- **CONTROLES** (`views/Controles.tscn`): dos hojas en paralelo, **VR (visor OpenXR)** y **Escritorio (sin visor)**, con la tabla acción → control de cada modo y una nota al pie por hoja (el jugador no camina; con un ítem en la mano el mouse no gira la vista). Es la versión in-game de [Controles.md](../Controles.md) y cubre la categoría "CONTROLES" que el menú de opciones (§5.2, RF-38) solo listaba como rótulo.
- **CREDITOS** (`views/Creditos.tscn`): tres fichas, una por integrante, con nombre, rol y sus tareas concretas en el proyecto; al pie, la línea de identidad del juego.
- Ambas fijan `keep_aspect = KEEP_WIDTH` en su cámara: el encuadre se calcula sobre un área segura 16:9 para que ninguna ventana angosta recorte las tablas.

## 6. Escenarios (entornos)

Dos escenarios interconectados por el mapa 2D (no hay desplazamiento físico entre ellos). Ambos ~50 m.

### 6.1 E1 — Calle principal (exterior)

Punto de inicio de la misión; primer paciente. Carril de ~50 m con dos carriles vehiculares bloqueados por vehículos abandonados/escombros. Edificios laterales dañados con grafitis de la Oposición. Parque cercano con pocos árboles.

**Objetos:**

| Objeto                      | Tipo        | Función                                         |
| --------------------------- | ----------- | ----------------------------------------------- |
| Vehículo abandonado/volcado | Decorativo  | Oculta parcialmente al herido; cobertura pasiva |
| Grafiti de la Oposición     | Decorativo  | Narrativo (marca del conflicto)                 |
| Árboles del parque          | Decorativo  | Ambientación urbana                             |
| Escombros / vidrios rotos   | Decorativo  | Ruido al pisar (no interactivo)                 |
| Foco de emergencia          | Funcional   | Ubica al jugador y marca punto de rescate       |
| Soldado herido              | Interactivo | NPC objetivo                                    |

### 6.2 E2 — Edificio (interior)

Sala de estar de un edificio de oficinas consumido por el conflicto (entorno rectangular). Suelo cubierto de vidrios rotos y papeleo que genera ruido al pisar. Baja visibilidad (tensión).

**Objetos:**

| Objeto                         | Tipo                    | Función                                       |
| ------------------------------ | ----------------------- | --------------------------------------------- |
| Muebles volcados (sillón/mesa) | Decorativo              | Ocultan parcialmente al herido                |
| Escombros internos / vidrios   | Decorativo              | Ruido al pisar alerta a opositores            |
| Escalera interior              | Decorativo              | Sugiere extensión del edificio (no accesible) |
| Puertas del edificio           | Decorativo              | Una entreabierta, otra en el suelo            |
| Foco de emergencia             | Funcional               | Iluminación + orientación                     |
| Soldado herido                 | Interactivo (principal) | NPC objetivo                                  |

### 6.3 Iluminación por escenario

- E1: luz difusa de día nublado + focos de emergencia en puntos de rescate.
- E2: interior oscuro; focos de emergencia como principal fuente de luz (tensión + orientación). Cuidar rendimiento (RNF-01): evitar exceso de luces dinámicas.

## 7. Ítems del kit médico (arte + mecánica)

| Ítem               | Apariencia                      | Gesto                               | Efecto                                         |
| ------------------ | ------------------------------- | ----------------------------------- | ---------------------------------------------- |
| Vendas             | Rollo blanco de gasa            | Movimiento circular sobre la herida | Detiene hemorragia (paso base)                 |
| Morfina            | Jeringa transparente            | Sacar y aplicar en el brazo         | Reduce tiempo de estabilización / alivia dolor |
| Alcohol            | Frasco blanco con líquido claro | Inclinar/volcar sobre la herida     | Desinfecta (requerido antes de suturar)        |
| Suturas            | Grapadora tipo suturador        | Presión para grapar                 | Cierra heridas profundas (gesto más técnico)   |
| Analgésicos orales | Pastillas                       | Acercar al paciente                 | Alivia dolor moderado (uso simple)             |

## 8. Objetos de UI/mundo a modelar

Confirmados en Arte Visual §6.4:

- **Médicos:** vendas, botella de alcohol, suturador tipo grapadora, pastillas, aguja (jeringa), kit médico.
- **Ambientación:** auto destruido, mesa, sofá, puerta, cristales rotos.
- **Interfaces:** mapa neón, sticky note, fondo tipo neón, grafiti.

## 9. Coherencia UI ↔ juego (checklist de diseño)

- La estética "documento clasificado" conecta la UI con la identidad narrativa militar.
- El color semafórico del HUD refleja exactamente la mecánica central (monitorear heridos).
- El mapa 2D vive en la muñeca (diegético) → refuerza inmersión.
- Durante el tratamiento, ausencia de HUD agresivo → el jugador se concentra en los gestos.
- El estilo low-poly es consistente con los menús 2D de papel; un estilo realista rompería la coherencia.
