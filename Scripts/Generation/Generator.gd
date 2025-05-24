extends Node3D

const LINCOLN = "res://GeoJson-Files/lincoln.geojson"
const GRASS = preload("res://Material/grass.tres")
const BUILDING = preload("res://Material/building.tres")
const PAVED_BRICK = preload("res://Material/paved_brick.tres")
const GRAVEL = preload("res://Material/gravel.tres")
const ROAD = preload("res://Material/road.tres")
const RAIL = preload("res://Material/rail.tres")

@onready var anchor: Node3D = $Anchor
signal file_loaded

func _ready() -> void:
	FileLoader.load_file(LINCOLN)
	generate_terrain()
	generate_buildings()
	generate_paths()
	generate_bridges()
	global_position = Vector3(-FileLoader.bbox[2], -5,  -FileLoader.bbox[3])
	file_loaded.emit()

func generate_paths():
	var path_total = CSGCombiner3D.new()
	var road_total = CSGCombiner3D.new()
	var rail_total = CSGCombiner3D.new()
	
	for multipoly in FileLoader.loaded_multipolys:
		if ["pedestrian", "steps", "footway"].has(multipoly.properties.highway):
			for poly in multipoly.geometry.coordinates:
				var path = CSGPolygon3D.new()
				path.polygon = poly
				path.depth = 5.01
				path.material = GRAVEL
				path_total.add_child(path)
				
	for linestring in FileLoader.loaded_lines:
		if ["pedestrian", "steps", "footway"].has(linestring.properties.highway) and linestring.properties.layer < 1:
			var poly = linestring.geometry.as_polygon(2)
			for discrete_poly in poly:
				var path = CSGPolygon3D.new()
				path.polygon = discrete_poly
				path.depth = 5.01
				path.material = GRAVEL
				path_total.add_child(path)
			continue
		if ["primary", "secondary", "tertiary", "unclassified", "service", "residential", "unclassified", "trunk"].has(linestring.properties.highway) and linestring.properties.layer < 1:
			var poly = linestring.geometry.as_polygon(2.5 * min(linestring.properties.lanes, 2))
			for discrete_poly in poly:
				var path = CSGPolygon3D.new()
				path.polygon = discrete_poly
				path.depth = 5.02
				path.material = ROAD
				road_total.add_child(path)
			continue
		if linestring.properties.railway != "-1" and linestring.properties.ref != "NOB4" and "Line" in linestring.properties.name:
			var poly = linestring.geometry.as_polygon(3)
			for discrete_poly in poly:
				var path = CSGPolygon3D.new()
				path.polygon = discrete_poly
				path.depth = 5.03
				path.material = RAIL
				rail_total.add_child(path)
			continue
		
	add_child(path_total)
	add_child(road_total)
	add_child(rail_total)

func generate_bridges():
	var ignored : Array[int] = []
	for i  in range(len(FileLoader.loaded_lines)):
		if i in ignored:
			continue
		var linestring = FileLoader.loaded_lines[i]
		
		if linestring.properties.layer >= 1:
			var complete_line : PackedVector2Array = []
			complete_line.append_array(linestring.geometry.coordinates)
			ignored.append(i)
			
			for j  in range(len(FileLoader.loaded_lines)):
				if i == j:
					continue
				var second_linestring = FileLoader.loaded_lines[j]
				if complete_line[0] == second_linestring.geometry.coordinates[-1]:
					complete_line = second_linestring.geometry.coordinates + complete_line
					ignored.append(j)
				if complete_line[-1] == second_linestring.geometry.coordinates[0]:
					complete_line =  complete_line + second_linestring.geometry.coordinates
					ignored.append(j)

func generate_buildings():
	var building_container = Node3D.new()
	
	for building in FileLoader.loaded_multipolys:
		if building.properties.building != "-1" or building.properties.building != "-1":
			for poly in building.geometry.coordinates:
				var building_csg = CSGPolygon3D.new()
				building_csg.polygon = poly
				building_csg.depth = pow(polygon_area(poly), 0.22) * 3
				building_csg.operation = CSGPolygon3D.OPERATION_SUBTRACTION
				building_csg.material = BUILDING
				building_container.add_child(building_csg)
	
	building_container.global_position.z = -5
	building_container.name = "BUILDINGS"
	add_child(building_container)


func polygon_area(points: PackedVector2Array) -> float:
	var area := 0.0
	var j := points.size() - 1
	for i in range(points.size()):
		area += (points[j].x + points[i].x) * (points[j].y - points[i].y)
		j = i
	return abs(area) * 0.5

func generate_terrain():
	var base_terrain = CSGCombiner3D.new()
	var water_total = CSGCombiner3D.new()
	
	var grass = CSGPolygon3D.new()
	grass.polygon = PackedVector2Array([
		Vector2(FileLoader.bbox[0], FileLoader.bbox[1]),
		Vector2(FileLoader.bbox[0], FileLoader.bbox[3]),
		Vector2(FileLoader.bbox[2], FileLoader.bbox[3]),
		Vector2(FileLoader.bbox[2], FileLoader.bbox[1])
	])
	
	grass.depth = 5

	
	for feature in FileLoader.loaded_multipolys:
		if "Brayford" in feature.properties.name:
			pass
		if feature.properties.water != "-1" or feature.properties.waterway != "-1":
			for poly in feature.geometry.coordinates:
				var water = CSGPolygon3D.new()
				water.polygon = poly
				water.depth = 5
				water.operation = CSGPolygon3D.OPERATION_UNION
				water_total.add_child(water)
				
	for feature in FileLoader.loaded_lines:
		if "Brayford" in feature.properties.name:
			pass
		if feature.properties.water != "-1" or feature.properties.waterway != "-1":
			var poly = feature.geometry.as_polygon(3)
			for discrete_poly in poly:
				var water = CSGPolygon3D.new()
				water.polygon = discrete_poly
				water.depth = 5
				water.operation = CSGPolygon3D.OPERATION_UNION
				water_total.add_child(water)
	
	base_terrain.add_child(grass)
	water_total.operation = CSGShape3D.OPERATION_SUBTRACTION
	base_terrain.add_child(water_total)
	
	
	base_terrain.material_override = GRASS
	base_terrain.name = "TERRAIN"
	add_child(base_terrain)
