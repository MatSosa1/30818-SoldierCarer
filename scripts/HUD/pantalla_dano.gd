extends MeshInstance3D
class_name PantallaDano
## RF-05: comunica dano/salud critica tinendo la vista de rojo, sin barra
## numerica. Es un quad 3D frente a la XRCamera3D (no un ColorRect en
## CanvasLayer): en Godot 4 con use_xr los nodos 2D NO se renderizan en el
## headset, solo en la ventana espejo de escritorio, asi que el tinte tiene
## que vivir en el mundo 3D para verse en VR.
##
## PLACEHOLDER: tinte uniforme; un vignette radial real (mas comodo en VR,
## oscurece solo los bordes) requiere una textura de gradiente (PH-018).

@export var alpha_maximo: float = 0.5
@export var incremento_por_golpe: float = 0.25
@export var duracion_desvanecido: float = 0.6

func mostrar_dano() -> void:
	var material := material_override as StandardMaterial3D
	if not material:
		return
	material.albedo_color.a = min(material.albedo_color.a + incremento_por_golpe, alpha_maximo)
	var tween := create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, duracion_desvanecido)
