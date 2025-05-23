class_name FileLoader
## GeoJSON File Loader helper class
##
## This class manages the loading of GeoJSON files into arrays of [GeoJsonPoint], [GeoJsonLineString] and [GeoJsonMultiPolygon] features.

## The loaded [GeoJsonPoint] features
static var loaded_points : Array[GeoJsonPoint]

## The loaded [GeoJsonLineString] features
static var loaded_lines : Array[GeoJsonLineString]

## The loaded [GeoJsonMultiPolygon] features
static var loaded_multipolys : Array[GeoJsonMultiPolygon]

## The coordinates used to project latitude and longitude to a 2D space
static var reference_coord : Vector2

## The bounding box of our GeoJson area
static var bbox: Vector4

## The name of our city
##
## Defined by the filename of the GeoJson File loaded, stripped of file path and extension, and then [method String.capitalize]'d [br]
## e.g. [code]res://GeoJson-Files/lincoln.geojson[/code] becomes Lincoln
static var worldName : String

## Signal for declaring when a file has finished loading
signal file_loaded

"""
Loads the file at the given path (e.g. res://GeoJson-Files/lincoln.geojson) and 
"""
static func load_file(path_name: String) -> void:
	
	# Get file content into a dictionary
	var file := FileAccess.open(path_name, FileAccess.READ)
	var content := file.get_as_text()
	var file_name = path_name.get_file()
	var parsed_content = JSON.parse_string(content)
	
	if parsed_content == null:
		return
	
	
	# Get city name
	var stripped = file_name.replace(".geojson", "").capitalize()
	worldName = stripped
	
	# Calculate the bounding box (bbox) area in world space
	reference_coord = Vector2(parsed_content["referenceCoords"][0], parsed_content["referenceCoords"][1])
	var temp_bbox : Array[Vector2] = [
		GenerationExtras.project_ortho(parsed_content["bbox"][1], parsed_content["bbox"][0], reference_coord[0], reference_coord[1]),
		GenerationExtras.project_ortho(parsed_content["bbox"][3], parsed_content["bbox"][2], reference_coord[0], reference_coord[1]),
	]
	bbox = Vector4(temp_bbox[0][0], temp_bbox[0][1], temp_bbox[1][0], temp_bbox[1][1])
	
	# Filter features and process them
	for feature in parsed_content["features"]:
		if feature["geometry"]["type"] == "Point":
			parse_point(feature)
		if feature["geometry"]["type"] == "LineString":
			parse_line(feature)
		if feature["geometry"]["type"] == "MultiPolygon":
			parse_poly(feature)

## Take a dictionary and convert it to a [GeoJsonPointFeature] object
static func parse_point(point_feature):
	var new_point = GeoJsonPoint.new() 									# Create Point object
	var feature_points = point_feature["geometry"]["coordinates"] 		# Get raw coordiantes
	new_point.geometry = GeoJsonPoint.GeoJsonPointGeometry.new()		# Create Point Geometry
	new_point.geometry.coordinates = \
		GenerationExtras.project_ortho(feature_points[1], feature_points[0], reference_coord[0], reference_coord[1]) # Convert lat and lon into game Coords
	
	new_point.properties = parse_properties(point_feature)				# Parse feature properties
	
	loaded_points.append(new_point)										# Append point to list

## Take a dictionary and convert it to a [GeoJsonLineString]
static func parse_line(line_feature):
	var new_line = GeoJsonLineString.new()								# Create LineString object
	var feature_points = line_feature["geometry"]["coordinates"]		# Get raw coordinates
	new_line.geometry = GeoJsonLineString.GeoJsonLineStringGeometry.new() 	# Create new LineString geometry
	new_line.geometry.coordinates = []
	for point in feature_points:										# Convert lat and lon into game Coords
		new_line.geometry.coordinates.append(GenerationExtras.project_ortho(point[1], point[0], reference_coord[0], reference_coord[1]))
	
	new_line.properties = parse_properties(line_feature)				# Parse feature properties
	
	loaded_lines.append(new_line)										# Append line to list

## Take a dictionary and convert it to a [GeoJsonMultiPolygon]
static func parse_poly(poly_feature):
	var new_poly = GeoJsonMultiPolygon.new()							# Create MultiPolygon object
	var feature_points = poly_feature["geometry"]["coordinates"]		# Get raw coordinates
	new_poly.geometry = GeoJsonMultiPolygon.GeoJsonMultiPolygonGeometry.new()	# Create LineString geometry
	new_poly.geometry.coordinates = [] as Array[PackedVector2Array]		# Convert lat and lon into game coords
	for poly in feature_points[0]:
		var this_poly: PackedVector2Array = []
		for point : Array in poly:
			this_poly.append(GenerationExtras.project_ortho(point[1], point[0], reference_coord[0], reference_coord[1]))
		new_poly.geometry.coordinates.append(this_poly)
	
	new_poly.properties = parse_properties(poly_feature)
	
	loaded_multipolys.append(new_poly)

## Take the properties dictionary and convert them to a [GeoJsonProperties] object
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
