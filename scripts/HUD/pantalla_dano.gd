extends ColorRect
class_name PantallaDano
## RF-05: comunica dano/salud critica tinendo la pantalla de rojo, sin barra
## numerica. Se adjunta directamente al ColorRect de pantalla completa
## (UI/PantallaDanio en Jugador.tscn); jugador.gd solo llama mostrar_dano().

@export var alpha_maximo: float = 0.6
@export var incremento_por_golpe: float = 0.25
@export var duracion_desvanecido: float = 0.6

func mostrar_dano() -> void:
	color.a = min(color.a + incremento_por_golpe, alpha_maximo)
	var tween := create_tween()
	tween.tween_property(self, "color:a", 0.0, duracion_desvanecido)
