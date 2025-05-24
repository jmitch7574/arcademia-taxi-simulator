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
				path.use_collision = true
				path_total.add_child(path)
				
	for linestring in FileLoader.loaded_lines:
		if ["pedestrian", "steps", "footway"].has(linestring.properties.highway) and linestring.properties.bridge != "yes":
			var poly = linestring.geometry.as_polygon(2)
			for discrete_poly in poly:
				var path = CSGPolygon3D.new()
				path.polygon = discrete_poly
				path.depth = 5.01
				path.material = GRAVEL
				path.use_collision = true
				path_total.add_child(path)
			continue
		if ["primary", "secondary", "tertiary", "unclassified", "service", "residential", "unclassified", "trunk"].has(linestring.properties.highway) and linestring.properties.bridge != "yes":
			var poly = linestring.geometry.as_polygon(2.5 * min(linestring.properties.lanes, 2))
			for discrete_poly in poly:
				var path = CSGPolygon3D.new()
				path.polygon = discrete_poly
				path.depth = 5.02
				path.material = ROAD
				path.use_collision = true
				road_total.add_child(path)
			continue
		if linestring.properties.railway != "-1" and linestring.properties.ref != "NOB4" and "Line" in linestring.properties.name:
			var poly = linestring.geometry.as_polygon(3)
			for discrete_poly in poly:
				var path = CSGPolygon3D.new()
				path.polygon = discrete_poly
				path.depth = 5.03
				path.material = RAIL
				path.use_collision = true
				rail_total.add_child(path)
			continue
		
	add_child(path_total)
	add_child(road_total)
	add_child(rail_total)

func generate_bridges():
	var bridges = Node3D.new()
	for linestring in FileLoader.loaded_lines:
		if linestring.properties.bridge == "yes" and ["primary", "secondary", "tertiary", "unclassified", "service", "residential", "unclassified", "trunk"].has(linestring.properties.highway):
			var path = Path3D.new()
			path.curve = Curve3D.new()
			var coords = linestring.geometry.coordinates
			for k in range(0, floor(len(coords) / 2)):
				var t = float(k) / float(coords.size() - 1)
				var bridge_height = sin(t * PI) * min(2 * len(coords), 20)
				path.curve.add_point(Vector3(coords[k].x, bridge_height, coords[k].y))
			for k in range(floor(len(coords) / 2),  len(coords)):
				var t = float(k) / float(coords.size() - 1)
				var bridge_height = sin(t * PI) * min(2 * len(coords), 20)
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
	add_child(bridges)

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
				building.use_collision = true
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
	base_terrain.use_collision = true
	
	
	base_terrain.material_override = GRASS
	base_terrain.name = "TERRAIN"
	add_child(base_terrain)
