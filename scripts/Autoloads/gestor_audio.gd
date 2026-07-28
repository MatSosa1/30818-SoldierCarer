extends Node
## Musica por estado (RF-46): menu (calma), combate (tension media), critico
## (intenso). Los SFX puntuales (kit, heridos, disparos, pasos) usan su
## propio AudioStreamPlayer3D cableado localmente en cada escena -tienen
## posicion 3D propia, no tiene sentido centralizarlos aqui-; GestorAudio
## solo centraliza la musica de fondo, que es unica y global por naturaleza.
##
## PH-012 (tracks en audio/, no assets/ - carpeta aparte agregada por el
## encargado), asignados como default en el propio script (GestorAudio se
## registra en project.godot como .gd suelto, no .tscn, asi que no hay
## Inspector donde arrastrarlos). MENU cubre tanto el menu principal como
## el puesto de mando/instrucciones (jugador.gd solo cambia a COMBATE al
## confirmar el despliegue - ver EventBus.mision_desplegada); COMBATE y
## CRITICO sueltan el mismo ambiente de guerra ya que ambos son "en mision",
## solo cambia la intensidad narrativa (RF-46 dejo la distincion para si se
## consigue un track especifico de tension alta).
enum EstadoMusica {MENU, COMBATE, CRITICO}

const MUSICA_MENU := preload("res://audio/GHOST FREQ-0  1H Tactical Stealth Music - Reaction Window.mp3")
const MUSICA_MISION := preload("res://audio/Call of Duty_ WARZONE AMBIENCE  Background Noise (Relaxing Call of Duty Ambient Sounds).mp3")

@export var musica_menu: AudioStream = MUSICA_MENU
@export var musica_combate: AudioStream = MUSICA_MISION
@export var musica_critico: AudioStream = MUSICA_MISION

var estado_actual: EstadoMusica = EstadoMusica.MENU

@onready var reproductor: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	# Bus "Musica" (default_bus_layout.tres): permite mezclar musica de fondo
	# por separado de los SFX (RF-38, ajuste de volumen en Opciones).
	reproductor.bus = "Musica"
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
