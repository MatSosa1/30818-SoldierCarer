extends Node
## Estado de partida: fuente unica de verdad del tiempo de mision, la
## puntuacion por rescates y la condicion de fin (RF-16, RF-41..RF-44). Era
## el unico autoload documentado en Arquitectura.md SS4 que faltaba; antes
## del temporizador vivia localmente en hud_mision.gd (S6), que ahora solo
## escucha tiempo_actualizado en vez de llevar su propio reloj.

signal tiempo_actualizado(segundos_restantes: float)
signal mision_finalizada(resultado: String, rescates: int)

@export var duracion_mision: float = 600.0 # 10 min; D1 (Contexto.md SS8) pendiente de confirmar valor final
# RF-42 "tiempo diferenciado frente a un herido": mientras el kit medico
# esta abierto (tratamiento activo) el tiempo corre mas lento - la medicina
# es el eje del juego (Contexto.md pilar 1), no se penaliza tomarse el
# tiempo de tratar bien a un herido.
@export var factor_tiempo_tratando: float = 0.5
# RF-42 "calculado por distancia al desplazarse por el mapa": costo de
# tiempo por cada metro recorrido al confirmar un teletransporte.
@export var segundos_por_metro: float = 0.3

var tiempo_restante: float
var rescates: int = 0
var mision_activa: bool = false

var _tratando: bool = false

func _ready() -> void:
	reiniciar()
	EventBus.herido_estabilizado.connect(_al_estabilizar_herido)

func reiniciar() -> void:
	tiempo_restante = duracion_mision
	rescates = 0
	mision_activa = true
	_tratando = false

func _process(delta: float) -> void:
	if not mision_activa:
		return
	var factor := factor_tiempo_tratando if _tratando else 1.0
	tiempo_restante = max(tiempo_restante - delta * factor, 0.0)
	tiempo_actualizado.emit(tiempo_restante)
	if tiempo_restante <= 0.0:
		terminar_mision("tiempo_agotado")

# Llamado por kit_medico.gd cada frame con su propia visibilidad.
func marcar_tratando(activo: bool) -> void:
	_tratando = activo

# Llamado por gestor_escenarios.gd antes de reposicionar, con la distancia
# real entre la posicion actual del jugador y el destino.
func consumir_tiempo_por_distancia(distancia: float) -> void:
	if not mision_activa:
		return
	tiempo_restante = max(tiempo_restante - distancia * segundos_por_metro, 0.0)
	tiempo_actualizado.emit(tiempo_restante)
	if tiempo_restante <= 0.0:
		terminar_mision("tiempo_agotado")

func _al_estabilizar_herido(_herido: Node) -> void:
	if mision_activa:
		rescates += 1

# RF-43: termina la mision por tiempo agotado o jugador eliminado. Pausa la
# simulacion del escenario activo (mismo mecanismo que el menu de pausa,
# S9) y avisa a quien escuche mision_finalizada (RF-44, pantalla de
# resultados) para mostrar el resumen.
func terminar_mision(resultado: String) -> void:
	if not mision_activa:
		return
	mision_activa = false
	var gestor := get_tree().get_first_node_in_group("gestor_escenarios")
	if gestor:
		gestor.pausar_activo(true)
	mision_finalizada.emit(resultado, rescates)
