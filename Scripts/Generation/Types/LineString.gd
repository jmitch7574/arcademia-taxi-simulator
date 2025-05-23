class_name GeoJsonLineString
## A class for containing geometry and property information about GeoJSON Linestrings
##
## This class is mostly used for storing information on paths, roads and rivers

## Class for storing GeoJSON LineString geometry
class GeoJsonLineStringGeometry:
	
	## The coordinates array that makes up the line
	var coordinates: PackedVector2Array
	
	## This function represents the linestring as a polygon with some width
	func as_polygon(width: float):
		return Geometry2D.offset_polyline(coordinates, width, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)

## The LineString Geometry of the feature
var geometry: GeoJsonLineStringGeometry

## The properties of the feature
var properties: GeoJsonProperties
