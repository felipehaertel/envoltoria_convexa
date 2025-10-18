extends Node2D

# Configurações de exportação
@export var initial_num_points := 20
@export var point_radius := 5.0
@export var analysis_output_file := "user://complexity_analysis.csv"
@export var points_output_file := "user://last_points_export.csv"

var points: Array[Vector2] = []
var hull: Array[Vector2] = []


func _ready():
	randomize()
	# Gera pontos iniciais na tela
	generate_random_points(initial_num_points)
	
	run_complexity_analysis()
	print("Análise de complexidade gerada em: ", ProjectSettings.globalize_path(analysis_output_file))


func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		points.append(event.position)
		update_hull()
		export_data(points_output_file) # Exporta dados do conjunto atual
		queue_redraw()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				generate_random_points(initial_num_points)
				export_data(points_output_file)
			KEY_C:
				generate_circle(initial_num_points)
				export_data(points_output_file)
			KEY_T:
				generate_triangle(initial_num_points)
				export_data(points_output_file)
			KEY_B:
				generate_rectangle(initial_num_points)
				export_data(points_output_file)
			KEY_X:
				clear_points()
			KEY_A:
				# Roda a análise de complexidade novamente
				run_complexity_analysis()
				print("Análise de complexidade RE-GERADA em: ", ProjectSettings.globalize_path(analysis_output_file))


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
		
		# Desenha o primeiro ponto com cor diferente
		draw_circle(hull[0], point_radius * 1.5, Color.GREEN)

func clear_points():
	points.clear()
	hull.clear()
	queue_redraw()


func cross(o: Vector2, a: Vector2, b: Vector2) -> float:
	"""Calcula o produto cruzado 2D (vetorial) para determinar a direção de virada."""
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)


func convex_hull(pts: Array[Vector2]) -> Array[Vector2]:
	"""Implementa o algoritmo Monotone Chain para encontrar a envoltória convexa."""
	if pts.size() < 3:
		return pts.duplicate()

	var sorted = pts.duplicate()
	# Ordena por X e depois por Y (usando a função de comparação auxiliar)
	sorted.sort_custom(self._compare_points)

	# Constrói o envelope inferior
	var lower: Array[Vector2] = []
	for p in sorted:
		while lower.size() >= 2 and cross(lower[-2], lower[-1], p) <= 0:
			lower.pop_back()
		lower.append(p)

	# Constrói o envelope superior
	var upper: Array[Vector2] = []
	for i in range(sorted.size() - 1, -1, -1):
		var p = sorted[i]
		while upper.size() >= 2 and cross(upper[-2], upper[-1], p) <= 0:
			upper.pop_back()
		upper.append(p)

	# Remove o último ponto de cada envelope
	if upper.size() > 0: upper.pop_back()
	if lower.size() > 0: lower.pop_back()
	
	# O hull final é a concatenação
	return lower + upper

func update_hull():
	hull = convex_hull(points)
	queue_redraw()
	
func _compare_points(a: Vector2, b: Vector2) -> bool:
	"""Função auxiliar para ordenação de pontos: primeiro X, depois Y."""
	if a.x == b.x:
		return a.y < b.y
	return a.x < b.x


func generate_random_points(count: int):
	points.clear()
	var w = get_viewport_rect().size.x
	var h = get_viewport_rect().size.y
	for i in range(count):
		points.append(Vector2(randf() * w, randf() * h))
	update_hull()
	queue_redraw()

func generate_circle(count: int):
	points.clear()
	var center = get_viewport_rect().size / 2
	var radius = min(center.x, center.y) / 2
	for i in range(count):
		var angle = 2 * PI * float(i) / count
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	update_hull()
	queue_redraw()

func generate_rectangle(count: int):
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
	var total_perimeter = 2 * (rect_size.x + rect_size.y)
	var segment_length = total_perimeter / count
	
	for i in range(count):
		var edge = i % 4
		var t = float(i) / count # Proporção
		# Lógica de distribuição simplificada para cobrir as bordas (pode ser melhorada, mas funciona)
		var p1: Vector2
		var p2: Vector2
		if i < count / 4.0:
			p1 = corners[0]
			p2 = corners[1]
			t = (float(i) / count) * 4.0
		elif i < count / 2.0:
			p1 = corners[1]
			p2 = corners[2]
			t = ((float(i) - count / 4.0) / count) * 4.0
		elif i < 3 * count / 4.0:
			p1 = corners[2]
			p2 = corners[3]
			t = ((float(i) - count / 2.0) / count) * 4.0
		else:
			p1 = corners[3]
			p2 = corners[0]
			t = ((float(i) - 3 * count / 4.0) / count) * 4.0
			
		points.append(p1.lerp(p2, t))
	update_hull()
	queue_redraw()

func generate_triangle(count: int):
	points.clear()
	var center = get_viewport_rect().size / 2
	var r = min(center.x, center.y) / 2
	var vertices = [
		center + Vector2(0, -r),
		center + Vector2(-r * sin(PI / 3), r * cos(PI / 3)),
		center + Vector2(r * sin(PI / 3), r * cos(PI / 3))
	]
	
	for i in range(count):
		var edge = i % 3
		var t = float(i % int(count / 3)) / (count / 3.0)
		points.append(vertices[edge].lerp(vertices[(edge + 1) % 3], t))
	update_hull()
	queue_redraw()



