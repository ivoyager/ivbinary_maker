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

# We need only a few items from ivoyager, which are re-added here explicitly.
# Some 'converters' also reference a few class script constants directly.
#
# Version 0.1 generates asteroid_binaries for ivoyager 0.0.14.


const EXTENSION_NAME := "ivbinary_maker"
const EXTENSION_VERSION := "0.1"
const EXTENSION_BUILD := ""
const EXTENSION_STATE := "dev"
const EXTENSION_YMD := 20230315


func _extension_init() -> void:
	print("%s %s%s-%s %s" % [EXTENSION_NAME, EXTENSION_VERSION, EXTENSION_BUILD, EXTENSION_STATE,
			str(EXTENSION_YMD)])
	
	IVProjectBuilder.initializers.clear()
	IVProjectBuilder.prog_refs.clear()
	IVProjectBuilder.prog_nodes.clear()
	IVProjectBuilder.gui_nodes.clear()
	IVProjectBuilder.procedural_classes.clear()
	
	IVProjectBuilder.initializers._TableImporter_ = IVTableImporter
	IVProjectBuilder.prog_refs._TableReader_ = IVTableReader
	IVProjectBuilder.prog_refs._AsteroidsConverter_ = AsteroidsConverter
	IVProjectBuilder.prog_refs._RingsConverter_ = RingsConverter
	
	IVProjectBuilder.top_gui = IVFiles.make_object_or_scene(GUI)

