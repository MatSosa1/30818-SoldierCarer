extends XRController3D
## Gestos de mano VR (RF-04). La posicion/rotacion ya la replica el tracking
## nativo de XRController3D; este script solo agrega feedback visual de
## agarre (abierta/cerrada) sobre la malla placeholder.
##
## PLACEHOLDER: sin modelo de mano ni animaciones (PH-001). El feedback de
## agarre se simula tinendo la malla en vez de animar dedos. Reemplazar la
## malla PH_Mano por el rig de manos final sin tocar este script (mismo
## nombre de nodo hijo).

@export var color_mano_abierta: Color = Color(0.75, 0.65, 0.55)
@export var color_mano_cerrada: Color = Color(0.55, 0.45, 0.35)

@onready var malla_mano: MeshInstance3D = $PH_Mano

func _process(_delta: float) -> void:
	if not malla_mano:
		return
	var agarre := get_float("grip")
	var material := malla_mano.get_surface_override_material(0)
	if material is StandardMaterial3D:
		material.albedo_color = color_mano_abierta.lerp(color_mano_cerrada, agarre)
