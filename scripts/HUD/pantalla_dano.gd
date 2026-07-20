extends MeshInstance3D
class_name PantallaDano
## RF-05: comunica dano/salud tinendo la vista de rojo, sin barra numerica —
## la salud es 100% diegetica (estilo Uncharted). Dos componentes sumados:
## - Flash por golpe: sube al recibir dano y se desvanece solo.
## - Tinte persistente: presente mientras la salud esta bajo umbral_critico,
##   proporcional a que tan baja esta; se limpia solo conforme la salud se
##   regenera (jugador.gd actualiza fraccion_salud).
## Es un quad 3D frente a la XRCamera3D (no un ColorRect en CanvasLayer): en
## Godot 4 con use_xr los nodos 2D NO se renderizan en el headset.
##
## PLACEHOLDER: tinte uniforme; un vignette radial real (mas comodo en VR,
## oscurece solo los bordes) requiere una textura de gradiente (PH-018).

@export var alpha_maximo: float = 0.5
@export var incremento_por_golpe: float = 0.25
@export var duracion_desvanecido: float = 0.6
# Tinte persistente maximo (salud casi a cero) y fraccion de salud bajo la
# cual empieza a notarse.
@export var alpha_critico: float = 0.4
@export var umbral_critico: float = 0.35

# Actualizada por jugador.gd al recibir dano y al regenerar (0..1).
var fraccion_salud: float = 1.0

var _flash: float = 0.0

func mostrar_dano() -> void:
	_flash = min(_flash + incremento_por_golpe, alpha_maximo)

func _process(delta: float) -> void:
	var material := material_override as StandardMaterial3D
	if not material:
		return
	if _flash > 0.0:
		_flash = max(_flash - (alpha_maximo / duracion_desvanecido) * delta, 0.0)
	var persistente := 0.0
	if fraccion_salud < umbral_critico:
		persistente = alpha_critico * (1.0 - fraccion_salud / umbral_critico)
	material.albedo_color.a = clampf(persistente + _flash, 0.0, 0.65)
