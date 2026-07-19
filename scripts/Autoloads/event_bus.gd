extends Node
## Bus de senales global para desacoplar sistemas (Arquitectura.md SS4).
## Cada senal se agrega en el sprint que le da un consumidor real, para no
## declarar contratos sin uso: S2 sumo teletransporte/escenario; S4 suma
## herido_estabilizado (RF-16, consumida por jugador.gd para el "+RESCATE").
## herido_muerto y mision_terminada quedan para cuando S4/S10 las necesiten.

signal solicitar_teletransporte(punto_destino: Vector3, escenario: String)
signal escenario_activado(escenario: String)
signal herido_estabilizado(herido: Node)
