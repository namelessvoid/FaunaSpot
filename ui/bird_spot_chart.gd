extends Control
class_name BirdSpotChart

@export var colors: Array[Color]

var _easy_chart_scene: PackedScene = preload("res://addons/easy_charts/control_charts/chart.tscn")
var _easy_chart: Chart
var _chart_properties: ChartProperties

func set_spots(spots: Array[FSSpot]) -> void: 
	if _easy_chart:
		remove_child(_easy_chart)
		_easy_chart.queue_free()
	
	_easy_chart = _easy_chart_scene.instantiate();
	_easy_chart.set_x_domain(0, 23)
	_easy_chart.set_y_domain(0, _get_y_max(spots))
	_easy_chart.x_labels_function = _get_x_label
	_easy_chart.y_labels_function = _get_y_label
	add_child(_easy_chart)
	_easy_chart.plot(_get_plot_functions(spots), _get_chart_properties(spots))

func _get_chart_properties(spots: Array[FSSpot]) -> ChartProperties:
	var chart_properties := ChartProperties.new()
	chart_properties.colors.frame = Color("#161a1d")
	chart_properties.colors.background = Color.TRANSPARENT
	chart_properties.colors.grid = Color("#283442")
	chart_properties.colors.ticks = Color("#283442")
	chart_properties.colors.text = Color.WHITE_SMOKE
	chart_properties.draw_bounding_box = false
	chart_properties.title = "Animals spotted"
	chart_properties.x_label = "Time"
	chart_properties.y_label = "Count"
	chart_properties.max_samples = 0
	chart_properties.x_scale = 23
	chart_properties.y_scale = _get_y_max(spots)
	chart_properties.show_legend = true
	chart_properties.interactive = true
	return chart_properties

func _get_y_max(spots: Array[FSSpot]) -> int:
	var max_value = 0
	for spot in spots:
		for animal in spot.get_animals():
			var animal_count := spot.get_animal_count(animal)
			if animal_count > max_value:
				max_value = animal_count

	# Add one tick on top to get some nice spacing
	max_value += 1

	return max_value

func _get_plot_functions(spots: Array[FSSpot]) -> Array[Function]:
	var spots_by_bird_per_hour = {}
	for spot in spots:
		var date_time_dict := Time.get_datetime_dict_from_datetime_string(spot.date_time, false)
		var hour := date_time_dict["hour"] as int

		for animal in spot.get_animals():
			if !spots_by_bird_per_hour.has(animal):
				var empty_time_slots = []
				empty_time_slots.resize(24)
				empty_time_slots.fill(0)
				spots_by_bird_per_hour[animal] = empty_time_slots

			if spot.get_animal_count(animal) > spots_by_bird_per_hour[animal][hour]:
				spots_by_bird_per_hour[animal][hour] = spot.get_animal_count(animal)

	var sample_colors := colors.duplicate()
	var plot_functions: Array[Function] = []
	for animal in spots_by_bird_per_hour.keys():
		var color = sample_colors.pop_front()
		plot_functions.append(
			_bird_plot_function(animal, spots_by_bird_per_hour[animal], color)
		)
	return plot_functions

func _bird_plot_function(animal: String, spots_per_hour: Array, color: Color) -> Function:
	return Function.new(
		range(0, 24),
		spots_per_hour,
		animal,
		{
			color = color,
			marker = Function.Marker.CROSS,
			type = Function.Type.SCATTER
		}
	)

func _get_x_label(value: float) -> String:
	return "%02d" % value

func _get_y_label(value: float) -> String:
	return "%d" % value
