class_name FileLoader

static var loaded_points : Array[GeoJsonPoint]
static var loaded_lines : Array[GeoJsonLineString]
static var loaded_multipolys : Array[GeoJsonMultiPolyogn]

static var reference_coord : PackedVector2Array

static func load_file(path_name: String) -> void:
	var file := FileAccess.open(path_name, FileAccess.READ)
	var content := file.get_as_text()
	
	var parsed_content = JSON.parse_string(content)
	
	if parsed_content == null:
		return
	
	for feature in parsed_content["features"]:
		pass

static func parse_point(point_data):
	pass

static func parse_line(line_data):
	pass

static func parse_poly(poly_data):
	pass
