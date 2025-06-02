class_name NamedBuilding
extends CSGPolygon3D

var center : Vector3
var building_name : String

func get_closest_point(target: Vector3) -> Vector3:
	var closest_dist = INF
	var closest_vec = Vector3(0, 0, 0)
	
	for point in polygon:
		var mapped_poly = Vector3(point.x, 0, point.y)  + Vector3(-FileLoader.bbox[2] / 2, -5,  -FileLoader.bbox[3] / 2)
		if target.distance_to(mapped_poly) < closest_dist:
			closest_dist = target.distance_to(mapped_poly)
			closest_vec = mapped_poly
	
	return closest_vec
