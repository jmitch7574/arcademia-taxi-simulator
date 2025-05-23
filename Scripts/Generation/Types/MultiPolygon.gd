class_name GeoJsonMultiPolygon
## A Class for containing geometry and property information about GeoJSON Multi Polygons
##
## This class is mostly used for storing buildings, terrain areas, water bodies, etc.

## A class that represents a GeoJson Multipolygon geometry
class GeoJsonMultiPolygonGeometry:
	
	## The coordinates that make up multiple polygons
	var coordinates: Array[PackedVector2Array]

## The geometry of the feature
var geometry: GeoJsonMultiPolygonGeometry

## The properties of the feature
var properties: GeoJsonProperties
