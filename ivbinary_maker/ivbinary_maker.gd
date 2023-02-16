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
#
# We need only a few items from ivoyager, which are added here or used directly
# in 'converter' classes.


const EXTENSION_NAME := "ivbinary_maker"
const EXTENSION_VERSION := "0.0.1-DEV"
const EXTENSION_VERSION_YMD := 20230216


func _extension_init() -> void:
	prints(EXTENSION_NAME, EXTENSION_VERSION, EXTENSION_VERSION_YMD)

	IVGlobal.connect("project_objects_instantiated", self, "_on_project_objects_instantiated")
	
	IVProjectBuilder.prog_builders.clear()
	IVProjectBuilder.prog_nodes.clear()
	IVProjectBuilder.procedural_classes.clear()
	
	IVProjectBuilder.initializers = {
		_TableImporter_ = IVTableImporter,
	}
	
	IVProjectBuilder.prog_refs = {
		_TableReader_ = IVTableReader,
	}
	
	IVProjectBuilder.gui_nodes = {
		_ProjectGUI_ = GUI,
	}




func _on_project_objects_instantiated() -> void:
	pass


