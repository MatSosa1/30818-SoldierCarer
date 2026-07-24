# Controles — SoldierCarer

Referencia de controles e interacciones del juego, tanto en VR (headset OpenXR) como en el modo de escritorio (fallback sin headset). El modo se detecta solo al arrancar la misión (`jugador.gd._inicializar_openxr()`): si `XRServer` encuentra un runtime OpenXR inicializado, se juega en VR; si no, se activa el modo escritorio automáticamente, sin que haya que elegir nada a mano.

> El **menú principal** (`main_menu.tscn`) todavía es mouse-only en ambos modos: los botones 3D (Play/Opciones/Salir) se seleccionan con clic, no hay apuntado con el controlador VR todavía (ver `Planificacion_Sprints.md`).

## 1. Menú principal

| Acción | Control |
|---|---|
| Seleccionar Play / Opciones / Salir | Clic izquierdo sobre la sticky note (cursor visible) |
| Volver desde Opciones | Clic izquierdo sobre "VOLVER" |

## 2. VR (headset OpenXR)

El jugador está **fijo en posición** (RF-03): nunca camina, solo gira la cabeza y se desplaza por teletransporte. La mano derecha dispara y confirma; la mano izquierda abre kit/mapa y recarga.

| Acción | Control |
|---|---|
| Mirar alrededor | Rotación real de la cabeza (tracking del headset) |
| Disparar pistola | Gatillo derecho (`trigger_click`), pistola desenfundada y con balas |
| Desenfundar / enfundar pistola | Acercar la mano derecha a la cadera (`PuntoFunda`) |
| Recargar pistola | Botón X/A de la mano izquierda (`ax_button`), pistola en mano |
| Abrir mapa de muñeca | Levantar la mano izquierda por encima del hombro |
| Seleccionar destino en el mapa / confirmar | Acercar la mano derecha al ícono + gatillo derecho |
| Abrir kit médico | Acercar la mano izquierda a la mochila (cadera) |
| Seleccionar ítem del kit | Acercar la mano derecha al ítem + gatillo derecho |
| Aplicar vendas | Movimiento circular de la mano derecha alrededor de la herida (320°) |
| Aplicar alcohol | Inclinar la mano derecha (mano "boca abajo") y sostener 0.4s |
| Aplicar suturas | Apretar y soltar el grip derecho 3 veces seguidas |
| Aplicar morfina / analgésicos | Acercar la mano derecha al herido + gatillo derecho |
| Alivio rápido (dolor bloqueando el tratamiento) | La morfina del kit pulsa sola: acercarse y gatillo, sin leer las 5 etiquetas |
| Guardar ítem equipado sin aplicar | Gatillo derecho (con un ítem de secuencia en mano, sin herida válida en rango) |
| Abrir/cerrar menú de pausa | Botón de menú de la mano izquierda (`menu_button`) |
| Seleccionar opción del menú de pausa | Acercar la mano derecha al ícono (Reanudar/Opciones/Salir) + gatillo |
| Seleccionar punto de despliegue (puesto de mando) | Acercar la mano derecha al ícono E1/E2 + gatillo |
| Confirmar pantalla de resultados | Acercar la mano derecha a "VOLVER AL MENÚ" + gatillo |

## 3. Escritorio (sin headset)

Se activa solo si no hay runtime OpenXR disponible. El jugador sigue sin trasladarse (mismo RF-03): el mouse reemplaza el tracking de cabeza, y varias interacciones que en VR dependen de la posición de la mano se resuelven con teclas dedicadas porque no hay forma de rastrear una mano real.

| Acción | Control |
|---|---|
| Mirar alrededor | Mover el mouse (mouse capturado; yaw + pitch) |
| Disparar pistola | Clic izquierdo (apunta exactamente donde está la mira central) |
| Recargar pistola | `R` |
| Abrir/cerrar mapa de muñeca | `M` |
| Ciclar destino resaltado en el mapa | Rueda del mouse / `Tab` (`Shift+Tab` para atrás) |
| Confirmar destino resaltado | Clic izquierdo |
| Abrir/cerrar kit médico | `E` |
| Elegir sobre qué herida trabajar | Mirarla (mira central) **antes** de elegir el ítem — ver notas |
| Seleccionar ítem del kit | `1` Vendas · `2` Morfina · `3` Alcohol · `4` Suturas · `5` Analgésicos |
| Aplicar vendas (equipadas) | Mover el mouse (acumula progreso, no hace falta mantener ningún botón) |
| Aplicar alcohol (equipado) | Mantener clic derecho ~0.4s |
| Aplicar suturas (equipadas) | Clic derecho 3 veces seguidas |
| Aplicar morfina / analgésicos (equipados) | Clic izquierdo, con la mira sobre un herido cercano |
| Alivio rápido (inyectar morfina sin equipar nada) | `Q`, con un herido cerca — guarda lo que tengas en mano si hace falta |
| Guardar ítem equipado sin aplicar | Clic izquierdo (con un ítem de secuencia en mano, sin herida válida) |
| Abrir/cerrar menú de pausa | `ESC` (también libera/recaptura el mouse) |
| Ciclar opción resaltada del menú de pausa | Rueda del mouse / `Tab` (`Shift+Tab` para atrás) |
| Confirmar opción resaltada del menú de pausa | Clic izquierdo |
| Seleccionar punto de despliegue (puesto de mando) | Mirar el ícono E1/E2 (mira central) + clic izquierdo |
| Confirmar pantalla de resultados | Clic izquierdo (con demora mínima de 0.5s desde que aparece la pantalla) |

### Notas del modo escritorio

- La mira central (`UI/Mira` en `Jugador.tscn`) solo se muestra sin headset; en VR se apunta con la mano/controlador, no tiene equivalente de pantalla.
- El clic izquierdo es un único "gatillo" contextual (`jugador.gd._al_presionar_boton_mano`): dispara si no hay ningún panel abierto, o confirma el panel visible con más prioridad (resultados > pausa > despliegue > mapa > kit), igual que el gatillo derecho en VR.
- El clic derecho es el "gesto secundario" que sustituye a los gestos físicos de alcohol/suturas (inclinar la mano, apretar el grip) que no tienen forma de replicarse sin una mano rastreada.
- La pistola queda desenfundada de forma permanente en modo escritorio (el gesto de extraerla de la cadera no tiene equivalente sin manos).
- **Con un ítem del kit equipado, la vista deja de rotar con el mouse** hasta que se guarda o se aplica: el mismo movimiento del mouse es el gesto de vendas, así que si además rotara la cámara el jugador terminaba girando sin control mientras vendaba. Por eso hay que **mirar la herida que se quiere tratar antes de presionar el número del ítem**, no después — una vez equipado, la herida objetivo queda fijada a donde estaba apuntando la mira en ese momento.
- La herida objetivo se elige por la mira (la más centrada bajo el reticulo, con una tolerancia si ninguna está bien centrada), no por cercanía a un punto fijo: con 2+ heridas por herido (mínimo actual), esto es lo que permite elegir cuál tratar primero en vez de que el juego siempre eligiera la geométricamente más próxima a una mano fantasma.
- `Q` es un atajo, no reemplaza al kit: sigue existiendo el flujo normal (`2` para equipar morfina y confirmar con clic) si preferís usarlo. `Q` funciona tenga el kit abierto o no.
