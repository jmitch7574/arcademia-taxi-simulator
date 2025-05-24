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

func _ready() -> void:
	FileLoader.load_file(LINCOLN)
	event.emit("Loaded File")
	await gen_step()
	generate_spawn()
	await gen_step()
	event.emit("Found Spawn Point")
	generate_terrain()
	await gen_step()
	generate_buildings()
	event.emit("Loaded Buildings")
	await gen_step()
	generate_paths()
	await gen_step()
	generate_bridges()
	event.emit("Loaded Bridges")
	await gen_step()
	WorldOrigin.global_position = Vector3(-FileLoader.bbox[2], -5,  -FileLoader.bbox[3])
	WorldOrigin.name = FileLoader.worldName
	file_loaded.emit()
	event.emit("Done")
	
	assign_ownership_recursive(WorldOrigin, WorldOrigin)
	
	var scene = PackedScene.new()
	scene.pack(WorldOrigin)
	event.emit("Saving at res://SavedGens/" + FileLoader.worldName + ".tscn")
	var result = ResourceSaver.save(scene, "res://SavedGens/" + FileLoader.worldName + ".tscn")
	event.emit("Save result: " + str(result))

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
	var path_total = Node3D.new()
	path_total.name = "PATHS"
	var road_total = Node3D.new()
	road_total.name = "ROADS"
	var rail_total = Node3D.new()
	rail_total.name = "RAILS"
	
	for multipoly in FileLoader.loaded_multipolys:
		if ["pedestrian", "steps", "footway"].has(multipoly.properties.highway):
			for poly in multipoly.geometry.coordinates:
				path_total.add_child(create_extruded_polygon(poly, 5.01, GRAVEL))
				
	for linestring in FileLoader.loaded_lines:
		if ["pedestrian", "steps", "footway"].has(linestring.properties.highway) and linestring.properties.bridge != "yes":
			var poly = linestring.geometry.as_polygon(2)
			for discrete_poly in poly:
				path_total.add_child(create_extruded_polygon(poly, 5.01, GRAVEL))
			continue
		if ["primary", "secondary", "tertiary", "unclassified", "service", "residential", "unclassified", "trunk"].has(linestring.properties.highway) and linestring.properties.bridge != "yes":
			var poly = linestring.geometry.as_polygon(2.5 * min(linestring.properties.lanes, 2))
			for discrete_poly in poly:
				road_total.add_child(create_extruded_polygon(discrete_poly, 5.1, ROAD))
			continue
		if linestring.properties.railway != "-1" and linestring.properties.ref != "NOB4" and "Line" in linestring.properties.name:
			var poly = linestring.geometry.as_polygon(3)
			for discrete_poly in poly:
				rail_total.add_child(create_extruded_polygon(discrete_poly, 5.05, RAIL))
			continue
		
	WorldOrigin.add_child(path_total)
	event.emit("Loaded Paths")
	WorldOrigin.add_child(road_total)
	event.emit("Loaded Roads")
	WorldOrigin.add_child(rail_total)
	event.emit("Loaded Rails")

func generate_bridges():
	var bridges = Node3D.new()
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
		
			
			var curve : Curve3D = path.curve
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
			bridges.add_child(mesh_instance)
	
	bridges.rotation_degrees = Vector3(-90, 0, 0)
	bridges.position.z = -5
	WorldOrigin.add_child(bridges)

func generate_buildings():
	var building_container = Node3D.new()
	
	for building in FileLoader.loaded_multipolys:
		if building.properties.building != "-1" or building.properties.building != "-1":
			for poly in building.geometry.coordinates:
				building_container.add_child(create_extruded_polygon(poly, pow(polygon_area(poly), 0.22) * 3, BUILDING))
	
	building_container.global_position.z = -5
	building_container.name = "BUILDINGS"
	WorldOrigin.add_child(building_container)


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
	event.emit("Created Terrain")
	
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
	event.emit("Created Lakes and Rivers")
	
	base_terrain.add_child(grass)
	water_total.operation = CSGShape3D.OPERATION_SUBTRACTION
	base_terrain.add_child(water_total)
	
	
	base_terrain.material_override = GRASS
	base_terrain.use_collision = true
	base_terrain.name = "TERRAIN"
	WorldOrigin.add_child(base_terrain)

func gen_step():
	await get_tree().process_frame

func create_extruded_polygon(polygon: PackedVector2Array, height: float, material : Material) -> Node3D:
	var node := Node3D.new()

	# Create the Mesh
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Top and bottom faces
	var top := []
	var bottom := []
	for point in polygon:
		top.append(Vector3(point.x, point.y, -height))
		bottom.append(Vector3(point.x, point.y, 0))

	# Triangulate the top face
	var indices := Geometry2D.triangulate_polygon(polygon)
	for i in range(0, indices.size(), 3):
		var i0 = indices[i]
		var i1 = indices[i + 1]
		var i2 = indices[i + 2]

		var v0 = top[i0]
		var v1 = top[i1]
		var v2 = top[i2]

		st.set_uv(Vector2(v0.x, v0.z))
		st.add_vertex(v0)
		st.set_uv(Vector2(v1.x, v1.z))
		st.add_vertex(v1)
		st.set_uv(Vector2(v2.x, v2.z))
		st.add_vertex(v2)

		# Bottom face (inverted winding)
		var bv0 = bottom[i2]
		var bv1 = bottom[i1]
		var bv2 = bottom[i0]

		st.set_uv(Vector2(bv0.x, bv0.z))
		st.add_vertex(bv0)
		st.set_uv(Vector2(bv1.x, bv1.z))
		st.add_vertex(bv1)
		st.set_uv(Vector2(bv2.x, bv2.z))
		st.add_vertex(bv2)

	# Side faces
	var n := polygon.size()
	for i in range(n):
		var next := (i + 1) % n

		var p0 = bottom[i]
		var p1 = bottom[next]
		var p2 = top[next]
		var p3 = top[i]

		var u0 = float(i) / n
		var u1 = float(i + 1) / n

		# First triangle
		st.set_uv(Vector2(u0, 0))
		st.add_vertex(p0)
		st.set_uv(Vector2(u1, 1))
		st.add_vertex(p2)
		st.set_uv(Vector2(u1, 0))
		st.add_vertex(p1)

		# Second triangle
		st.set_uv(Vector2(u0, 0))
		st.add_vertex(p0)
		st.set_uv(Vector2(u0, 1))
		st.add_vertex(p3)
		st.set_uv(Vector2(u1, 1))
		st.add_vertex(p2)

	st.generate_normals()
	mesh = st.commit()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	node.add_child(mesh_instance)
	
	mesh_instance.material_override = material

	# Collision
	var col_shape := ConcavePolygonShape3D.new()
	col_shape.set_faces(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	
	var static_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	collision.shape = col_shape
	static_body.add_child(collision)
	node.add_child(static_body)

	return node
