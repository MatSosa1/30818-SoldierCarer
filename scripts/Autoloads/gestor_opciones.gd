extends Node
## Ajustes de accesibilidad/confort VR (RNF-05) y audio general, expuestos
## en el menu de opciones (RF-38: menu principal y menu de pausa). No estaba
## en la lista original de autoloads de Arquitectura.md (solo
## EventBus/GestorJuego/GestorAudio), pero sin el no hay forma de que
## "Accesibilidad: intensidad de teletransporte" ni el volumen tengan un
## efecto real, no solo un rotulo en un menu.
##
## Volumen en 3 buses independientes (Master/Musica/SFX, ver
## default_bus_layout.tres) para poder bajar musica o efectos sin tocar el
## general. Se persiste en user://opciones.cfg (ConfigFile) para que el
## ajuste sobreviva a cerrar el juego.
##
## Grafico/Controles (RF-38) no tienen aqui ningun ajuste todavia: no existe
## un sistema de calidad grafica ni de rebinding de controles que configurar
## (ver Elementos_Faltantes.md).

enum IntensidadTeletransporte {INSTANTANEO, DESVANECIDO_SUAVE, DESVANECIDO_FUERTE}

# Persistencia simple en user:// (RF-38: "a su gusto" implica que el ajuste
# sobreviva a cerrar el juego, no solo dentro de la misma sesion).
const RUTA_CONFIG := "user://opciones.cfg"

@export var intensidad_teletransporte: IntensidadTeletransporte = (
	IntensidadTeletransporte.DESVANECIDO_SUAVE
)

# Master en 1.0 (0dB, sin recorte extra); la mezcla pareja se logra bajando
# el nivel por defecto de los buses Musica/SFX (default_bus_layout.tres,
# -8dB/-6dB) en vez de tocar Master - asi el jugador todavia tiene margen
# para subir cada canal por separado desde el menu de opciones (RF-38).
@export var volumen_master: float = 1.0:
	set(valor):
		volumen_master = clamp(valor, 0.0, 1.0)
		_aplicar_volumen_bus("Master", volumen_master)

@export var volumen_musica: float = 0.8:
	set(valor):
		volumen_musica = clamp(valor, 0.0, 1.0)
		_aplicar_volumen_bus("Musica", volumen_musica)

@export var volumen_sfx: float = 0.8:
	set(valor):
		volumen_sfx = clamp(valor, 0.0, 1.0)
		_aplicar_volumen_bus("SFX", volumen_sfx)

func _aplicar_volumen_bus(nombre_bus: String, valor: float) -> void:
	var bus := AudioServer.get_bus_index(nombre_bus)
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(max(valor, 0.001)))

# Duracion del fundido a negro que oculta el "salto" del teletransporte
# (RF-08), segun la intensidad elegida. INSTANTANEO = sin fundido.
func duracion_fundido() -> float:
	match intensidad_teletransporte:
		IntensidadTeletransporte.INSTANTANEO:
			return 0.0
		IntensidadTeletransporte.DESVANECIDO_SUAVE:
			return 0.15
		IntensidadTeletransporte.DESVANECIDO_FUERTE:
			return 0.4
	return 0.0

func ciclar_intensidad_teletransporte() -> void:
	var valores := IntensidadTeletransporte.values()
	var indice := valores.find(intensidad_teletransporte)
	intensidad_teletransporte = valores[(indice + 1) % valores.size()]
	guardar()

# Nombre legible para UI (no el identificador crudo del enum).
func nombre_intensidad_actual() -> String:
	match intensidad_teletransporte:
		IntensidadTeletransporte.INSTANTANEO:
			return "Instantáneo"
		IntensidadTeletransporte.DESVANECIDO_SUAVE:
			return "Suave"
		IntensidadTeletransporte.DESVANECIDO_FUERTE:
			return "Fuerte"
	return "?"

# Pasos de 10% (wrap 100% -> 0%), mismo criterio "un click, un paso" que
# ciclar_intensidad_teletransporte(): controles de audio en menu principal
# (folder/Contenedor_Opciones) y menu de pausa (MenuPausa) llaman a estos en
# vez de tocar volumen_master/musica/sfx directo, para guardar siempre.
func ciclar_volumen_master() -> void:
	volumen_master = _siguiente_paso(volumen_master)
	guardar()

func ciclar_volumen_musica() -> void:
	volumen_musica = _siguiente_paso(volumen_musica)
	guardar()

func ciclar_volumen_sfx() -> void:
	volumen_sfx = _siguiente_paso(volumen_sfx)
	guardar()

func _siguiente_paso(valor_actual: float) -> float:
	var siguiente := snappedf(valor_actual, 0.1) + 0.1
	return 0.0 if siguiente > 1.001 else siguiente

func porcentaje_volumen_master() -> String:
	return "%d%%" % roundi(volumen_master * 100.0)

func porcentaje_volumen_musica() -> String:
	return "%d%%" % roundi(volumen_musica * 100.0)

func porcentaje_volumen_sfx() -> String:
	return "%d%%" % roundi(volumen_sfx * 100.0)

func _ready() -> void:
	_cargar()

func _cargar() -> void:
	var config := ConfigFile.new()
	if config.load(RUTA_CONFIG) != OK:
		return # sin archivo todavia (primera vez) -> se quedan los defaults
	volumen_master = config.get_value("audio", "volumen_master", volumen_master)
	volumen_musica = config.get_value("audio", "volumen_musica", volumen_musica)
	volumen_sfx = config.get_value("audio", "volumen_sfx", volumen_sfx)
	intensidad_teletransporte = config.get_value(
		"accesibilidad", "intensidad_teletransporte", intensidad_teletransporte
	)

func guardar() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volumen_master", volumen_master)
	config.set_value("audio", "volumen_musica", volumen_musica)
	config.set_value("audio", "volumen_sfx", volumen_sfx)
	config.set_value("accesibilidad", "intensidad_teletransporte", intensidad_teletransporte)
	config.save(RUTA_CONFIG)
