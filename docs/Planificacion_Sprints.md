# Planificación de Sprints — SoldierCarer

**Proyecto:** SoldierCarer · Grupo 6
**Metodología:** Scrum + GitFlow · Commits semánticos (Conventional Commits)
**Documento:** Roadmap de sprints y flujo de trabajo Git
**Versión:** 1.0

> Este documento planifica el desarrollo por sprints y define **cómo trabaja Claude Code con Git**. Es la referencia operativa para cada entrega de código.

---

## 1. Marco de trabajo (Scrum)

- **Sprints** temáticos por sistema. Cada sprint agrupa funcionalidades relacionadas y produce incremento jugable/probable.
- **Definición de Terminado (DoD)** por tarea:
  1. Funcionalidad implementada y probada (aunque sea con placeholders).
  2. Requisitos (RF/RNF) asociados cubiertos.
  3. Placeholders introducidos registrados en `Elementos_Faltantes.md`.
  4. Archivos preparados con `git add` y **mensaje de commit semántico entregado** (sin push).
  5. Rama de la funcionalidad **seleccionada (checked out)** para revisión del encargado.
- **Orden recomendado:** S1 → S2 → S3/S4 (pueden solaparse) → S5 → S6 → S7 → S8 → S9 → S10 → S11. Ajustable según prioridades del equipo y la rúbrica.

## 2. Flujo de trabajo Git (OBLIGATORIO)

### 2.1 Modelo de ramas (GitFlow)
```
main        ← estable / entregables al profesor (tags de versión)
  └─ develop  ← integración continua de features
       ├─ feature/vr-core
       ├─ feature/mapa-navegacion
       ├─ feature/kit-medico
       └─ ...
```
- `main`: solo versiones estables/entregables. **Claude Code NUNCA commitea ni mergea directo a `main`.**
- `develop`: rama de integración. Las features se mergean aquí (merge manual del encargado).
- `feature/*`: **una rama por funcionalidad o grupo de funcionalidades** (un sprint puede tener 1 o varias features).
- Rama existente: **`feature/ia-enemigos-demo`** (demo ya hecha). **Primer paso del equipo:** mergear esta rama a `develop` manualmente antes de abrir nuevas features encima.

### 2.2 Reglas de commits
- **Formato Conventional Commits:** `tipo: descripción`
  - Tipos: `feat` (funcionalidad), `fix` (corrección), `docs` (documentación), `refactor` (reestructura sin cambio de comportamiento), `test` (pruebas), `chore` (tareas de mantenimiento), `perf` (rendimiento), `style` (formato).
  - **Tipo en inglés, descripción en español**, imperativa, minúscula, sin punto final. (Coherente con la demo: `feat: Demo funcional de IA de enemigos con FSM reactiva`).
- **Un commit = un cambio lógico coherente.** Preferir varios commits pequeños y semánticos a uno gigante.

### 2.3 Procedimiento por tarea (lo que Claude Code entrega)
En cada tarea Claude Code debe:
1. Implementar la funcionalidad (con placeholders si falta algo).
2. **`git add <archivos concretos>`** — nunca `git add .` a ciegas; listar los archivos tocados.
3. **Entregar el comando de commit listo**, por ejemplo:
   ```bash
   git commit -m "feat: agregar mapa 2D de muñeca con selección de destino"
   ```
4. **NO ejecutar `git push`** (el push es manual, lo hace el encargado).
5. **Dejar la rama `feature/…` seleccionada (checked out)** para que el encargado revise, confirme, haga push y avance.

> Claude Code puede ejecutar el `git commit` para dejar el historial listo, pero **jamás** `git push`, `git merge` a `main`, ni borrado de ramas. Si el encargado prefiere ejecutar también el commit a mano, Claude entrega el `git add` hecho y el mensaje de commit textual.

### 2.4 Apertura de una feature (plantilla)
```bash
git checkout develop
git pull            # (manual por el encargado, si aplica)
git checkout -b feature/<nombre-corto-en-kebab-case>
# ... trabajo de Claude Code ...
git add <archivos>
git commit -m "feat: ..."
# (queda en feature/<...>, sin push)
```

## 3. Roadmap de sprints

> Cada sprint indica: objetivo, RF/RNF cubiertos, **rama sugerida** y **ejemplos de commits semánticos**. Los ejemplos son guía; Claude Code ajusta los archivos reales según el estado del repo.

