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
const COLOR_FILE := "color.txt"
const TRANSPARENCY_FILE := "transparency.txt"
const BACKSCATTERED_FILE := "backscattered.txt"
const FORWARDSCATTERED_FILE := "forwardscattered.txt"
const UNLITSIDE_FILE := "unlitside.txt"

# export
const EXPORT_PATH := "res://ivbinary_export/rings/saturn.rings.png"


const UNLIT_COLOR := Color(1.0, 0.97075, 0.952)


var color: Array[Color] = [] # lit side
var transparency: Array[float] = [] # inverted alpha
var backscattered: Array[float] = []
var forwardscattered: Array[float] = []
var unlitside: Array[float] = []



func convert_data() -> void:
	_read_data()
	_export_image_8bit()



func _read_data() -> void:
#	_data = [[], [], [], [], [], [], []]
	var file := FileAccess.open(SOURCE_PATH + COLOR_FILE, FileAccess.READ)
	if !file:
		print("Failed to open file for read: ", SOURCE_PATH + COLOR_FILE)
		return
	
	# color
	var file_length := file.get_length()
	while file.get_position() < file_length:
		var line: String = file.get_line()
		var values := line.split_floats("\t", false)
		color.append(Color(values[0], values[1], values[2]))
	
	# all others
	for file_name in [
			TRANSPARENCY_FILE,
			BACKSCATTERED_FILE,
			FORWARDSCATTERED_FILE,
			UNLITSIDE_FILE,
	] as Array[String]:
		file = FileAccess.open(SOURCE_PATH + file_name, FileAccess.READ)
		var array: Array[float] = get(file_name.get_basename())
		if !file:
			print("Failed to open file for read: ", SOURCE_PATH + file_name)
			return
		file_length = file.get_length()
		while file.get_position() < file_length:
			var line: String = file.get_line()
			var value := float(line)
			array.append(value)
		assert(array.size() == color.size())


func _export_image_8bit() -> void:
	var size: int = color.size()
	var image := Image.create(size, 3, false, Image.FORMAT_RGBA8)
	for i in size:
		var alpha := 1.0 - transparency[i]
		var backscattered_color := Color(color[i] * backscattered[i], alpha)
		var forwardscattered_color := Color(color[i] * forwardscattered[i], alpha)
		var unlit_color := Color(UNLIT_COLOR * unlitside[i], alpha)
		image.set_pixel(i, 0, backscattered_color)
		image.set_pixel(i, 1, forwardscattered_color)
		image.set_pixel(i, 2, unlit_color)
	
	image.save_png(EXPORT_PATH)
	status.emit("Generated texture size: " + str(image.get_size()))


