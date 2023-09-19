# rings_converter.gd
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
class_name RingsConverter
extends RefCounted

# Data files from https://bjj.mmedia.is/data/s_rings/.

signal status(message)

# import
const SOURCE_PATH := "res://source_data/rings/"
const BACKSCATTERED_FILE := "backscattered.txt"
const FORWARDSCATTERED_FILE := "forwardscattered.txt"
const UNLITSIDE_FILE := "unlitside.txt"
const TRANSPARENCY_FILE := "transparency.txt"
const COLOR_FILE := "color.txt"
const FLIP_TRANSPARENCY := true # set true if '1' means full transparency

# export
const EXPORT_PATH := "res://ivbinary_export/rings/saturn.rings.png"


const BITS32MINUS1 := (1 << 32) - 1

var _data: Array[Array] = []


func convert_data() -> void:
	_read_data()
	_export_image_8bit()


func test_image_8bit() -> void:
	_read_data()
	var texture: Texture2D = load(EXPORT_PATH)
	var image := texture.get_image()
#	false # image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	var error := 0.0
	for j in _data[0].size():
		var color1 := image.get_pixel(j, 0)
		var color2 := image.get_pixel(j, 1)
		error += abs(_data[0][j] - color1[0])
		error += abs(_data[1][j] - color1[1])
		error += abs(_data[2][j] - color1[2])
		error += abs(_data[3][j] - color1[3])
		error += abs(_data[4][j] - color2[0])
		error += abs(_data[5][j] - color2[1])
		error += abs(_data[6][j] - color2[2])
	error /= _data[0].size() * 7.0
	error *= 100.0 # percent
	
	var feedback := "\nValues: %s\nAverage error: %s%%" % [7 * _data[0].size(), error]
	print(feedback)
	emit_signal("status", feedback)


func test_image_32bit() -> void:
	_read_data()
	var texture: Texture2D = load(EXPORT_PATH)
	var image := texture.get_image()
#	false # image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	var error_sum := 0.0
	for i in 7:
		for j in _data[0].size():
			error_sum += abs(_data[i][j] - float(image.get_pixel(j, i).to_rgba32()) / BITS32MINUS1)
	var feedback := "\nValues: %s\nSum of errors: %s" % [7 * _data[0].size(), error_sum]
	print(feedback)
	status.emit(feedback)


func _read_data() -> void:
	_data = [[], [], [], [], [], [], []]
	var file := FileAccess.open(SOURCE_PATH + COLOR_FILE, FileAccess.READ)
	if !file:
		print("Failed to open file for read: ", SOURCE_PATH + COLOR_FILE)
		return
	var line: String = file.get_line()
	while line and !file.eof_reached():
		var values := line.split_floats("\t", false)
		_data[4].append(values[0])
		_data[5].append(values[1])
		_data[6].append(values[2])
		line = file.get_line()
	var i := 0
	for file_name in [BACKSCATTERED_FILE, FORWARDSCATTERED_FILE, UNLITSIDE_FILE, TRANSPARENCY_FILE]:
		file = FileAccess.open(SOURCE_PATH + file_name, FileAccess.READ)
		if !file:
			print("Failed to open file for read: ", SOURCE_PATH + file_name)
			return
		var flip_value: bool = FLIP_TRANSPARENCY and file_name == TRANSPARENCY_FILE
		line = file.get_line()
		while line and !file.eof_reached():
			var value := float(line)
			if flip_value:
				value = 1.0 - value
			_data[i].append(value)
			line = file.get_line()
		i += 1
	var size: int = _data[0].size()
	assert(size == _data[1].size())
	assert(size == _data[2].size())
	assert(size == _data[3].size())
	assert(size == _data[4].size())
	assert(size == _data[5].size())
	assert(size == _data[6].size())


func _export_image_8bit() -> void:
	# I'd prefer 16-bit given the value multiplications in shader...
	var size: int = _data[0].size()
	var image := Image.create(size, 2, false, Image.FORMAT_RGBA8)
#	image.create(size, 2, false, Image.FORMAT_RGBA8)
#	false # image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	for j in size:
		var color1 := Color(_data[0][j], _data[1][j], _data[2][j], _data[3][j])
		var color2 := Color(_data[4][j], _data[5][j], _data[6][j])
		image.set_pixel(j, 0, color1)
		image.set_pixel(j, 1, color2)
	image.save_png(EXPORT_PATH)
	status.emit("Generated texture size: " + str(image.get_size()))


func _export_image_32bit() -> void:
	# NOT IMPLEMENTED.
	# We would need usampler2D in the shader (which isn't supported in GLES2)
	# or recode each float as four (8-bit) floats.
	var size: int = _data[0].size()
	var image := Image.create(size, 7, false, Image.FORMAT_RGBA8)
#	image.create(size, 7, false, Image.FORMAT_RGBA8)
#	false # image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	for i in 7:
		for j in size:
			var value: float = _data[i][j]
			var int32 := int(round(value * BITS32MINUS1))
			image.set_pixel(j, i, int32)
	image.save_png(EXPORT_PATH)
	status.emit("Generated texture size: " + str(image.get_size()))

