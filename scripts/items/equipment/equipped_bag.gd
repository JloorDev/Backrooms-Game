class_name EquippedBag
extends RefCounted

# EquipmentData (el .tres) es solo la "receta" de una mochila -- cuánto
# pesa, cuánto le cabe, etc. Esto de acá es la mochila REAL que traes
# puesta en una partida: tiene su propia grilla con lo que le metiste
# adentro. Por eso se crea una nueva en cada _init() en vez de guardarla
# en el .tres -- si no, todas las mochilas del mismo tipo compartirían
# el mismo contenido, cosa que obviamente no queremos.
# - JloorDev

var data: EquipmentData
var grid: ItemGrid

func _init(bag_data: EquipmentData) -> void:
	data = bag_data
	grid = ItemGrid.new(bag_data.internal_grid_width, bag_data.internal_grid_height, bag_data.internal_max_weight)

## El peso que esta mochila le suma al jugador: su propio peso completo,
## más solo una fracción (external_weight_multiplier) del peso de lo que
## lleva adentro -- esa es la ventaja de usar una mochila en vez de cargar
## todo suelto en el cuerpo. El límite interno (grid.max_weight) sigue
## usando el peso completo, sin descuento: eso es "cuánto le cabe", no
## "cuánto se nota afuera".
func get_total_weight() -> float:
	return data.weight + grid.get_current_weight() * data.external_weight_multiplier
