extends Area3D
## Control de volumen del menu de opciones (RF-38): mismo patron Area3D +
## clic izquierdo que btn_play/btn_options/btn_exit (ver CLAUDE.md), pero en
## vez de abrir/cerrar un panel, cicla el volumen del bus asociado en pasos
## de 10% (GestorOpciones.ciclar_volumen_*, wrap 100% -> 0%).
##
## Las tres filas viven sobre la hoja de la carpeta (folder/
## Contenedor_Opciones), bajo el titulo "AUDIO" y encima de "Volver". La hoja
## se recorre en +X (derecha) y -Z (arriba); +Y es su normal. Un apilado en Y
## -como estaba- dejaba las tres filas una detras de otra y fuera de la hoja.
## Reemplazan al Sprite3D "Opciones_extra", que solo dibujaba la lista de
## categorias AUDIO/GRAFICOS/CONTROLES/ACCESIBILIDAD sin nada detras (PH-015).

enum Canal {MASTER, MUSICA, SFX}

@export var canal: Canal = Canal.MASTER

@onready var etiqueta_valor: Label3D = $EtiquetaValor

func _ready() -> void:
	input_event.connect(_al_recibir_input)
	_actualizar_etiqueta()

func _al_recibir_input(
	_camara: Node, evento: InputEvent, _posicion: Vector3, _normal: Vector3, _indice_forma: int
) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
		match canal:
			Canal.MASTER:
				GestorOpciones.ciclar_volumen_master()
			Canal.MUSICA:
				GestorOpciones.ciclar_volumen_musica()
			Canal.SFX:
				GestorOpciones.ciclar_volumen_sfx()
		_actualizar_etiqueta()

func _actualizar_etiqueta() -> void:
	if not etiqueta_valor:
		return
	match canal:
		Canal.MASTER:
			etiqueta_valor.text = "General: %s" % GestorOpciones.porcentaje_volumen_master()
		Canal.MUSICA:
			etiqueta_valor.text = "Musica: %s" % GestorOpciones.porcentaje_volumen_musica()
		Canal.SFX:
			etiqueta_valor.text = "Efectos: %s" % GestorOpciones.porcentaje_volumen_sfx()
