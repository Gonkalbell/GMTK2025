class_name Util extends Object

static func segment_curve_intersect3d(from: Vector3, to: Vector3, points: PackedVector3Array) -> Variant:
	for i in points.size() - 1:
		var closest_points: PackedVector3Array = Geometry3D.get_closest_points_between_segments(from, to, points[i], points[ i+ 1])
		var distance_sqr: float = closest_points[0].distance_squared_to(closest_points[1])

		# TODO: I'm worried this could return false negatives. I don't want to use the actual
		# formula for 3d line segment intersection because that'll miss segments that come close to
		# touching but barely miss. Maybe instead I can see if the segment intersects a plane
		# defined by from, to, and an up_vector?
		if distance_sqr < from.distance_squared_to(to) / 2:
			return {
				"point": closest_points[1],
				"index": i,
			}

	return null

static func random_point_on_fibonacci_sphere(samples = 100) -> Vector3:
	const golden_angle = PI * (3 - sqrt(5))
	var r = float(randi_range(0, samples - 1))
	var y = lerp(-1, 1, r / samples)
	var radius = sqrt(1 - y * y)
	var theta = r * golden_angle
	var x = cos(theta) * radius
	var z = sin(theta) * radius
	return Vector3(x, y, z)
