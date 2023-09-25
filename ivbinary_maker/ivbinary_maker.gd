# ivbinary_maker.gd
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

# v0.1 exports data for ivoyager v0.0.14 - 15 (Godot 3.x).
# v0.2 exports data for ivoyager v0.0.16 - (Godot 4.x).


const EXTENSION_NAME := "ivbinary_maker"
const EXTENSION_VERSION := "0.2"
const EXTENSION_BUILD := ""
const EXTENSION_STATE := "dev"
const EXTENSION_YMD := 20230925


func _extension_init() -> void:
	print("%s %s%s-%s %s" % [EXTENSION_NAME, EXTENSION_VERSION, EXTENSION_BUILD, EXTENSION_STATE,
			str(EXTENSION_YMD)])
	
	# Clear everything and add what we need.
	IVProjectBuilder.initializers.clear()
	IVProjectBuilder.program_refcounteds.clear()
	IVProjectBuilder.program_nodes.clear()
	IVProjectBuilder.gui_nodes.clear()
	IVProjectBuilder.procedural_objects.clear()
	IVProjectBuilder.initializers[&"TableInitializer"] = IVTableInitializer
	
	# ivbinary_maker
	IVProjectBuilder.program_refcounteds[&"_AsteroidsConverter_"] = AsteroidsConverter
	IVProjectBuilder.program_refcounteds[&"_RingsConverter_"] = RingsConverter
	IVProjectBuilder.top_gui = IVFiles.make_object_or_scene(GUI)

