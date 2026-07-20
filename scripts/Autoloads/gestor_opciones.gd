extends Node
## Ajustes de accesibilidad/confort VR (RNF-05) y audio general, expuestos
## en el menu de opciones (RF-38). No estaba en la lista original de
## autoloads de Arquitectura.md (solo EventBus/GestorJuego/GestorAudio),
## pero sin el no hay forma de que "Accesibilidad: intensidad de
## teletransporte" tenga un efecto real, no solo un rotulo en un menu.
##
## Grafico/Controles (RF-38) no tienen aqui ningun ajuste todavia: no existe
## un sistema de calidad grafica ni de rebinding de controles que configurar
## (ver Elementos_Faltantes.md).

enum IntensidadTeletransporte {INSTANTANEO, DESVANECIDO_SUAVE, DESVANECIDO_FUERTE}

@export var intensidad_teletransporte: IntensidadTeletransporte = IntensidadTeletransporte.DESVANECIDO_SUAVE

@export var volumen_master: float = 1.0:
	set(valor):
		volumen_master = clamp(valor, 0.0, 1.0)
		var bus := AudioServer.get_bus_index("Master")
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, linear_to_db(max(volumen_master, 0.001)))

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