### S0 — Demo de IA de enemigos ✅ (hecha)
- **Rama:** `feature/ia-enemigos-demo` (pendiente de merge a `develop`).
- **Entregado:** FSM de enemigos (arma/cuchillo), director de oleadas, escalado de dificultad, placeholder de herido, jugador no-VR de prueba.
- **Acción del equipo:** revisar y mergear a `develop`.

### S1 — Núcleo VR (OpenXR)
- **Objetivo:** convertir el jugador de prueba en un **rig VR real** con OpenXR, manos y locomoción base, **conservando** los contratos `disparo_realizado` y `recibir_dano`.
- **RF/RNF:** RF-01, RF-02, RF-03, RF-04 · RNF-04, RNF-08, RNF-09.
- **Rama:** `feature/vr-core`.
- **Commits ejemplo:**
  ```
  feat: inicializar OpenXR y configurar XROrigin3D del jugador
  feat: mapear controladores VR a manos con agarre básico
  refactor: adaptar jugador de mouse a rig VR conservando señal de disparo
  docs: documentar setup de OpenXR en Arquitectura
  ```

### S2 — Navegación (mapa 2D + teletransporte)
- **Objetivo:** mapa de muñeca con iconos de heridos y teletransporte entre E1/E2.
- **RF/RNF:** RF-06..RF-10 · RNF-04.
- **Rama:** `feature/mapa-navegacion`.
- **Commits ejemplo:**
  ```
  feat: proyectar mapa 2D al levantar la mano izquierda
  feat: mostrar iconos de heridos con color de urgencia en el mapa
  feat: teletransportar al jugador al destino seleccionado
  feat: alternar escenario activo E1/E2 al teletransportarse
  ```

### S3 — Kit médico y curación
- **Objetivo:** apertura del kit y los 5 ítems con sus gestos y efectos; secuencia de tratamiento.
- **RF/RNF:** RF-17..RF-24 · RNF-06, RNF-07.
- **Rama:** `feature/kit-medico`.
- **Commits ejemplo:**
  ```
  feat: abrir kit médico desde la mochila con la mano izquierda
  feat: implementar gesto de vendaje con detección circular
  feat: implementar morfina, alcohol, suturas y analgésicos
  feat: validar secuencia de tratamiento y emitir herido_estabilizado
  fix: corregir tolerancia del gesto de sutura
  ```

### S4 — Sistema de heridos
- **Objetivo:** estados de salud con decaimiento por temporizador, puntos de rescate, focos de emergencia, muerte y feedback.
- **RF/RNF:** RF-11..RF-16, RF-23.
- **Rama:** `feature/sistema-heridos`.
- **Commits ejemplo:**
  ```
  feat: agregar FSM de salud del herido con decaimiento por tiempo
  feat: colocar puntos de rescate con focos de emergencia
  feat: sincronizar color de urgencia entre foco y mapa
  feat: manejar muerte del herido y apagar su foco
  ```

### S5 — Combate y arma
- **Objetivo:** pistola VR (holster, munición, disparo, recarga) integrada con la IA existente; extraer `enemigo_base.gd`.
- **RF/RNF:** RF-25..RF-30.
- **Rama:** `feature/combate-pistola`.
- **Commits ejemplo:**
  ```
  feat: extraer pistola del holster de la cadera derecha
  feat: implementar munición limitada y recarga de cargador
  refactor: extraer enemigo_base con la FSM común sin cambiar comportamiento
  test: verificar neutralización de enemigos con daño acumulado
  ```

### S6 — HUD y feedback
- **Objetivo:** pantalla roja de daño, temporizador, indicador de cargador, confirmación de rescate.
- **RF/RNF:** RF-05, RF-27, RF-34, RF-35, RF-36.
- **Rama:** `feature/hud-mision`.
- **Commits ejemplo:**
  ```
  feat: teñir la pantalla de rojo según salud del jugador
  feat: mostrar temporizador de misión con aceleración final
  feat: mostrar indicador de cargador solo con pistola en mano
  feat: mostrar confirmación +RESCATE al estabilizar
  ```

