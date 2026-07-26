extends XRController3D
## Gestos de mano VR (RF-04). La posicion/rotacion ya la replica el tracking
## nativo de XRController3D; este script solo agrega feedback visual de
## agarre (abierta/cerrada) sobre la malla de la mano.
##
## PH-001 resuelto: nodo hijo "Mano" es ahora una instancia de
## assets/3D/entities/medic/HandRig.tscn (rig extraido de Hands.blend, con
## Skeleton3D). Sin animaciones de dedos todavia (falta rig de gestos): el
## feedback de agarre se sigue simulando tinendo el material de la malla.
## Transform/escala de "Mano"/"Manga" en Jugador.tscn son un primer ajuste
## aproximado (el .blend fuente no viene en escala real) - falta pulido
## visual en el editor.

@export var color_mano_abierta: Color = Color(0.75, 0.65, 0.55)
@export var color_mano_cerrada: Color = Color(0.55, 0.45, 0.35)

@onready var malla_mano: MeshInstance3D = _buscar_malla_mano()

func _buscar_malla_mano() -> MeshInstance3D:
	var rig := get_node_or_null("Mano")
	if not rig:
		return null
	if rig is MeshInstance3D:
		return rig as MeshInstance3D
	for hijo in rig.find_children("*", "MeshInstance3D", true, false):
		return hijo as MeshInstance3D
	return null

func _process(_delta: float) -> void:
	if not malla_mano:
		return
	if not malla_mano.get_surface_override_material(0):
		var base := malla_mano.mesh.surface_get_material(0)
		malla_mano.set_surface_override_material(0, base.duplicate() if base else StandardMaterial3D.new())
	var agarre := get_float("grip")
	var material := malla_mano.get_surface_override_material(0)
	if material is StandardMaterial3D:
		material.albedo_color = color_mano_abierta.lerp(color_mano_cerrada, agarre)
