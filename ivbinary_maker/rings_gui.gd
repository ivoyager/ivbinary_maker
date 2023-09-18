# rings_gui.gd
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
extends VBoxContainer

var label_text := """
Generates a *.png texture that can be used by rings.gdshader.

IMPORTANT! We don't want compression loss or other data changes! Select the
@export image in the editor and reimport with settings:

Compress Mode: Lossless
Everything else: Disabled or Off

After that, the .png and .import files can be added to ivoyager_assets/rings/.

"""

func _ready() -> void:
	($Label as Label).text = label_text
	var rings_converter: RingsConverter = IVGlobal.program.RingsConverter
	($"%Convert" as Button).pressed.connect(rings_converter.convert_data)
	($"%Test" as Button).pressed.connect(rings_converter.test_image_8bit)
	rings_converter.status.connect(($Feedback as Label).set_text)


func _on_message(message: String) -> void:
	($Feedback as Label).text = message

