class_name Generator
extends Node3D

const LINCOLN = "res://GeoJson-Files/lincoln.geojson"
const GRASS = preload("res://Material/grass.tres")
const BUILDING = preload("res://Material/building.tres")
const PAVED_BRICK = preload("res://Material/paved_brick.tres")
const GRAVEL = preload("res://Material/gravel.tres")
const ROAD = preload("res://Material/road.tres")
const RAIL = preload("res://Material/rail.tres")

@onready var anchor: Node3D = $Anchor
@onready var WorldOrigin: StoredWorldInfo = $WorldOrigin
var step := 0

signal file_loaded
signal event(message : String)

var building_thread : Thread
var terrain_thread : Thread
var path_thread : Thread
var bridges_thread : Thread

var base_terrain : CSGCombiner3D
var water_total : CSGCombiner3D
var path_total : CSGCombiner3D
var building_container : Node3D
var bridges_container : Node3D

var paths : Array[PackedVector2Array] = [] as Array[PackedVector2Array]
var roads : Array[PackedVector2Array] = [] as Array[PackedVector2Array]
var rails : Array[PackedVector2Array] = [] as Array[PackedVector2Array]
var builds : Array[PackedVector2Array] = [] as Array[PackedVector2Array]
var build_names : Array[String] = []
var selectable_buildings : Array[NamedBuilding] = []
var waters : Array[PackedVector2Array] = [] as Array[PackedVector2Array]
var bridges : Array[Path3D]

var t0 : float

var finished = false
var threads : Array[bool] = []

const ROAD_MATCH = ["primary", "secondary", "tertiary", "unclassified", "service", "residential", "unclassified", "trunk"]
const PATH_MATCH = ["pedestrian", "steps", "footway"]

func _ready() -> void:
	await get_tree().process_frame
	FileLoader.load_file(LINCOLN)
	event.emit("Loaded File")
	t0 = Time.get_ticks_msec()
	
	building_thread = Thread.new()
	terrain_thread = Thread.new()
	path_thread = Thread.new()
	bridges_thread = Thread.new()
	
	
	generate_spawn()
	
	building_thread.start(generate_buildings, Thread.PRIORITY_HIGH)
	terrain_thread.start(generate_terrain, Thread.PRIORITY_HIGH)
	path_thread.start(generate_paths, Thread.PRIORITY_HIGH)
	bridges_thread.start(generate_bridges, Thread.PRIORITY_HIGH)
	
	threads = [false, false, false, false]
	
	WorldOrigin.global_position = Vector3(-FileLoader.bbox[2], -5,  -FileLoader.bbox[3])

func _process(delta: float):
	if finished:
		return
	for i in threads:
		if not i:
			return
	
	finished = true
	file_loaded.emit()

func assign_ownership_recursive(root: Node, owner: Node):
	for child in root.get_children():
		child.set_owner(owner)
		assign_ownership_recursive(child, owner)

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

func generate_paths():
	path_total = CSGCombiner3D.new()
	
	#for multipoly : GeoJsonMultiPolyogn in FileLoader.loaded_multipolys:
#		if PATH_MATCH.has(multipoly.properties.highway):
#			for poly in multipoly.geometry.coordinates:
#				var path = CSGPolygon3D.new()
#				path.polygon = poly
#				path.depth = 5.01
#				path.material = GRAVEL
#				path.operation = CSGPolygon3D.OPERATION_UNION
#				path_total.add_child(path)
				
	for linestring : GeoJsonLineString in FileLoader.loaded_lines:
		if PATH_MATCH.has(linestring.properties.highway) and linestring.properties.bridge != "yes":
			var poly = linestring.geometry.as_polygon(2)
			for discrete_poly in poly:
				paths.append(discrete_poly)
			continue
		if ROAD_MATCH.has(linestring.properties.highway) and linestring.properties.bridge != "yes":
			var poly = linestring.geometry.as_polygon(2.5 * min(linestring.properties.lanes, 2))
			for discrete_poly in poly:
				roads.append(discrete_poly)
			continue
		if linestring.properties.railway != "-1" and linestring.properties.ref != "NOB4" and "Line" in linestring.properties.name:
			var poly = linestring.geometry.as_polygon(3)
			for discrete_poly in poly:
				rails.append(discrete_poly)
			continue
		
	path_total.use_collision = true
	call_deferred("paths_callback")

func paths_callback():
	path_thread.wait_to_finish()
	path_total = CSGCombiner3D.new()
	
	for path in paths:
		var csg = CSGPolygon3D.new()
		csg.polygon = path
		csg.depth = 5.01
		csg.material = GRAVEL
		csg.operation = CSGPolygon3D.OPERATION_UNION
		path_total.add_child(csg)
	for road in roads:
		var csg = CSGPolygon3D.new()
		csg.polygon = road
		csg.depth = 5.02
		csg.material = ROAD
		csg.operation = CSGPolygon3D.OPERATION_UNION
		path_total.add_child(csg)
	for rail in rails:
		var csg = CSGPolygon3D.new()
		csg.polygon = rail
		csg.depth = 5.03
		csg.material = RAIL
		csg.operation = CSGPolygon3D.OPERATION_UNION
		path_total.add_child(csg)
		
	WorldOrigin.add_child(path_total)
	path_total.use_collision = true
	threads[0] = true
	print("Paths: " + str(Time.get_ticks_msec() - t0))
	