func export_data(file_path: String = "user://last_points_export.csv"):
	"""
	Exporta os dados detalhados do CONJUNTO DE PONTOS atual, 
	incluindo o custo da última computação.
	
	Saída CSV: x, y, is_hull, elapsed_ms, n_points, n_hull, n_inside, density
	"""
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("Erro ao abrir arquivo para escrita: ", file_path)
		return

	# CABEÇALHO
	file.store_line("x,y,is_hull,elapsed_ms,n_points,n_hull,n_inside,density")

	if points.size() == 0:
		print("Nenhum ponto para exportar!")
		file.close()
		return

	var n_points = points.size()
	
	# Medição do custo computacional
	var t0 = Time.get_ticks_msec()
	# Recalcula o hull (garante que o tempo medido é preciso)
	var current_hull = convex_hull(points) 
	var elapsed = Time.get_ticks_msec() - t0
	
	var n_hull = current_hull.size()
	var n_inside = n_points - n_hull
	var density = float(n_inside) / n_points # Densidade de pontos internos (0 a 1)
	
	# Linhas de Dados
	for p in points:
		var is_hull = "1" if current_hull.has(p) else "0"
		var line = "%f,%f,%s,%d,%d,%d,%d,%f" % [p.x, p.y, is_hull, elapsed, n_points, n_hull, n_inside, density]
		file.store_line(line)

	file.close()
	print("Dados do conjunto de pontos exportados para: ", ProjectSettings.globalize_path(file_path))


func run_complexity_analysis():
	"""
	Realiza uma análise de complexidade gerando conjuntos de pontos 
	crescentes e medindo o tempo de execução.
	
	Exporta os resultados resumidos para 'complexity_analysis.csv'.
	"""
	
	var analysis_points_counts = [10, 50, 100, 200, 500, 1000, 2000, 5000, 10000]
	var results: Array[Dictionary] = []
	
	print("Iniciando análise de complexidade...")

	# Abre o arquivo de análise de complexidade
	var file = FileAccess.open(analysis_output_file, FileAccess.WRITE)
	if not file:
		print("Erro ao abrir arquivo para análise: ", analysis_output_file)
		return

	# CABEÇALHO para Análise de Crescimento
	file.store_line("n_points,time_ms_random,n_hull_random,density_random,time_ms_circle,n_hull_circle")

	for n in analysis_points_counts:
		var result = {"n_points": n}
		
		# --- Teste 1: Pontos Aleatórios (Caso Típico: n_hull << n) ---
		
		# 1. Gera e calcula o Hull
		var w = get_viewport_rect().size.x
		var h = get_viewport_rect().size.y
		var temp_points_random: Array[Vector2] = []
		for i in range(n):
			temp_points_random.append(Vector2(randf() * w, randf() * h))

		var t0_random = Time.get_ticks_msec()
		var hull_random = convex_hull(temp_points_random)
		var elapsed_random = Time.get_ticks_msec() - t0_random
		
		result.time_ms_random = elapsed_random
		result.n_hull_random = hull_random.size()
		result.density_random = float(n - hull_random.size()) / n
		
		# --- Teste 2: Pontos em Círculo (Caso Extremo: n_hull == n) ---

		# 1. Gera e calcula o Hull
		var center = get_viewport_rect().size / 2
		var radius = min(center.x, center.y) / 2
		var temp_points_circle: Array[Vector2] = []
		for i in range(n):
			var angle = 2 * PI * float(i) / n
			temp_points_circle.append(center + Vector2(cos(angle), sin(angle)) * radius)

		var t0_circle = Time.get_ticks_msec()
		var hull_circle = convex_hull(temp_points_circle)
		var elapsed_circle = Time.get_ticks_msec() - t0_circle
		
		result.time_ms_circle = elapsed_circle
		result.n_hull_circle = hull_circle.size()
		
		results.append(result)
		
		# Escreve a linha de resultado resumido
		var line = "%d,%d,%d,%f,%d,%d" % [
			n,
			result.time_ms_random,
			result.n_hull_random,
			result.density_random,
			result.time_ms_circle,
			result.n_hull_circle
		]
		file.store_line(line)
		
		print("Processado N=%d. Tempo (Random): %d ms, Tempo (Circle): %d ms" % [n, elapsed_random, elapsed_circle])


	file.close()
	print("Análise de complexidade concluída e salva.")
	
# --- Exportação JSON (Adicional) ---

func export_json(file_path: String = "user://last_points_export.json"):
	"""Exporta os dados detalhados do conjunto de pontos atual para JSON."""
	if points.size() == 0:
		print("Nenhum ponto para exportar em JSON!")
		return
	
	# Medição do custo computacional
	var n_points = points.size()
	var t0 = Time.get_ticks_msec()
	var current_hull = convex_hull(points) 
	var elapsed = Time.get_ticks_msec() - t0
	
	var n_hull = current_hull.size()
	var n_inside = n_points - n_hull
	var density = float(n_inside) / n_points 
	
	var export_data_list = []
	for p in points:
		export_data_list.append({
			"x": p.x,
			"y": p.y,
			"is_hull": current_hull.has(p),
		})
		
	var final_json = {
		"metadata": {
			"n_points": n_points,
			"n_hull": n_hull,
			"n_inside": n_inside,
			"density": density,
			"elapsed_ms": elapsed
		},
		"points": export_data_list
	}

	var json_string = JSON.stringify(final_json, "\t")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Dados exportados para JSON em: ", ProjectSettings.globalize_path(file_path))
	else:
		print("Erro ao abrir arquivo JSON para escrita: ", file_path)
