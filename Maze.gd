extends Node2D

const N = 1
const E = 2
const S = 4
const W = 8

onready var Map = $TileMap

var cell_walls = {
	Vector2.UP : N, Vector2.RIGHT : E,
	Vector2.DOWN : S, Vector2.LEFT : W
}



var erase_fraction = 1

var tile_size = 64
var width = 20
var height = 12

var map_seed = 0


func _ready():
	$Camera2D.zoom = Vector2(1,1)
	$Camera2D.position = Map.map_to_world(Vector2(width/2, height/2))
	#OS.set_window_size(Vector2((width * tile_size), (height * tile_size)))
	randomize()
	if !map_seed:
		map_seed = randi()
	seed(map_seed)
	print("Seed: ", map_seed)
	tile_size = Map.cell_size
	make_maze()
	

export var zoom = 0.1


signal continue_signal


var scroll_dir = {
	'scroll_up' : Vector2(-zoom, -zoom),
	'scroll_down' : Vector2(zoom, zoom)
}

var modifier = 1

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		emit_signal("continue_signal")
	
	if event.is_action_pressed("modifier"):
		modifier = 5
	elif event.is_action_released("modifier"):
		modifier = 1
		
		
	for dir in scroll_dir.keys():
		if event.is_action_pressed(dir):
			print(modifier)
			zoom(scroll_dir[dir] * modifier)




func zoom(dir):
	$Camera2D.zoom += dir


func check_neighbors(cell, unvisited): # Cell is the current cell, unvisited is a list of all unvisited cells.
	var list = []
	for n in cell_walls.keys():
		if cell + n in unvisited: # If the current cell + a vector in any cardinal direction is unvisited.
			list.append(cell + n) # Add the unvisited, adjacent cell to the list.
	return list


func make_maze():
	var unvisited = []
	var stack = []
	# Fill the map with solid tiles
	Map.clear()
	for x in range(width):
		for y in range (height):
			unvisited.append(Vector2(x,y))
			Map.set_cellv(Vector2(x,y), N|E|S|W) # Makes all the Cells blank, equal to tile 15
	var current = Vector2.ZERO
	unvisited.erase(current)
	
	# Al gore rythm (Recursive backtracker)
	while unvisited:
		yield(self, "continue_signal")
		var neighbors = check_neighbors(current, unvisited) # Gets all unvisited neighbors.
		if neighbors.size() > 0: # If there is an unvisited neighbour.
			var next = neighbors[randi() % neighbors.size()] # Randomly choose one of the potential neighbours.
			stack.append(current) # Add the current cell to the stack.
			var dir = next - current # Finds the direction of the selected neighbour.
			var current_walls = Map.get_cellv(current) - cell_walls[dir] # Makes current_walls equal to the current cell minus the direction AKA the new cell.
			var next_walls = Map.get_cellv(next) - cell_walls[-dir]
			Map.set_cellv(current, current_walls)
			Map.set_cellv(next, next_walls)
			current = next
			unvisited.erase(current)
		elif stack:
			current = stack.pop_back()
		#yield(get_tree(), 'idle_frame')
		
		
		#yield(self, "continue_signal")
	yield(self, "continue_signal")
	erase_walls()
	
func erase_walls():
	for i in range(int(width * height * erase_fraction)):
		var x = int(rand_range(1, width-1))
		var y = int(rand_range(1, height-1))
		var cell = Vector2(x, y)
		
		var neighbor = cell_walls.keys()[randi() % cell_walls.size()]
		
		if Map.get_cellv(cell) & cell_walls[neighbor]:
			var walls = Map.get_cellv(cell) - cell_walls[neighbor]
			var n_walls = Map.get_cellv(cell + neighbor) - cell_walls[-neighbor]
			Map.set_cellv(cell, walls)
			Map.set_cellv(cell + neighbor, n_walls)
		yield(self, "continue_signal")