func generate_bridges():
	bridges_container = Node3D.new()
	for linestring in FileLoader.loaded_lines:
		if linestring.properties.bridge == "yes" and ["primary", "secondary", "tertiary", "unclassified", "service", "residential", "unclassified", "trunk"].has(linestring.properties.highway):
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
			
			bridges.append(path)
	call_deferred("bridges_callback")


func bridges_callback():
	bridges_thread.wait_to_finish()
	WorldOrigin.add_child(bridges_container)
	
	for bridge in bridges:
		var curve : Curve3D = bridge.curve
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		var points := []
		var d := 0.0
		while d < curve.get_baked_length():
			points.append(curve.sample_baked(d))
			d += 2

		# Compute center offset
		var center := Vector3.ZERO
		for p in points:
			center += p
		center /= points.size()

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

			# --- Top Face (road surface)
			st.add_vertex(v1a)
			st.add_vertex(v2a)
			st.add_vertex(v2b)

			st.add_vertex(v1a)
			st.add_vertex(v2b)
			st.add_vertex(v1b)

			# --- Bottom Face (underside)
			st.add_vertex(v1b_b)
			st.add_vertex(v2b_b)
			st.add_vertex(v2a_b)

			st.add_vertex(v1b_b)
			st.add_vertex(v2a_b)
			st.add_vertex(v1a_b)

			# --- Left Face
			st.add_vertex(v1a_b)
			st.add_vertex(v2a_b)
			st.add_vertex(v2a)

			st.add_vertex(v1a_b)
			st.add_vertex(v2a)
			st.add_vertex(v1a)

			# --- Right Face
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
	
	threads[1] = true
	print("Bridges: " + str(Time.get_ticks_msec() - t0))

func generate_buildings():
	building_container = Node3D.new()
	
	for building in FileLoader.loaded_multipolys:
		if building.properties.building != "-1" or building.properties.building != "-1":
			builds.append(building.geometry.coordinates[0])
			build_names.append(building.properties.name)
	
	building_container.name = "BUILDINGS"
	
	call_deferred("building_callback")

func building_callback():
	building_thread.wait_to_finish()
	WorldOrigin.add_child(building_container)
	
	for i in range(len(builds)):
		var build = builds[i]
		var building_csg = NamedBuilding.new()
		building_csg.polygon = build
		building_csg.operation = CSGPolygon3D.OPERATION_UNION
		building_csg.depth = pow(polygon_area(build), 0.22) * 3
		building_csg.material = BUILDING
		building_csg.use_collision = true
		building_csg.building_name = build_names[i]
		if build_names[i] != "-1":
			selectable_buildings.append(building_csg)
		building_container.add_child(building_csg)
			
	threads[2] = true
	print("Buildings: " + str(Time.get_ticks_msec() - t0))

func polygon_area(points: PackedVector2Array) -> float:
	var area := 0.0
	var j := points.size() - 1
	for i in range(points.size()):
		area += (points[j].x + points[i].x) * (points[j].y - points[i].y)
		j = i
	return abs(area) * 0.5

func generate_terrain():
	base_terrain = CSGCombiner3D.new()
	water_total = CSGCombiner3D.new()
	
	var grass = CSGPolygon3D.new()
	grass.polygon = PackedVector2Array([
		Vector2(FileLoader.bbox[0], FileLoader.bbox[1]),
		Vector2(FileLoader.bbox[0], FileLoader.bbox[3]),
		Vector2(FileLoader.bbox[2], FileLoader.bbox[3]),
		Vector2(FileLoader.bbox[2], FileLoader.bbox[1])
	])
	
	grass.depth = 5
	grass.material = GRASS

	for feature in FileLoader.loaded_multipolys:
		if feature.properties.water != "-1" or feature.properties.waterway != "-1":
			waters.append(feature.geometry.coordinates[0])
	
	for feature in FileLoader.loaded_lines:
		if "Brayford" in feature.properties.name:
			pass
		if feature.properties.water != "-1" or feature.properties.waterway != "-1":
			var poly = feature.geometry.as_polygon(3)
			for discrete_poly in poly:
				waters.append(discrete_poly)
	
	base_terrain.add_child(grass)
	water_total.operation = CSGShape3D.OPERATION_SUBTRACTION
	base_terrain.add_child(water_total)
	base_terrain.use_collision = true
	
	
	base_terrain.name = "TERRAIN"
	call_deferred("terrain_callback")

func terrain_callback():
	terrain_thread.wait_to_finish()
	WorldOrigin.add_child(base_terrain)
	
	for water in waters:
		var csg = CSGPolygon3D.new()
		csg.polygon = water
		csg.depth = 5
		csg.operation = CSGPolygon3D.OPERATION_UNION
		water_total.add_child(csg)
	
	threads[3] = true
	print("Terrain: " + str(Time.get_ticks_msec() - t0))

func gen_step():
	await get_tree().process_frame

func bake_csg_to_static(csg: CSGShape3D):
	# Bake mesh from CSG
	var mesh = csg.bake_static_mesh()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.global_transform = csg.global_transform

	# Create StaticBody3D with collision
	var static_body = StaticBody3D.new()
	static_body.global_transform = csg.global_transform

	var collider = CollisionShape3D.new()
	collider.shape = csg.bake_collision_shape()
	static_body.add_child(collider)

	# Add baked objects to the scene
	csg.get_parent().add_child(mesh_instance)
	csg.get_parent().add_child(static_body)

	# Optional: Remove the original CSG
	csg.queue_free()


func bake_csgs_recursive(root: Node):
	for child in root.get_children():
		if child is CSGShape3D:
			bake_csg_to_static(child)
		else:
			bake_csgs_recursive(child)

func emit_message(message : String):
	event.emit(message)
