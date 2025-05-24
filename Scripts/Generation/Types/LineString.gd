class_name GeoJsonLineString

class GeoJsonLineStringGeometry:
	var coordinates: PackedVector2Array
	
	func as_polygon(width: float):
		return Geometry2D.offset_polyline(coordinates, width, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)

var geometry: GeoJsonLineStringGeometry
var properties: GeoJsonProperties
