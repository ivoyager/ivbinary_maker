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

signal status(message)

const SOURCE_PATH := "res://source_data/rings/"
const COLOR_FILE := "color.txt"
const TRANSPARENCY_FILE := "transparency.txt"
const BACKSCATTERED_FILE := "backscattered.txt"
const FORWARDSCATTERED_FILE := "forwardscattered.txt"
const UNLITSIDE_FILE := "unlitside.txt"

const EXPORT_PATH := "res://ivbinary_export/rings/saturn.rings.png"


var _data := []

var _data1 := []
var _data2 := []


func convert_data() -> void:
	_read_data()
	_export_image()


func test_image() -> void:
	_read_data()
	var texture: Texture = load(EXPORT_PATH)
	var image := texture.get_data()
	image.lock()
	for i in range(3000, 4000):
		prints(_data2[i] - image.get_pixel(i, 1))
	print(texture)
	emit_signal("status", "test")


func _read_data() -> void:
	var file := File.new()
	if file.open(SOURCE_PATH + COLOR_FILE, File.READ) != OK:
		print("Failed to open file for read: ", SOURCE_PATH + COLOR_FILE)
		return
	var line: String = file.get_line()
	while line and !file.eof_reached():
		var values := line.split_floats("\t", false)
		var color := Color(values[0], values[1], values[2])
		_data1.append(color)
		line = file.get_line()
		if !line:
			break
	var size := _data1.size()
	var i := 0
	file.open(SOURCE_PATH + TRANSPARENCY_FILE, File.READ)
	line = file.get_line()
	while line and !file.eof_reached():
		var value := float(line)
		_data1[i][3] = value
		i += 1
		line = file.get_line()
	assert(i == size)
	_data2.resize(size)
	_data2.fill(Color())
	var j := 0
	for file_name in [BACKSCATTERED_FILE, FORWARDSCATTERED_FILE, UNLITSIDE_FILE]:
		i = 0
		file.open(SOURCE_PATH + file_name, File.READ)
		line = file.get_line()
		while line and !file.eof_reached():
			var value := float(line)
			_data2[i][j] = value
			i += 1
			line = file.get_line()
		assert(i == size)
		j += 1
	

func _export_image() -> void:
	var size := _data1.size()
	var image := Image.new()
	image.create(size, 2, false, Image.FORMAT_RGBA8)
	image.lock()
	for i in size:
		image.set_pixel(i, 0, _data1[i])
		image.set_pixel(i, 1, _data2[i])

	image.save_png(EXPORT_PATH)
	
	emit_signal("status", "Generated texture size: " + str(image.get_size()))
	
	

