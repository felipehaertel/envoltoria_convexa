extends Node2D

@export var num_points := 20
@export var point_radius := 5.0

var points: Array[Vector2] = []
var hull: Array[Vector2] = []

func _ready():
	randomize()
	export_data()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		points.append(event.position)
		update_hull()
		queue_redraw()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				generate_random_points()
			KEY_C:
				generate_circle()
			KEY_T:
				generate_triangle()
			KEY_B:
				generate_rectangle()
			KEY_X:
				clear_points()

# ======================= FUNÇÕES DE DESENHO ============================
func _draw():
	# desenha pontos
	for p in points:
		draw_circle(p, point_radius, Color.BLUE)
	# desenha envoltória convexa
	if hull.size() >= 2:
		for i in range(hull.size()):
			var a = hull[i]
			var b = hull[(i + 1) % hull.size()]
			draw_line(a, b, Color.RED, 2.0)

func clear_points():
	points.clear()
	hull.clear()
	queue_redraw()

# ======================= FUNÇÃO AUXILIAR CROSS =========================
func cross(o: Vector2, a: Vector2, b: Vector2) -> float:
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)

# ======================= ALGORITMO: GRAHAM SCAN =======================
func convex_hull(pts: Array[Vector2]) -> Array[Vector2]:
	if pts.size() < 3:
		return pts.duplicate()

	var sorted = pts.duplicate()
	
	# Ordena por X e depois por Y
	sorted.sort_custom(self._compare_points)
	#sorted.sort_custom(func(a, b):
		#if a.x == b.x:
			#return a.y < b.y
		#return a.x < b.x
	#)

	var lower: Array[Vector2] = []
	for p in sorted:
		while lower.size() >= 2 and cross(lower[-2], lower[-1], p) <= 0:
			lower.pop_back()
		lower.append(p)

	var upper: Array[Vector2] = []
	for i in range(sorted.size() - 1, -1, -1):
		var p = sorted[i]
		while upper.size() >= 2 and cross(upper[-2], upper[-1], p) <= 0:
			upper.pop_back()
		upper.append(p)

	upper.pop_back()
	lower.pop_back()
	return lower + upper

func update_hull():
	hull = convex_hull(points)
	queue_redraw()
	
#func export_data(file_path: String = "user://points.csv"):
	#var file = FileAccess.open(file_path, FileAccess.WRITE)
	#if not file:
		#print("Erro ao abrir arquivo para escrita: ", file_path)
		#return
#
	#file.store_line("x,y,is_hull,elapsed_ms,n_points")  # cabeçalho
#
	#var n_points = points.size()
	#var t0 = Time.get_ticks_msec()
	#hull = convex_hull(points)
	#var elapsed = Time.get_ticks_msec() - t0
#
	#for p in points:
		#var is_hull = "1" if hull.has(p) else "0"
		#file.store_line("%f,%f,%s,%d,%d" % [p.x, p.y, is_hull, elapsed, n_points])
#
	#file.close()
	#print("Dados exportados para ", file_path)
	
func export_data(file_path: String = "user://points.csv"):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("Erro ao abrir arquivo para escrita: ", file_path)
		return

	file.store_line("x,y,is_hull,elapsed_ms,n_points,n_hull,n_inside,density")

	if points.size() == 0:
		print("Nenhum ponto para exportar!")
		return

	var n_points = points.size()
	var t0 = Time.get_ticks_msec()
	hull = convex_hull(points)
	var elapsed = Time.get_ticks_msec() - t0
	var n_hull = hull.size()
	var n_inside = n_points - n_hull
	var density = float(n_inside) / n_points

	for p in points:
		var is_hull = "1" if hull.has(p) else "0"
		file.store_line("%f,%f,%s,%d,%d,%d,%d,%f" % [p.x, p.y, is_hull, elapsed, n_points, n_hull, n_inside, density])

	file.close()
	print("Dados exportados para ", ProjectSettings.globalize_path(file_path))

func _compare_points(a: Vector2, b: Vector2) -> bool:
	if a.x == b.x:
		return a.y < b.y
	return a.x < b.x

# ======================= GERAÇÃO DE PONTOS ============================
func generate_random_points():
	points.clear()
	var w = get_viewport_rect().size.x
	var h = get_viewport_rect().size.y
	for i in range(num_points):
		points.append(Vector2(randf() * w, randf() * h))
	update_hull()
	queue_redraw()

func generate_circle():
	points.clear()
	var center = get_viewport_rect().size / 2
	var radius = min(center.x, center.y) / 2
	for i in range(num_points):
		var angle = 2 * PI * float(i) / num_points
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	update_hull()
	queue_redraw()

func generate_rectangle():
	points.clear()
	var rect_size = get_viewport_rect().size * 0.5
	var center = get_viewport_rect().size / 2
	var half = rect_size / 2
	var corners = [
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y)
	]
	# Distribui pontos nas bordas
	for i in range(num_points):
		var edge = i % 4
		var t = float(i % int(num_points / 4)) / (num_points / 4)
		if edge == 0:
			points.append(Vector2(corners[0].x + t * (corners[1].x - corners[0].x), corners[0].y))
		elif edge == 1:
			points.append(Vector2(corners[1].x, corners[1].y + t * (corners[2].y - corners[1].y)))
		elif edge == 2:
			points.append(Vector2(corners[2].x - t * (corners[2].x - corners[3].x), corners[2].y))
		else:
			points.append(Vector2(corners[3].x, corners[3].y - t * (corners[3].y - corners[0].y)))
	update_hull()
	queue_redraw()

func generate_triangle():
	points.clear()
	var center = get_viewport_rect().size / 2
	var r = min(center.x, center.y) / 2
	var vertices = [
		center + Vector2(0, -r),
		center + Vector2(-r * sin(PI / 3), r * cos(PI / 3)),
		center + Vector2(r * sin(PI / 3), r * cos(PI / 3))
	]
	for i in range(num_points):
		var edge = i % 3
		var t = float(i % int(num_points / 3)) / (num_points / 3)
		points.append(vertices[edge].lerp(vertices[(edge + 1) % 3], t))
	update_hull()
	queue_redraw()
