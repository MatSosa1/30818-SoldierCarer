extends Control
## HUD no diegetico de la mision (RF-36: minimo y discreto).
## - Temporizador (RF-34): cuenta regresiva en la esquina superior derecha;
##   parpadea en rojo en el ultimo minuto (umbral_urgencia).
## - Confirmacion de rescate (RF-35): "+RESCATE" breve al centro; el sonido
##   ya lo cubre Herido/SonidoRescate (S4), espacial en el punto de rescate.
##
## RF-43 (fin de mision por tiempo agotado) es responsabilidad de S10 /
## GestorJuego, que todavia no existe; aqui el temporizador solo se detiene
## visualmente en 0.

@export var duracion_mision: float = 600.0 # 10 min; D1 (Contexto.md SS8) pendiente de confirmar valor final
@export var umbral_urgencia: float = 60.0 # ultimo minuto: parpadeo rojo

@onready var etiqueta_temporizador: Label = $EtiquetaTemporizador
@onready var etiqueta_rescate: Label = $EtiquetaRescate

var _tiempo_restante: float
var _tiempo_agotado: bool = false

func _ready() -> void:
	_tiempo_restante = duracion_mision
	EventBus.herido_estabilizado.connect(_al_estabilizar_herido)
	_actualizar_temporizador()

func _process(delta: float) -> void:
	if _tiempo_agotado:
		return
	_tiempo_restante = max(_tiempo_restante - delta, 0.0)
	_actualizar_temporizador()
	if _tiempo_restante <= 0.0:
		_tiempo_agotado = true
		etiqueta_temporizador.text = "TIEMPO AGOTADO"
		etiqueta_temporizador.modulate = Color(1.0, 0.3, 0.3)

func _actualizar_temporizador() -> void:
	var minutos := int(_tiempo_restante) / 60
	var segundos := int(_tiempo_restante) % 60
	etiqueta_temporizador.text = "%02d:%02d" % [minutos, segundos]
	if _tiempo_restante <= umbral_urgencia:
		var parpadeo := 0.5 + sin(Time.get_ticks_msec() / 100.0) * 0.5
		etiqueta_temporizador.modulate = Color.WHITE.lerp(Color(1.0, 0.2, 0.2), parpadeo)
	else:
		etiqueta_temporizador.modulate = Color.WHITE

func _al_estabilizar_herido(_herido: Node) -> void:
	etiqueta_rescate.visible = true
	get_tree().create_timer(1.0).timeout.connect(func(): etiqueta_rescate.visible = false)
