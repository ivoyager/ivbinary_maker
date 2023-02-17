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
extends Reference

# A mock-up of IVSmallBodiesGroup data structure helps us generate binaries.

# *****************************************************************************
# IVSmallBodiesGroup data

# below is binary import data
var names := PoolStringArray()
var iau_numbers := PoolIntArray() # DEPRECIATE
var magnitudes := PoolRealArray()

# WIP restructure
var e_i_Om_w := PoolColorArray() # common (e librates for secular resonance)
var a_M0_n := PoolVector3Array() # librating in l-point objects
var s_g := PoolVector2Array() # orbit precessions
var da_D_f := PoolVector3Array() # Trojans: a, L ampltude, and frequency
var th0_de := PoolVector2Array() # libration angle at epoch [, e amplitude for sec res]
# end WIP restructure


var dummy_translations := PoolVector3Array() # all 0's

# non-Trojans - arrays pre-structured for MeshArray construction
var a_e_i := PoolVector3Array()
var Om_w_M0_n := PoolColorArray()
# Trojans - arrays pre-structured for MeshArray construction
var d_e_i := PoolVector3Array()
var Om_w_D_f := PoolColorArray()


# *****************************************************************************

var is_trojans: bool

var _index := 0
var _maxes := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _mins := [INF, INF, INF, INF, INF, INF, INF, INF, INF]
var _load_count := 0



func expand_arrays(n: int) -> void:
	names.resize(n + names.size())
	iau_numbers.resize(n + iau_numbers.size())
	magnitudes.resize(n + magnitudes.size())
	dummy_translations.resize(n + dummy_translations.size())
	if !is_trojans:
		a_e_i.resize(n + a_e_i.size())
		Om_w_M0_n.resize(n + Om_w_M0_n.size())
	else:
		d_e_i.resize(n + d_e_i.size())
		Om_w_D_f.resize(n + Om_w_D_f.size())
		th0_de.resize(n + th0_de.size())


func set_data(name_: String, magnitude: float, keplerian_elements: Array, iau_number := -1) -> void:
	names[_index] = name_
	iau_numbers[_index] = iau_number
	magnitudes[_index] = magnitude
	dummy_translations[_index] = Vector3(0.0, 0.0, 0.0)
	a_e_i[_index] = Vector3(keplerian_elements[0], keplerian_elements[1], keplerian_elements[2]) # a, e, i
	Om_w_M0_n[_index] = Color(keplerian_elements[3], keplerian_elements[4], keplerian_elements[5], keplerian_elements[6]) # Om, w, M0, n
	_index += 1


func set_trojan_data(name_: String, magnitude: float, keplerian_elements: Array, trojan_elements: Array, iau_number := -1) -> void:
	names[_index] = name_
	iau_numbers[_index] = iau_number
	magnitudes[_index] = magnitude
	dummy_translations[_index] = Vector3(0.0, 0.0, 0.0)
	d_e_i[_index] = Vector3(trojan_elements[1], keplerian_elements[1], keplerian_elements[2]) # d, e, i
	Om_w_D_f[_index] = Color(keplerian_elements[3], keplerian_elements[4], trojan_elements[2], trojan_elements[3]) # Om, w, D, f
	th0_de[_index] = Vector2(trojan_elements[4], 0.0) # th0_de
	_index += 1


func write_binary(binary: File) -> void:
	var binary_data: Array
	if !is_trojans:
		binary_data = [names, iau_numbers, magnitudes, dummy_translations, a_e_i, Om_w_M0_n]
	else:
		binary_data = [names, iau_numbers, magnitudes, dummy_translations, d_e_i, Om_w_D_f, th0_de]
	binary.store_var(binary_data)


func clear_for_import() -> void:
	names.resize(0)
	iau_numbers.resize(0)
	magnitudes.resize(0)
	dummy_translations.resize(0)
	a_e_i.resize(0)
	Om_w_M0_n.resize(0)
	d_e_i.resize(0)
	Om_w_D_f.resize(0)
	th0_de.resize(0)
	_index = 0



