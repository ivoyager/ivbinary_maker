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
extends Reference

# Each source value (float) is encoded as a 32-bit Color. This is overkill, but
# precission is good for value mulitiplication in the shader and the lossless
# file is only 77kb.

signal status(message)

const SOURCE_PATH := "res://source_data/rings/"
const COLOR_FILE := "color.txt"
const TRANSPARENCY_FILE := "transparency.txt"
const BACKSCATTERED_FILE := "backscattered.txt"
const FORWARDSCATTERED_FILE := "forwardscattered.txt"
const UNLITSIDE_FILE := "unlitside.txt"

const EXPORT_PATH := "res://ivbinary_export/rings/saturn.rings.png"

const BITS32MINUS1 := (1 << 32) - 1

var _data := []


func convert_data() -> void:
	_read_data()
	_export_image()


func test_image() -> void:
	_read_data()
	var texture: Texture = load(EXPORT_PATH)
	var image := texture.get_data()
	image.lock()
	var error_sum := 0.0
	for i in 7:
		for j in _data[0].size():
			error_sum += abs(_data[i][j] - float(image.get_pixel(j, i).to_rgba32()) / BITS32MINUS1)
	var feedback := "\nValues: %s\nSum of errors: %s" % [7 * _data[0].size(), error_sum]
	print(feedback)
	emit_signal("status", feedback)


func _read_data() -> void:
	_data = [[], [], [], [], [], [], []]
	var file := File.new()
	if file.open(SOURCE_PATH + COLOR_FILE, File.READ) != OK:
		print("Failed to open file for read: ", SOURCE_PATH + COLOR_FILE)
		return
	var line: String = file.get_line()
	while line and !file.eof_reached():
		var values := line.split_floats("\t", false)
		_data[0].append(values[0])
		_data[1].append(values[1])
		_data[2].append(values[2])
		line = file.get_line()
	var i := 3
	for file_name in [TRANSPARENCY_FILE, BACKSCATTERED_FILE, FORWARDSCATTERED_FILE, UNLITSIDE_FILE]:
		if file.open(SOURCE_PATH + file_name, File.READ) != OK:
			print("Failed to open file for read: ", SOURCE_PATH + file_name)
			return
		line = file.get_line()
		while line and !file.eof_reached():
			_data[i].append(float(line))
			line = file.get_line()
		i += 1
	var size: int = _data[0].size()
	assert(size == _data[3].size())
	assert(size == _data[4].size())
	assert(size == _data[5].size())
	assert(size == _data[6].size())


func _export_image() -> void:
	var size: int = _data[0].size()
	var image := Image.new()
	image.create(size, 7, false, Image.FORMAT_RGBA8)
	image.lock()
	for i in 7:
		for j in size:
			var value: float = _data[i][j]
			var int32 := int(round(value * BITS32MINUS1))
			image.set_pixel(j, i, int32)
	image.save_png(EXPORT_PATH)
	
	emit_signal("status", "Generated texture size: " + str(image.get_size()))
	
	

