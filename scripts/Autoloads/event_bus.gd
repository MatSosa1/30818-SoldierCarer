extends Node
## Bus de senales global para desacoplar sistemas (Arquitectura.md SS4).
## S2 solo agrega el contrato de teletransporte/escenario, que es el que
## tiene consumidores reales en este sprint (MapaMuneca emite,
## GestorEscenarios escucha). El resto de senales documentadas
## (herido_muerto, herido_estabilizado, mision_terminada) se agregan en los
## sprints que las implementen (S4/S10) para no declarar contratos sin uso.

signal solicitar_teletransporte(punto_destino: Vector3, escenario: String)
signal escenario_activado(escenario: String)
