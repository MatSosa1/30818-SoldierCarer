extends Node
## Bus de senales global para desacoplar sistemas (Arquitectura.md SS4).
## Cada senal se agrega en el sprint que le da un consumidor real, para no
## declarar contratos sin uso: S2 sumo teletransporte/escenario; S4 suma
## herido_estabilizado (RF-16, consumida por jugador.gd para el "+RESCATE").
## herido_muerto y mision_terminada quedan para cuando S4/S10 las necesiten.

signal solicitar_teletransporte(punto_destino: Vector3, escenario: String)
signal escenario_activado(escenario: String)
signal herido_estabilizado(herido: Node)
# Emitida por GestorJuego al confirmar el punto de despliegue en el mapa del
# puesto de mando (RF-39/RF-08): arranca el reloj de mision y arma al
# DirectorDeOleadas del escenario elegido.
signal mision_desplegada(escenario: String)
# Emitida por el herido cada vez que un paso de tratamiento se completa
# (fraccion = pasos completados / pasos totales). El DirectorDeOleadas la usa
# para escalar las oleadas: curar hace ruido y atrae a la Oposicion (RF-31).
signal tratamiento_progresado(herido: Node, fraccion: float)
