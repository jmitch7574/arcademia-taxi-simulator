class_name Generator
extends Node3D
## The big massive class that creates the world the user drives in
##
## Loads a GeoJson file and uses [CSGPolygon3D]s to create world features. 
## NOTE: Generator should be rotated 90 since CSGs are orientated weirdly by default


const LINCOLN = "res://GeoJson-Files/lincoln.geojson"

## Grass materail
const GRASS = preload("res://Material/grass.tres")

## Building material
const BUILDING = preload("res://Material/building.tres")

## Gravel material for paths
const GRAVEL = preload("res://Material/gravel.tres")

## Road material
const ROAD = preload("res://Material/road.tres")

## Rail material
const RAIL = preload("res://Material/rail.tres")

## Anchor, which used to be used for debugging the lincoln map, goes unused in game
@onready var anchor: Node3D = $Anchor

## The parent object of the generated world
@onready var WorldOrigin: StoredWorldInfo = $WorldOrigin

## Little counter used to pause for a frame every x amount of objects generated
##
## Legit only exists because at one point loading times got so bad windows thought the game crashed :(
var step := 0

## Signal used for when the world is finished generating
signal world_generated

## Signal used for when a generation event happens
signal event(message : String)

## CSG Combiner for the base world terrain
var base_terrain : CSGCombiner3D

## CSG Combiner for the water polygons
var water_total : CSGCombiner3D

## Parent for all paths
var path_total : Node3D

## Parent for all buildings
var building_container : Node3D

## Parent for all bridges
var bridges_container : Node3D

## Array for path geometries
var paths : Array[PackedVector2Array] = [] as Array[PackedVector2Array]

## Array for road geometries
var roads : Array[PackedVector2Array] = [] as Array[PackedVector2Array]

## Array for rail geometries
var rails : Array[PackedVector2Array] = [] as Array[PackedVector2Array]

## Array for building names
var build_names : Array[String] = []

## Array for selectable buildings
var selectable_buildings : Array[NamedBuilding] = []

var t0 : float

var finished = false

const ROAD_MATCH = ["primary", "secondary", "tertiary", "unclassified", "service", "residential", "unclassified", "trunk"]
const PATH_MATCH = ["pedestrian", "steps", "footway"]


func _ready() -> void:
	FileLoader.load_file(LINCOLN) 		# Load data
	
	event.emit("Loaded File")			# Perform each generation task
	await gen_step()
	generate_spawn()
	await gen_step()
	event.emit("Found Spawn Point")
	generate_terrain()
	await gen_step()
	generate_buildings()
	event.emit("Loaded Buildings")
	await gen_step()
	generate_bridges()
	event.emit("Loaded Bridges")
	await gen_step()
	collect_paths()
	generate_paths()
	
	WorldOrigin.add_child(base_terrain) 		# Child all generated nodes
	WorldOrigin.add_child(building_container)
	WorldOrigin.add_child(bridges_container)
	
	WorldOrigin.global_position = Vector3(-FileLoader.bbox[2] / 2, -5,  -FileLoader.bbox[3] / 2) # Keep generated items close to 0,0
	WorldOrigin.name = FileLoader.worldName
	world_generated.emit()
	event.emit("Done")

## Get GeoJson Point objects named spawn point (note: custom additions not in original OSM data)
func generate_spawn():
	for point in FileLoader.loaded_points:
		if point.properties.name == "SPAWN_POINT":
			WorldOrigin.spawn_point = Node3D.new()
			WorldOrigin.spawn_point.name = "SPAWN POINT"
			WorldOrigin.spawn_point.position = Vector3(point.geometry.coordinates.x, point.geometry.coordinates.y, -6)
			WorldOrigin.add_child(WorldOrigin.spawn_point)
			return
	
	event.emit("Could not find spawn point feature. Terminating...")
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

## Collect all paths from multipolygon and linestring data
func collect_paths():
	for multipoly in FileLoader.loaded_multipolys:
		if ["pedestrian", "steps", "footway"].has(multipoly.properties.highway):
				paths.append(multipoly.geometry.coordinates[0])
				
	for linestring in FileLoader.loaded_lines:
		if ["pedestrian", "steps", "footway"].has(linestring.properties.highway) and linestring.properties.bridge != "yes":
			var poly = linestring.geometry.as_polygon(2)
			for discrete_poly in poly:
				paths.append(discrete_poly)
			continue
		if ["primary", "secondary", "tertiary", "unclassified", "service", "residential", "unclassified", "trunk"].has(linestring.properties.highway) and linestring.properties.bridge != "yes":
			var poly = linestring.geometry.as_polygon(2.5 * min(linestring.properties.lanes, 2))
			for discrete_poly in poly:
				roads.append(discrete_poly)
			continue
		if linestring.properties.railway != "-1" and linestring.properties.ref != "NOB4" and "Line" in linestring.properties.name:
			var poly = linestring.geometry.as_polygon(3)
			for discrete_poly in poly:
				rails.append(discrete_poly)

