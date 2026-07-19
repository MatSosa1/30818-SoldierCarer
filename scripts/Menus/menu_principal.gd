extends Node3D
## RF-46: musica de menu (calma) mientras se esta en MainMenu.tscn.

func _ready() -> void:
	GestorAudio.cambiar_estado(GestorAudio.EstadoMusica.MENU)