### S7 — Escenarios y ambientación
- **Objetivo:** montar E1 Calle y E2 Edificio con props (placeholders donde falten), iluminación por zona.
- **RF/RNF:** soporte a RF-09, RF-11 · RNF-01, RNF-02.
- **Rama:** `feature/escenarios`.
- **Commits ejemplo:**
  ```
  feat: montar escenario E1 calle con props placeholder
  feat: montar escenario E2 edificio con baja visibilidad
  feat: configurar iluminación de focos de emergencia por zona
  docs: registrar props faltantes en Elementos_Faltantes
  ```

### S8 — Audio
- **Objetivo:** audio espacial 3D de enemigos/entorno, música por estado, SFX.
- **RF/RNF:** RF-33, RF-45, RF-46, RF-47 · RNF-15, RNF-16.
- **Rama:** `feature/audio`.
- **Commits ejemplo:**
  ```
  feat: configurar AudioListener3D y audio espacial de enemigos
  feat: cambiar música según estado (menú/combate/crítico)
  feat: cablear SFX de kit médico y confirmación de rescate
  chore: dejar streams de audio como placeholder pendientes de asset
  ```

### S9 — Menús y UI
- **Objetivo:** menú principal (ya iniciado), opciones, estado inicial, pausa.
- **RF/RNF:** RF-37..RF-40 · RNF-05, RNF-17.
- **Rama:** `feature/menus-ui`.
- **Commits ejemplo:**
  ```
  feat: implementar menú de opciones con audio, gráficos, controles y accesibilidad
  feat: implementar menú de pausa flotante con mapa táctico
  feat: agregar pantalla de estado inicial como transición narrativa
  ```

### S10 — Game loop y puntuación
- **Objetivo:** despliegue inicial, conteo de tiempo diferenciado, condiciones de fin, puntuación y pantalla de resultados.
- **RF/RNF:** RF-16, RF-32, RF-41..RF-44.
- **Rama:** `feature/game-loop`.
- **Commits ejemplo:**
  ```
  feat: contabilizar tiempo diferenciado frente a herido y por distancia
  feat: terminar misión por tiempo agotado o jugador eliminado
  feat: calcular puntuación por rescates y mostrar resultados
  ```

### S11 — Pulido, balanceo y rendimiento
- **Objetivo:** ajuste fino de tiempos/umbrales, confort VR, optimización a 90+ FPS, accesibilidad.
- **RF/RNF:** verificación de RNF-01..RNF-06.
- **Rama:** `feature/pulido`.
- **Commits ejemplo:**
  ```
  perf: reducir draw calls en escenario E2 para sostener 90 fps
  fix: ajustar intensidad de teletransporte para confort VR
  chore: parametrizar tiempos de decaimiento de heridos con export
  ```

## 4. Tabla resumen de sprints

| Sprint | Nombre | Rama | RF principales |
|---|---|---|---|
| S0 | Demo IA enemigos ✅ | `feature/ia-enemigos-demo` | RF-29..RF-32 |
| S1 | Núcleo VR | `feature/vr-core` | RF-01..RF-04 |
| S2 | Navegación | `feature/mapa-navegacion` | RF-06..RF-10 |
| S3 | Kit médico | `feature/kit-medico` | RF-17..RF-24 |
| S4 | Heridos | `feature/sistema-heridos` | RF-11..RF-16 |
| S5 | Combate | `feature/combate-pistola` | RF-25..RF-30 |
| S6 | HUD | `feature/hud-mision` | RF-05,27,34,35,36 |
| S7 | Escenarios | `feature/escenarios` | RF-09, RF-11 |
| S8 | Audio | `feature/audio` | RF-33,45,46,47 |
| S9 | Menús | `feature/menus-ui` | RF-37..RF-40 |
| S10 | Game loop | `feature/game-loop` | RF-41..RF-44 |
| S11 | Pulido | `feature/pulido` | RNF-01..RNF-06 |

## 5. Checklist de cierre de sprint (para Claude Code)
Al terminar cada sprint, antes de devolver el control:
- [ ] Funcionalidades del sprint implementadas y probadas.
- [ ] `Elementos_Faltantes.md` actualizado con placeholders nuevos/pendientes.
- [ ] `git add` de los archivos correctos ejecutado.
- [ ] Mensaje(s) de commit semántico entregados / commit realizado (sin push).
- [ ] Rama `feature/<sprint>` seleccionada y comunicada al encargado.
- [ ] Resumen breve de lo hecho y lo que sigue.
