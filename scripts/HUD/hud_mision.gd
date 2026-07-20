extends Node3D
## HUD diegetico de la mision (RF-36: minimo y discreto), en 3D porque los
## CanvasLayer/Control no se renderizan en el headset con use_xr (solo en la
## ventana espejo de escritorio) - ver pantalla_dano.gd.
##
## - Temporizador (RF-34): reloj Label3D en la muneca izquierda (junto al
##   mapa, diegetico como pide el pilar 2 de Contexto.md); parpadea en rojo
##   en el ultimo minuto (umbral_urgencia). El tiempo en si lo lleva
##   GestorJuego (S10, fuente unica de verdad); este script solo escucha
##   tiempo_actualizado y refleja el valor.
## - Confirmacion de rescate (RF-35): "+RESCATE" Label3D breve frente a la
##   vista; el sonido lo cubre Herido/SonidoRescate (S4), espacial en el
##   punto de rescate.

@export var umbral_urgencia: float = 60.0 # ultimo minuto: parpadeo rojo

# Este nodo es hijo de XROrigin3D/Camera3D; el reloj vive en la muneca.
@onready var etiqueta_temporizador: Label3D = get_node("../../ManoIzquierda/RelojMuneca")
@onready var etiqueta_rescate: Label3D = $EtiquetaRescate

func _ready() -> void:
	EventBus.herido_estabilizado.connect(_al_estabilizar_herido)
	GestorJuego.tiempo_actualizado.connect(_actualizar_temporizador)
	_actualizar_temporizador(GestorJuego.tiempo_restante)

func _actualizar_temporizador(segundos_restantes: float) -> void:
	if not etiqueta_temporizador:
		return
	var minutos := int(segundos_restantes) / 60
	var segundos := int(segundos_restantes) % 60
	etiqueta_temporizador.text = "%02d:%02d" % [minutos, segundos]
	if segundos_restantes <= umbral_urgencia:
		var parpadeo := 0.5 + sin(Time.get_ticks_msec() / 100.0) * 0.5
		etiqueta_temporizador.modulate = Color.WHITE.lerp(Color(1.0, 0.2, 0.2), parpadeo)
	else:
		etiqueta_temporizador.modulate = Color.WHITE

func _al_estabilizar_herido(_herido: Node) -> void:
	if not etiqueta_rescate:
		return
	etiqueta_rescate.visible = true
	get_tree().create_timer(1.0).timeout.connect(func(): etiqueta_rescate.visible = false)
