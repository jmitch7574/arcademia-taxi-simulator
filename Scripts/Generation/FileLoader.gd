class_name FileLoader

static var loaded_points : Array[GeoJsonPoint]
static var loaded_lines : Array[GeoJsonLineString]
static var loaded_multipolys : Array[GeoJsonMultiPolyogn]

static var reference_coord : Vector2
static var bbox: Vector4
static var worldName : String

signal file_loaded

static func load_file(path_name: String) -> void:
	var file := FileAccess.open(path_name, FileAccess.READ)
	var content := file.get_as_text()
	var file_name = path_name.get_file()
	
	var stripped = file_name.replace(".geojson", "").capitalize()
	
	worldName = stripped
	
	var parsed_content = JSON.parse_string(content)
	
	if parsed_content == null:
		return
	
	reference_coord = Vector2(parsed_content["referenceCoords"][0], parsed_content["referenceCoords"][1])
	
	var temp_bbox : Array[Vector2] = [
		GenerationExtras.project_ortho(parsed_content["bbox"][1], parsed_content["bbox"][0], reference_coord[0], reference_coord[1]),
		GenerationExtras.project_ortho(parsed_content["bbox"][3], parsed_content["bbox"][2], reference_coord[0], reference_coord[1]),
	]
	
	bbox = Vector4(temp_bbox[0][0], temp_bbox[0][1], temp_bbox[1][0], temp_bbox[1][1])
	
	for feature in parsed_content["features"]:
		if feature["geometry"]["type"] == "Point":
			parse_point(feature)
		if feature["geometry"]["type"] == "LineString":
			parse_line(feature)
		if feature["geometry"]["type"] == "MultiPolygon":
			parse_poly(feature)
	
static func parse_point(point_feature):
	var new_point = GeoJsonPoint.new()
	var feature_points = point_feature["geometry"]["coordinates"]
	new_point.geometry = GeoJsonPoint.GeoJsonPointGeometry.new()
	new_point.geometry.coordinates = \
		GenerationExtras.project_ortho(feature_points[1], feature_points[0], reference_coord[0], reference_coord[1])
	
	new_point.properties = parse_properties(point_feature)
	
	loaded_points.append(new_point)

static func parse_line(line_feature):
	var new_line = GeoJsonLineString.new()
	var feature_points = line_feature["geometry"]["coordinates"]
	new_line.geometry = GeoJsonLineString.GeoJsonLineStringGeometry.new()
	new_line.geometry.coordinates = []
	for point in feature_points:
		new_line.geometry.coordinates.append(GenerationExtras.project_ortho(point[1], point[0], reference_coord[0], reference_coord[1]))
	
	new_line.properties = parse_properties(line_feature)
	
	loaded_lines.append(new_line)

static func parse_poly(poly_feature):
	var new_poly = GeoJsonMultiPolyogn.new()
	var feature_points = poly_feature["geometry"]["coordinates"]
	new_poly.geometry = GeoJsonMultiPolyogn.GeoJsonMultiPolygonGeometry.new()
	new_poly.geometry.coordinates = [] as Array[PackedVector2Array]
	for poly in feature_points[0]:
		var this_poly: PackedVector2Array = []
		for point : Array in poly:
			this_poly.append(GenerationExtras.project_ortho(point[1], point[0], reference_coord[0], reference_coord[1]))
		new_poly.geometry.coordinates.append(this_poly)
	
	new_poly.properties = parse_properties(poly_feature)
	
	loaded_multipolys.append(new_poly)

static func parse_properties(feature) -> GeoJsonProperties:
	var new_props = GeoJsonProperties.new()
	
	var feat_props : Dictionary = feature["properties"]
	
	new_props.building = get_value(feat_props, "building", "-1")
	new_props.layer = get_value(feat_props, "layer", -1)
	new_props.name = get_value(feat_props, "name", "-1")
	new_props.natural = get_value(feat_props, "natural", "-1")
	new_props.water = get_value(feat_props, "water", "-1")
	new_props.waterway = get_value(feat_props, "waterway", "-1")
	new_props.highway = get_value(feat_props, "highway", "-1")
	new_props.lanes = get_value(feat_props, "lanes", 2)
	new_props.railway = get_value(feat_props, "railway", "-1")
	new_props.ref = get_value(feat_props, "ref", "-1")
	new_props.bridge = get_value(feat_props, "bridge", "no")
	new_props.landuse = get_value(feat_props, "landuse", "-1")
	
	return new_props

static func get_value(dict : Dictionary, key, default):
	return dict.get(key, default) if dict.get(key, default) != null else default