## Generate path CSGs
func generate_paths():
	path_total =  Node3D.new()
	var count : int = 0
	
	for path in paths:
		count = count + 1
		var csg = CSGPolygon3D.new()
		csg.polygon = path
		csg.depth = 5.01
		csg.material = GRAVEL
		csg.operation = CSGPolygon3D.OPERATION_UNION
		csg.use_collision = true
		path_total.add_child(csg)
	for path in roads:
		count = count + 1
		var csg = CSGPolygon3D.new()
		csg.polygon = path
		csg.depth = 5.02
		csg.material = ROAD
		csg.operation = CSGPolygon3D.OPERATION_UNION
		csg.use_collision = true
		path_total.add_child(csg)
	for path in rails:
		count = count + 1
		var csg = CSGPolygon3D.new()
		csg.polygon = path
		csg.depth = 5.03
		csg.material = RAIL
		csg.operation = CSGPolygon3D.OPERATION_UNION
		csg.use_collision = true
		path_total.add_child(csg)
	
	event.emit("Loaded Paths")
	WorldOrigin.add_child(path_total)

## Generate Bridges
func generate_bridges():
	bridges_container = Node3D.new()
	for linestring in FileLoader.loaded_lines: # Go throguh LineStrings
		
		# Bridge Condition
		if linestring.properties.bridge == "yes" and ["primary", "secondary", "tertiary", "unclassified", "service", "residential", "unclassified", "trunk"].has(linestring.properties.highway):
			
			# Create path 3D node out of line string
			var path = Path3D.new()
			path.curve = Curve3D.new()
			var coords = linestring.geometry.coordinates
			for k in range(0, floor(len(coords) / 2)):
				var t = float(k) / float(coords.size() - 1)
				var bridge_height = sin(t * PI) * min(len(coords), 15)
				path.curve.add_point(Vector3(coords[k].x, bridge_height, coords[k].y))
			for k in range(floor(len(coords) / 2),  len(coords)):
				var t = float(k) / float(coords.size() - 1)
				var bridge_height = sin(t * PI) * min(len(coords), 15)
				path.curve.add_point(Vector3(coords[k].x, bridge_height, coords[k].y))
		
			
			var curve : Curve3D = path.curve
			
			# Create Surface tool for mesh generation
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)

			var points := []
			var d := 0.0
			while d < curve.get_baked_length():
				points.append(curve.sample_baked(d))
				d += 2

			# Compute center offset, used so that node location represents bridge location, instead of node being at 0,0 with mesh points being at 3000,000 or something
			# Bit hacky icl
			var center := Vector3.ZERO
			for p in points:
				center += p
			center /= points.size()

			# Brigde details
			var width = 6.0
			var height = 3

			for i in range(points.size() - 1):
				var p1 = points[i] - center
				var p2 = points[i + 1] - center

				p1 = p1 + (p1 - p2) * 0.1
				p2 = p2 + (p2 - p1) * 0.1

				var forward = (p2 - p1).normalized()
				var up = Vector3.UP
				var right = forward.cross(up).normalized() * width

				# Top vertices
				var v1a = p1 - right
				var v1b = p1 + right
				var v2a = p2 - right
				var v2b = p2 + right

				# Bottom vertices (lowered by height)
				var v1a_b = v1a - up * height
				var v1b_b = v1b - up * height
				var v2a_b = v2a - up * height
				var v2b_b = v2b - up * height

				var normal_up = Vector3.UP
				var normal_down = -Vector3.UP
				var normal_left = -right.normalized()
				var normal_right = right.normalized()

				# Top Face
				st.add_vertex(v1a)
				st.add_vertex(v2a)
				st.add_vertex(v2b)

				st.add_vertex(v1a)
				st.add_vertex(v2b)
				st.add_vertex(v1b)

				# Bottom Face
				st.add_vertex(v1b_b)
				st.add_vertex(v2b_b)
				st.add_vertex(v2a_b)

				st.add_vertex(v1b_b)
				st.add_vertex(v2a_b)
				st.add_vertex(v1a_b)

				# Left Face
				st.add_vertex(v1a_b)
				st.add_vertex(v2a_b)
				st.add_vertex(v2a)

				st.add_vertex(v1a_b)
				st.add_vertex(v2a)
				st.add_vertex(v1a)

				# Right Face
				st.add_vertex(v1b)
				st.add_vertex(v2b)
				st.add_vertex(v2b_b)

				st.add_vertex(v1b)
				st.add_vertex(v2b_b)
				st.add_vertex(v1b_b)

			# Commit mesh
			var mesh := st.commit()
			mesh.surface_set_material(0, ROAD)

			# Create MeshInstance3D at center
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.mesh = mesh
			mesh_instance.position = center
			mesh_instance.create_trimesh_collision()
			bridges_container.add_child(mesh_instance)
	
	bridges_container.rotation_degrees = Vector3(-90, 0, 0)
	bridges_container.position.z = -5

