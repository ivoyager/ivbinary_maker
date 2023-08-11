# asteroids_gui.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2017-2023 Charlie Whitfield
# I, Voyager is a registered trademark of Charlie Whitfield in the US
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************************

extends GridContainer


const METHODS := [
	"add_numbered",
	"add_multiopposition",
	"revise_names",
	"revise_proper",
	"revise_trojans",
	"make_binary_files",
	"start_over",
]

const TEXTS := [
	"Add Numbered",
	"Add Multiopposition",
	"Revise Names",
	"Revise Proper Orbits",
	"Revise Trojan Orbits",
	"Make Binaries",
	"Start Over",
]

const DESCRIPTIONS := [
	"Add numbered asteroids to the pool.",
	"Add multiopposition asteroids to the pool.",
	("Revise asteroid number to number-name where available."
			+ "\n(Assumes numbered asteroids were added first above.)"),
	"Revise orbital elements to proper where available.",
	"Revise orbital elements to trojan proper where available.",
	"Make binary files from pool.",
	"Clear data and start over.",
]

var _status_labels := []

@onready var _asteroids_converter: AsteroidsConverter = IVGlobal.program.AsteroidsConverter

func _ready() -> void:
	_asteroids_converter.connect("status", Callable(self, "_on_status"))
	
	var func_type := 0
	while func_type < METHODS.size():
		var item_button := Button.new()
		item_button.connect("pressed", Callable(self, "_run_function").bind(func_type))
		item_button.text = TEXTS[func_type]
		add_child(item_button)
		var item_label := Label.new()
		item_label.text = DESCRIPTIONS[func_type]
		item_label.custom_minimum_size = Vector2(400, 50)
		item_label.valign = Label.ALIGNMENT_CENTER
		item_label.autowrap = true
		add_child(item_label)
		var status_label := Label.new()
		status_label.custom_minimum_size = Vector2(100, 50)
		status_label.valign = Label.ALIGNMENT_CENTER
		status_label.size_flags_horizontal = SIZE_EXPAND_FILL
		_status_labels.append(status_label)
		add_child(status_label)
		func_type += 1


func _run_function(func_type: int) -> void:
	_asteroids_converter.call_method(METHODS[func_type])
	if func_type == _asteroids_converter.START_OVER:
		for i in METHODS.size():
			_status_labels[func_type].text = ""


func _on_status(func_type: int, message: String) -> void:
	_status_labels[func_type].text = message


