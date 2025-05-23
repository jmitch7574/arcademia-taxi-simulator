class_name GeoJsonPoint
## A class containing information about GeoJSON point features
##
## This class basically went unused in the Arcademia release (the only GeoJSON point used was the spawn point)
## Could be used for storing information on benches, traffic lights etc.

## Class for storing GeoJSON point geometry
class GeoJsonPointGeometry:
	## The coordinates that represent the point
	var coordinates: Vector2 
	
## The Geometry of the feature
var geometry: GeoJsonPointGeometry 

## The properties of the feature
var properties: GeoJsonProperties 