## Generate Building CSGs
## TODO: Turns out multipolygons are used to define holes in larger polygons, revisit this
func generate_buildings():
	building_container = Node3D.new()
	
	for building in FileLoader.loaded_multipolys: # Go though multipolygons
		if building.properties.building != "-1" or building.properties.building != "-1":
			var building_csg = NamedBuilding.new() ## Create CSG Node
			var build_name = building.properties.name ## Get building name
			building_csg.polygon = building.geometry.coordinates[0] ## The first polygon in the multipolygon usually spans all of them
			building_csg.operation = CSGPolygon3D.OPERATION_UNION
			building_csg.depth = pow(polygon_area(building.geometry.coordinates[0]), 0.22) * 3 ## Scale height with building area
			building_csg.material = BUILDING ## set Building Material
			building_csg.use_collision = true ## Give the building collision
			building_csg.building_name = build_name ## Apply the building name
			
			## TODO: Replace this with something more reliable, easy to get stuck on the wrong side of building
			## Also there's some buildings which are literally impossible to get close to the center of
			building_csg.center = Vector3(building.geometry.coordinates[0][0].x, 0, building.geometry.coordinates[0][0].y) + Vector3(-FileLoader.bbox[2] / 2, -5,  -FileLoader.bbox[3] / 2)
			
			## If the building has a valid name, make it a selectable one
			if (build_name != "-1"):
				selectable_buildings.append(building_csg)
			building_container.add_child(building_csg)
	
	building_container.global_position.z = -5
	building_container.name = "BUILDINGS"
	
## Calculate the area of a polygon
func polygon_area(points: PackedVector2Array) -> float:
	var area := 0.0
	var j := points.size() - 1
	for i in range(points.size()):
		area += (points[j].x + points[i].x) * (points[j].y - points[i].y)
		j = i
	return abs(area) * 0.5

## Generate base terrain of the world, grass area with holes for water cut out
##
## TODO: Rewrite this, lincoln is way too grassy atm
## TODO: Also rewrite so that places like brayford island can exist
func generate_terrain():
	
	base_terrain = CSGCombiner3D.new()
	water_total = CSGCombiner3D.new()
	
	# Generate Base Grass
	var grass = CSGPolygon3D.new()
	grass.polygon = PackedVector2Array([
		Vector2(FileLoader.bbox[0], FileLoader.bbox[1]),
		Vector2(FileLoader.bbox[0], FileLoader.bbox[3]),
		Vector2(FileLoader.bbox[2], FileLoader.bbox[3]),
		Vector2(FileLoader.bbox[2], FileLoader.bbox[1])
	])
	event.emit("Created Terrain")
	
	grass.depth = 5
	grass.material = GRASS

	
	for feature in FileLoader.loaded_multipolys:
		if feature.properties.water != "-1" or feature.properties.waterway != "-1":
			for poly in feature.geometry.coordinates:
				var water = CSGPolygon3D.new()
				water.polygon = poly
				water.depth = 5
				water.operation = CSGPolygon3D.OPERATION_UNION
				water_total.add_child(water)
		if feature.properties.landuse == "resedential":
			for poly in feature.geometry.coordinates:
				var resedential = CSGPolygon3D.new()
				resedential.polygon = poly
				resedential.depth = 5.01
				resedential.operation = CSGPolygon3D.OPERATION_UNION
				resedential.material = GRAVEL
				base_terrain.add_child(resedential)
				
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
	event.emit("Created Lakes and Rivers")
	
	base_terrain.add_child(grass)
	water_total.operation = CSGShape3D.OPERATION_SUBTRACTION
	base_terrain.add_child(water_total)
	base_terrain.use_collision = true
	base_terrain.name = "TERRAIN"

func gen_step():
	await get_tree().process_frame
