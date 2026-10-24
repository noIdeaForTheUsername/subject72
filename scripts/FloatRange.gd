extends Resource
class_name FRange

@export var min: float
@export var max: float


func _init(min: float = 0.0, max: float = 0.0) -> void:
	self.min = min
	self.max = max
	adjust_values()
	

func adjust_values() -> void:
	if self.max < self.min:
		var temp := self.max
		self.max = self.min
		self.min = temp


func random() -> float:
	return randf_range(min, max)
