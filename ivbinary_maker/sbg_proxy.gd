# sbg_proxy.gd
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
class_name SBGProxy
extends RefCounted

# A mock-up of IVSmallBodiesGroup data structure helps us generate binaries.

# *****************************************************************************
# IVSmallBodiesGroup data

var names := PackedStringArray()

# packed data
var e_i_Om_w := PackedFloat32Array() # fixed & precessing (except e in sec res)
var a_M0_n := PackedFloat32Array() # librating in l-point objects
var s_g_mag_de := PackedFloat32Array() # orbit precessions, magnitude, & e amplitude (sec res only)
var da_D_f_th0 := PackedFloat32Array() # Trojans only

# *****************************************************************************

var _index := 0


func expand_arrays(n: int, is_trojans: bool) -> void:
	var new_size := names.size() + n
	names.resize(new_size)
	e_i_Om_w.resize(new_size * 4)
	a_M0_n.resize(new_size * 3)
	s_g_mag_de.resize(new_size * 4)
	
	if is_trojans:
		da_D_f_th0.resize(new_size * 4)


func set_data(name: String, elements: Array, trojan_elements := []) -> void:
	names[_index] = name
	# elements [a, e, i, Om, w, M0, n, M, mag, s, g, de]
	
	e_i_Om_w[_index * 4] = elements[1]
	e_i_Om_w[_index * 4 + 1] = elements[2]
	e_i_Om_w[_index * 4 + 2] = elements[3]
	e_i_Om_w[_index * 4 + 3] = elements[4]
	
	a_M0_n[_index * 3] = elements[0]
	a_M0_n[_index * 3 + 1] = elements[5]
	a_M0_n[_index * 3 + 2] = elements[6]
	
	s_g_mag_de[_index * 4] = elements[9]
	s_g_mag_de[_index * 4 + 1] = elements[10]
	s_g_mag_de[_index * 4 + 2] = elements[8]
	s_g_mag_de[_index * 4 + 3] = elements[11]

	if trojan_elements:
		# [lp_float, da, D, f, th0]
		
		da_D_f_th0[_index * 4] = trojan_elements[1]
		da_D_f_th0[_index * 4 + 1] = trojan_elements[2]
		da_D_f_th0[_index * 4 + 2] = trojan_elements[3]
		da_D_f_th0[_index * 4 + 3] = trojan_elements[4]
	
	_index += 1



func write_binary(binary: FileAccess) -> void:
	var binary_data := [names, e_i_Om_w, a_M0_n, s_g_mag_de, da_D_f_th0]
	binary.store_var(binary_data)


func clear_for_import() -> void:
	names.clear()
	e_i_Om_w.clear()
	a_M0_n.clear()
	s_g_mag_de.clear()
	da_D_f_th0.clear()
	_index = 0

