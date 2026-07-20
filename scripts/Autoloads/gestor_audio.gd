extends Node
## Musica por estado (RF-46): menu (calma), combate (tension media), critico
## (intenso). Los SFX puntuales (kit, heridos, disparos, pasos) usan su
## propio AudioStreamPlayer3D cableado localmente en cada escena -tienen
## posicion 3D propia, no tiene sentido centralizarlos aqui-; GestorAudio
## solo centraliza la musica de fondo, que es unica y global por naturaleza.
##
## PLACEHOLDER: los tres streams quedan sin asignar (PH-012, musica original
## del equipo pendiente). cambiar_estado() sigue funcionando sin ellos (no
## suena nada hasta que se asignen los @export, sin errores).

enum EstadoMusica {MENU, COMBATE, CRITICO}

@export var musica_menu: AudioStream
@export var musica_combate: AudioStream
@export var musica_critico: AudioStream

var estado_actual: EstadoMusica = EstadoMusica.MENU

@onready var reproductor: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(reproductor)

func cambiar_estado(nuevo: EstadoMusica) -> void:
	if nuevo == estado_actual and reproductor.playing:
		return
	estado_actual = nuevo
	var stream: AudioStream = {
		EstadoMusica.MENU: musica_menu,
		EstadoMusica.COMBATE: musica_combate,
		EstadoMusica.CRITICO: musica_critico,
	}.get(nuevo)
	reproductor.stream = stream
	if stream:
		reproductor.play()
	else:
		reproductor.stop()
		print("GestorAudio: sin stream para %s (PH-012, pendiente musica original)" % EstadoMusica.keys()[nuevo])
