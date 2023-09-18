# group_proxy.gd
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
class_name GroupProxy
extends RefCounted

# A mock-up of IVSmallBodiesGroup data structure helps us generate binaries.

# *****************************************************************************
# IVSmallBodiesGroup data

var names := PackedStringArray()
var magnitudes := PackedFloat32Array()

var e_i_Om_w := PackedColorArray() # fixed & precessing (e librates for secular resonance)
var a_M0_n := PackedVector3Array() # librating in l-point objects
var s_g := PackedVector2Array() # orbit precessions
var da_D_f := PackedVector3Array() # Trojans: a amplitude, relative L amplitude, and frequency
var th0_de := PackedVector2Array() # Trojans: libration at epoch [, & sec res: e amplitude]


# *****************************************************************************

var _index := 0
#var _maxes := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
#var _mins := [INF, INF, INF, INF, INF, INF, INF, INF, INF]
#var _load_count := 0


func expand_arrays(n: int, is_trojans: bool) -> void:
	var new_size := names.size() + n
	names.resize(new_size)
	magnitudes.resize(new_size)
	e_i_Om_w.resize(new_size)
	a_M0_n.resize(new_size)
	s_g.resize(new_size)
	if is_trojans:
		da_D_f.resize(new_size)
		th0_de.resize(new_size)


func set_data(name: String, elements: Array, trojan_elements := []) -> void:
	names[_index] = name
	# elements [a, e, i, Om, w, M0, n, M, mag, s, g, de]
	magnitudes[_index] = elements[8]
	e_i_Om_w[_index] = Color(
		elements[1],
		elements[2],
		elements[3],
		elements[4]
	)
	a_M0_n[_index] = Vector3(
		elements[0],
		elements[5],
		elements[6]
	)
	s_g[_index] = Vector2(
		elements[9],
		elements[10]
	)
	if trojan_elements:
		# [lp_float, da, D, f, th0]
		da_D_f[_index] = Vector3(
			trojan_elements[1],
			trojan_elements[2],
			trojan_elements[3]
		)
		th0_de[_index] = Vector2(
			trojan_elements[4],
			0.0
		)
	_index += 1



func write_binary(binary: FileAccess) -> void:
	var binary_data := [names, magnitudes, e_i_Om_w, a_M0_n, s_g, da_D_f, th0_de]
	binary.store_var(binary_data)


func clear_for_import() -> void:
	names.resize(0)
	magnitudes.resize(0)
	e_i_Om_w.resize(0)
	a_M0_n.resize(0)
	s_g.resize(0)
	da_D_f.resize(0)
	th0_de.resize(0)
	_index = 0

