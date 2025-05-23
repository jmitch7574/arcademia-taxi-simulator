class_name GenerationExtras

static func deg2rad(deg: float) -> float:
	return deg * PI / 180.0

const EARTH_RADIUS = 6370997.0

static func project_ortho(lat_deg: float, lon_deg: float, lat0_deg: float, lon0_deg: float, radius: float = EARTH_RADIUS) -> Vector2:
	var lat = deg2rad(lat_deg)
	var lon = deg2rad(lon_deg)
	var lat0 = deg2rad(lat0_deg)
	var lon0 = deg2rad(lon0_deg)

	var cos_c = sin(lat0) * sin(lat) + cos(lat0) * cos(lat) * cos(lon - lon0)
	if cos_c <= 0:
		return Vector2(INF, INF)
	var x = radius * cos(lat) * sin(lon - lon0)
	var y = radius * (cos(lat0) * sin(lat) - sin(lat0) * cos(lat) * cos(lon - lon0))
	return Vector2(roundf(x * 1000) / 1000, roundf(-y * 1000) / 1000)
