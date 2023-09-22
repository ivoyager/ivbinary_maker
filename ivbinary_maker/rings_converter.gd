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
const EXPORT_PREFIX := "res://ivbinary_export/rings/saturn.rings"



const UNLIT_COLOR := Color(1.0, 0.97075, 0.952)
const FORWARD_REDSHIFT := 0.05
const END_PADDING := 0.05 # saved image is 10% bigger


var color: Array[Color] = [] # lit side
var transparency: Array[float] = [] # inverted alpha
var backscattered: Array[float] = []
var forwardscattered: Array[float] = []
var unlitside: Array[float] = []



func convert_data() -> void:
	_read_data()
	_export_images()



func _read_data() -> void:
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


func _export_images() -> void:
	var image_width: int = color.size()
	var padding := roundi(END_PADDING * image_width)
	var texture_width := image_width + 2 * padding
	var backscattered_image := Image.create(texture_width, 2, true, Image.FORMAT_RGBA8)
	var forwardscattered_image := Image.create(texture_width, 2, true, Image.FORMAT_RGBA8)
	var unlitside_image := Image.create(texture_width, 2, true, Image.FORMAT_RGBA8)
	var texel_pos := 0
	for i in padding:
		backscattered_image.set_pixel(texel_pos, 0, Color(0.0, 0.0, 0.0, 0.0))
		backscattered_image.set_pixel(texel_pos, 1, Color(0.0, 0.0, 0.0, 0.0))
		forwardscattered_image.set_pixel(texel_pos, 0, Color(0.0, 0.0, 0.0, 0.0))
		forwardscattered_image.set_pixel(texel_pos, 1, Color(0.0, 0.0, 0.0, 0.0))
		unlitside_image.set_pixel(texel_pos, 0, Color(0.0, 0.0, 0.0, 0.0))
		unlitside_image.set_pixel(texel_pos, 1, Color(0.0, 0.0, 0.0, 0.0))
		texel_pos += 1
	for i in image_width:
		var alpha := 1.0 - transparency[i]
		var backscattered_color := Color(color[i] * backscattered[i], alpha)
		var forwardscattered_color := Color(color[i] * forwardscattered[i], alpha)
#		forwardscattered_color = _redshift_forwardscattered(forwardscattered_color)
		var unlit_color := Color(UNLIT_COLOR * unlitside[i], alpha)
		backscattered_image.set_pixel(texel_pos, 0, backscattered_color)
		backscattered_image.set_pixel(texel_pos, 1, backscattered_color)
		forwardscattered_image.set_pixel(texel_pos, 0, forwardscattered_color)
		forwardscattered_image.set_pixel(texel_pos, 1, forwardscattered_color)
		unlitside_image.set_pixel(texel_pos, 0, unlit_color)
		unlitside_image.set_pixel(texel_pos, 1, unlit_color)
		texel_pos += 1
	for i in padding:
		backscattered_image.set_pixel(texel_pos, 0, Color(0.0, 0.0, 0.0, 0.0))
		backscattered_image.set_pixel(texel_pos, 1, Color(0.0, 0.0, 0.0, 0.0))
		forwardscattered_image.set_pixel(texel_pos, 0, Color(0.0, 0.0, 0.0, 0.0))
		forwardscattered_image.set_pixel(texel_pos, 1, Color(0.0, 0.0, 0.0, 0.0))
		unlitside_image.set_pixel(texel_pos, 0, Color(0.0, 0.0, 0.0, 0.0))
		unlitside_image.set_pixel(texel_pos, 1, Color(0.0, 0.0, 0.0, 0.0))
		texel_pos += 1

	# Saved Texture2DArray is not recognized by editor importer!
#	const EXPORT_PATH := "res://ivbinary_export/rings/saturn.rings.res"
#	var array := [backscattered_image, forwardscattered_image, unlitside_image] as Array[Image]
#	var texture_array := Texture2DArray.new()
#	texture_array.create_from_images(array)
#	print(ResourceSaver.get_recognized_extensions(texture_array))
#	ResourceSaver.save(texture_array, EXPORT_PATH, ResourceSaver.FLAG_COMPRESS)

	backscattered_image.save_png(EXPORT_PREFIX + ".backscatter.png")
	forwardscattered_image.save_png(EXPORT_PREFIX + ".forwardscatter.png")
	unlitside_image.save_png(EXPORT_PREFIX + ".unlitside.png")
	
	status.emit("Generated 3 rings textures of width %s (%s padding + %s rings image + %s padding)"
			% [texture_width, padding, image_width, padding])


