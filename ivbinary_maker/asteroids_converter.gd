# asteroid_converter.gd
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
class_name AsteroidsConverter
extends Reference

const math := preload("res://ivoyager/static/math.gd")
const files := preload("res://ivoyager/static/files.gd")


signal status(func_type, message)


enum { # func_type
	ADD_NUMBERED,
	ADD_MULTIOPPOSITION,
	REVISE_NAMES,
	REVISE_PROPER,
	REVISE_TROJANS,
	MAKE_BINARY_FILES,
	START_OVER,
}

# settings
const USE_THREAD := false # false for debug
const REJECT_999 := false # reject mag "-9.99"; if false, accept but change to "99"
const STATUS_INTERVAL := 20000

# read/write
const SOURCE_PATH := "res://source_data/asteroids/"
const EXPORT_DIR := "res://ivbinary_export/asteroid_binaries"
const BINARIES_EXTENSION := "ivbinary"

# source data
const CAT_EPOCH := 60000.0 # This changes! Check 'Epoch(MJD)' in *.cat files!
const J2000_SEC := (CAT_EPOCH - 51544.5) * 86400.0 # seconds from our internal J2000 epoch
const ASTEROID_ORBITAL_ELEMENTS_NUMBERED_FILE := "allnum.cat"
const ASTEROID_ORBITAL_ELEMENTS_MULTIOPPOSITION_FILE := "ufitobs.cat"
const ASTEROID_PROPER_ELEMENTS_FILES := ["all.syn", "tno.syn", "secres.syn"]
const SECULAR_RESONANT_FILE := "secres.syn" # This one in above list, but special
const TROJAN_PROPER_ELEMENTS_FILE := "tro.syn"
const ASTEROID_NAMES_FILE := "discover.tab"

# units and standard gravitational parameter (binaries use  SI & radians)
const YEAR := 365.25 * 24.0 * 3600.0 # s; this is exact for Julian year
const AU := 149597870700.0 # m
const GM := 1.32712440042e20 # m^3 s^-2 (used only if we don't have proper elements)

# internal
const N_ELEMENTS := 12 # [a, e, i, Om, w, M0, n, M, mag, s, g, de]
const BINARY_FILE_MAGNITUDES = IVSmallBodiesBuilder.BINARY_FILE_MAGNITUDES


var _tables: Dictionary = IVGlobal.tables
var _table_reader: IVTableReader
var _thread: Thread

# current processing
var _asteroid_elements := PoolRealArray()
var _asteroid_names := []
var _iau_numbers := [] # -1 for unnumbered
var _astdys2_lookup := {} # index by astdys-2 format (number string or "2010UZ106")
var _trojan_elements := {}
var _index := 0


func _project_init() -> void:
	_table_reader = IVGlobal.program.TableReader
	if USE_THREAD:
		_thread = Thread.new()


func call_method(method: String) -> void:
	if USE_THREAD:
		if _thread.is_active():
			_thread.wait_to_finish()
		_thread.start(self, "_run_in_thread", method)
	else:
		call(method)
	

func _run_in_thread(method: String) -> void:
	call(method)


func add_numbered() -> void:
	_read_astdys_cat_file(ASTEROID_ORBITAL_ELEMENTS_NUMBERED_FILE, ADD_NUMBERED)


func add_multiopposition() -> void:
	_read_astdys_cat_file(ASTEROID_ORBITAL_ELEMENTS_MULTIOPPOSITION_FILE, ADD_MULTIOPPOSITION)


func revise_names() -> void:
	# The name file used here and asteroid numbered file both both have
	# line number = asteroid number (not counting header). We test that and use for indexing.
	var index := 0
	var count := 0
	var path := SOURCE_PATH + ASTEROID_NAMES_FILE
	var read_file = File.new()
	if read_file.open(path, File.READ) != OK:
		_update_status(REVISE_NAMES, "Could not open " + path)
		return
	var line: String = read_file.get_line()
	var status_index := STATUS_INTERVAL
	while !read_file.eof_reached():
		var number := int(line.substr(0, 6))
		assert(number == index + 1)
		assert(number == int(_asteroid_names[index]))
		var astdys2_name := line.substr(7, 17)
		astdys2_name = astdys2_name.strip_edges(false, true)
		if astdys2_name == "-":
			astdys2_name = ""
		
		# Do we want to add year-code if we have number?
#		if astdys2_name == "": # get and format year-number astdys2_name, if any
#			astdys2_name = line.substr(25, 4) + line.substr(30, 6) # skip space conforms w/ AstDyS-2
#			if astdys2_name.substr(0, 1) == "-":
#				astdys2_name = ""
#			else:
#				astdys2_name = astdys2_name.strip_edges(false, true)
		if astdys2_name:
			count += 1
			astdys2_name = str(number) + " " + astdys2_name
			if count == status_index:
				_update_status(REVISE_NAMES, "%s count (renamed: \"%s\" to \"%s\""
						% [count, _asteroid_names[index], astdys2_name])
				status_index += STATUS_INTERVAL
			_asteroid_names[index] = astdys2_name
		line = read_file.get_line()
		index += 1
	read_file.close()
	_update_status(REVISE_NAMES, str(count) + " renamed")


func revise_proper() -> void:
	# TODO: Secular resonant are only partially implemented (we simply skip e here)
	var revised := 0
	var n_not_found := 0
	var status_index := STATUS_INTERVAL
	for file_name in ASTEROID_PROPER_ELEMENTS_FILES:
		var is_sec_res: bool = file_name == SECULAR_RESONANT_FILE
		print("is_sec_res ", is_sec_res)
		var path: String = SOURCE_PATH + file_name
		var read_file := File.new()
		if read_file.open(path, File.READ) != OK:
			_update_status(REVISE_PROPER, "Could not open " + path)
			continue
		var line := read_file.get_line()
		while not read_file.eof_reached():
			if line.substr(0, 1) == "%":
				line = read_file.get_line()
				continue
			var line_array := line.split(" ", false)
			var astdys2_name: String = line_array[0]
			var index: int
			if _astdys2_lookup.has(astdys2_name):
				index = _astdys2_lookup[astdys2_name]
			else:
				n_not_found += 1
				line = read_file.get_line()
				continue
			var proper_a := float(line_array[2]) * AU
			var proper_e := float(line_array[3]) # really de in secular resonant
			var proper_i := asin(float(line_array[4])) # sin(i) -> i
			var proper_n := deg2rad(float(line_array[5])) / YEAR # deg/yr -> rad/s
			var g := deg2rad(float(line_array[6]) / 3600.0) / YEAR # "/yr -> rad/s
			var s := deg2rad(float(line_array[7]) / 3600.0) / YEAR # "/yr -> rad/s
			
			# [a, e, i, Om, w, M0, n, M, mag, s, g, de]
			
			# recalculate M0 using proper_n
			var M: float = _asteroid_elements[index * N_ELEMENTS + 7]
			var M0 := wrapf(M - proper_n * J2000_SEC, 0.0, TAU) # replaced if we have proper elements
			_asteroid_elements[index * N_ELEMENTS + 5] = M0
			
			# set proper elements
			_asteroid_elements[index * N_ELEMENTS] = proper_a
			if is_sec_res:
				_asteroid_elements[index * N_ELEMENTS + 11] = proper_e
			else:
				_asteroid_elements[index * N_ELEMENTS + 1] = proper_e
			_asteroid_elements[index * N_ELEMENTS + 2] = proper_i
			_asteroid_elements[index * N_ELEMENTS + 6] = proper_n
			_asteroid_elements[index * N_ELEMENTS + 9] = s
			_asteroid_elements[index * N_ELEMENTS + 10] = g
			revised += 1
			if revised == status_index:
				_update_status(REVISE_PROPER, "%s orbits revised to proper" % revised)
				status_index += STATUS_INTERVAL
			line = read_file.get_line()
		read_file.close()
	_update_status(REVISE_PROPER, "%s orbits revised to proper\n(Did not find %s)" % [revised, n_not_found])


func revise_trojans() -> void:
	# For trojans, we revise to proper e & i and save L-point, d, D & f in
	# _trojan_elements indexed by index (for writing to separate "L4", "L5"
	# binaries).
	var revised := 0
	var n_not_found := 0
	var status_index := STATUS_INTERVAL
	var path := SOURCE_PATH + TROJAN_PROPER_ELEMENTS_FILE
	var read_file := File.new()
	if read_file.open(path, File.READ) != OK:
#		print("Could not open ", path)
		_update_status(REVISE_TROJANS, "Could not open " + path)
		return
	var line := read_file.get_line()
	while not read_file.eof_reached():
		if line.substr(0, 1) == "%":
			line = read_file.get_line()
			continue
		var line_array := line.split(" ", false)
		var astdys2_name: String = line_array[0]
		var index: int
		if _astdys2_lookup.has(astdys2_name):
			index = _astdys2_lookup[astdys2_name]
		else:
			n_not_found += 1
			line = read_file.get_line()
			continue
		var da := float(line_array[2]) * AU
		var D := deg2rad(float(line_array[3])) # deg -> rad
		var f := deg2rad(float(line_array[4])) / YEAR # deg/y -> rad/s
		var proper_e := float(line_array[5])
		var g := deg2rad(float(line_array[6]) / 3600.0) / YEAR # "/yr -> rad/s
		var proper_i := asin(float(line_array[7])) # sin(i) -> i
		var s := deg2rad(float(line_array[8]) / 3600.0) / YEAR # "/yr -> rad/s
		var lp_float := float(line_array[9]) # "4" or "5" -> 4.0 or 5.0
		assert(lp_float == 4.0 or lp_float == 5.0)
		
		# [a, e, i, Om, w, M0, n, M, mag, s, g, de]
		
		# TODO: Given M, a, D, da & f (& s, g), approximate theta & theta0.
		# (a, M0 & n change w/ libration, so we don't need to fix here.)
		var th0 := rand_range(0.0, TAU) # just random for now...
		
		# Regular propers
		# [a, e, i, Om, w, M0, n, M, mag, s, g, de]
		_asteroid_elements[index * N_ELEMENTS + 1] = proper_e
		_asteroid_elements[index * N_ELEMENTS + 2] = proper_i
		_asteroid_elements[index * N_ELEMENTS + 9] = s
		_asteroid_elements[index * N_ELEMENTS + 10] = g
		# Trojan data
		_trojan_elements[index] = [lp_float, da, D, f, th0]
		
		revised += 1
		if revised == status_index:
			_update_status(REVISE_TROJANS, "%s orbits revised to proper" % revised)
			status_index += STATUS_INTERVAL
		line = read_file.get_line()
	read_file.close()
	_update_status(REVISE_TROJANS, "%s orbits revised to proper\n(Did not find %s)"
			% [revised, n_not_found])


func make_binary_files() -> void:
	# Binary files have name format such as "NE.22.5.vbinary" where NE is
	# orbit group (defined in data_tables/asteroid_import_data.txt) and 22.5
	# is the magnitude cutoff (contains everything brighter than this and
	# not already in smaller numbered binaries).
	# The binary is made using Godot function store_var(array) where array is
	# [<n_indexes>, <N_ELEMENTS>, <_asteroid_elements>, <_asteroid_names>,
	# <trojan_elements or null>]
	
	var n_total := _asteroid_names.size()
	_update_status(MAKE_BINARY_FILES, "n_total: %s" % n_total)
	print("N_ELEMENTS: ", N_ELEMENTS)
	var added := 0
	
	# Store indexes by file_name where data will be stored
	var group_indexes_dict := {}
	var mags := []
	for mag_str in BINARY_FILE_MAGNITUDES:
		mags.append(float(mag_str))
	var is_trojan_group := {}
	var trojan_file_groups := []
	
	var n_groups := _table_reader.get_n_rows("asteroid_groups")
	for row in n_groups:
		var trojan_of := _table_reader.get_string("asteroid_groups", "trojan_of", row)
		var is_trojans := bool(trojan_of)
		var group := _table_reader.get_string("asteroid_groups", "group", row)
		is_trojan_group[group] = is_trojans
		if not is_trojans:
			group_indexes_dict[group] = {}
			for mag_str in BINARY_FILE_MAGNITUDES:
				group_indexes_dict[group][mag_str] = []
		else:
			trojan_file_groups.append(group + "4")
			trojan_file_groups.append(group + "5")
			group_indexes_dict[group + "4"] = {}
			group_indexes_dict[group + "5"] = {}
			for mag_str in BINARY_FILE_MAGNITUDES:
				group_indexes_dict[group + "4"][mag_str] = []
			for mag_str in BINARY_FILE_MAGNITUDES:
				group_indexes_dict[group + "5"][mag_str] = []

	var group_definitions := {}
	for row in n_groups:
		var group := _table_reader.get_string("asteroid_groups", "group", row)
		var min_q := _table_reader.get_real("asteroid_groups", "min_q", row)
		var max_q := _table_reader.get_real("asteroid_groups", "max_q", row)
		var min_a := _table_reader.get_real("asteroid_groups", "min_a", row)
		var max_a := _table_reader.get_real("asteroid_groups", "max_a", row)
		var max_e := _table_reader.get_real("asteroid_groups", "max_e", row)
		var max_i := _table_reader.get_real("asteroid_groups", "max_i", row)
		
		
		group_definitions[group] = {
			min_q = min_q if !is_nan(min_q) else 0.0,
			max_q = max_q if !is_nan(max_q) else INF,
			min_a = min_a if !is_nan(min_a) else 0.0,
			max_a = max_a if !is_nan(max_a) else INF,
			max_e = max_a if !is_nan(max_e) else INF,
			max_i = max_a if !is_nan(max_i) else INF,
		}
	var status_index := STATUS_INTERVAL
	var index := 0
	while index < n_total:
		# [a, e, i, Om, w, M0, n, M, mag, s, g, de]
		var a: float = _asteroid_elements[index * N_ELEMENTS]
		var e: float = _asteroid_elements[index * N_ELEMENTS + 1]
		var q: float = (1.0 - e) * a
		var i: float = _asteroid_elements[index * N_ELEMENTS + 2]
		var magnitude: float = _asteroid_elements[index * N_ELEMENTS + 8]
		var mag_index := mags.bsearch(magnitude)
		if mag_index >= BINARY_FILE_MAGNITUDES.size():
			mag_index = BINARY_FILE_MAGNITUDES.size() - 1
		var mag_str: String = BINARY_FILE_MAGNITUDES[mag_index]
		# find the group that fits this asteroid
		for group in group_definitions:
			var def = group_definitions[group]
			if a <= def.min_a or a > def.max_a:
				continue
			if q <= def.min_q or q > def.max_q:
				continue
			if e > def.max_e:
				continue
			if i > def.max_i:
				continue
			var is_trojan: bool = _trojan_elements.has(index) # was in tro.syn
			if is_trojan != is_trojan_group[group]:
				continue
			# passes all definitions, so add index to a group
			if is_trojan:
				var lp_str := str(_trojan_elements[index][0]) # "4" or "5"
				assert(lp_str == "4" or lp_str == "5")
				group_indexes_dict[group + lp_str][mag_str].append(index)
			else:
				group_indexes_dict[group][mag_str].append(index)
			added += 1
			if added == status_index:
				_update_status(MAKE_BINARY_FILES, "%s indexes added (current prefix: %s.%s)"
						% [added, group, mag_str])
				status_index += STATUS_INTERVAL
			break
		index += 1
	print("%s indexes added" % added)
	if added != n_total:
		print("WARNING! %s added different than %s index number. Check data table criteria."
				% [added, n_total])
	
	# Write binaries
	print("Writing binaries to ", EXPORT_DIR)
	files.make_or_clear_dir(EXPORT_DIR)
	
	var group_proxy := GroupProxy.new()
	
	for file_group in group_indexes_dict:
		var is_trojans: bool = trojan_file_groups.has(file_group)
		for mag_str in group_indexes_dict[file_group]:
			var group_indexes: Array = group_indexes_dict[file_group][mag_str]
			var n_indexes := group_indexes.size()
			if n_indexes == 0:
				continue
			group_indexes.sort_custom(self, "_sort_group_indexes_by_mag")
			group_proxy.clear_for_import()
			group_proxy.expand_arrays(n_indexes, is_trojans)
			for i in n_indexes:
				index = group_indexes[i]
				var name_: String = _asteroid_names[index]
				var elements := []
				elements.resize(N_ELEMENTS)
				# [a, e, i, Om, w, M0, n, M, mag, s, g, de]
				for j in N_ELEMENTS:
					elements[j] = _asteroid_elements[index * N_ELEMENTS + j]
				if is_trojans:
					group_proxy.set_data(name_, elements, _trojan_elements[index])
				else:
					group_proxy.set_data(name_, elements)
			var file_name := "%s.%s.%s" % [file_group, mag_str, BINARIES_EXTENSION]
			_update_status(MAKE_BINARY_FILES,"%s (number indexes: %s)" % [file_name, n_indexes])
			var path := EXPORT_DIR + "/" + file_name
			var binary := File.new()
			if binary.open(path, File.WRITE) != OK:
#				print("Could not write ", path)
				_update_status(MAKE_BINARY_FILES,"Could not write " + path)
				return
			group_proxy.write_binary(binary)
			binary.close()
			
			

	_update_status(MAKE_BINARY_FILES, "%s asteroids written to binaries\n(of %s total)"
			% [added, n_total])


func _sort_group_indexes_by_mag(a: int, b: int) -> bool:
	return _asteroid_elements[a * N_ELEMENTS + 8] < _asteroid_elements[b * N_ELEMENTS + 8]


func start_over() -> void:
	_asteroid_elements.resize(0)
	_asteroid_names.clear()
	_iau_numbers.clear()
	_astdys2_lookup.clear()
	_index = 0


func _read_astdys_cat_file(data_file: String, func_type: int) -> void:
	# _asteroid_elements contain N_ELEMENTS floats per index: the first
	# 7 elements of keplerian_elements, magnitude (after propers: s, g, L)
	# for each asteroid.
	var path := SOURCE_PATH + data_file
	var read_file := File.new()
	if read_file.open(path, File.READ) != OK:
#		print("Could not open ", path)
		_update_status(func_type, "Could not open " + path)
		return
	var line := read_file.get_line()
	while line.substr(0, 1) != "!":
		line = read_file.get_line()
	line = read_file.get_line() # data starts after line starting with "!"
	var status_index := _index + STATUS_INTERVAL
	while not read_file.eof_reached():
		var line_array := line.split(" ", false)
		var mag_str: String = line_array[8]
		if mag_str == "-9.99":
			if REJECT_999:
				line = read_file.get_line()
				continue
			else:
				mag_str = "99"
		var astdys2_name: String = line_array[0]
		astdys2_name = astdys2_name.replace("'", "")
		
		assert(!_astdys2_lookup.has(astdys2_name), "Duplicate name: " + astdys2_name)
		
		_astdys2_lookup[astdys2_name] = _index
		_asteroid_names.append(astdys2_name)
		
		var a := float(line_array[2]) * AU
		var e := float(line_array[3])
		var i := deg2rad(float(line_array[4]))
		var Om := deg2rad(float(line_array[5]))
		var w := deg2rad(float(line_array[6]))
		var M := deg2rad(float(line_array[7]))
		
		var n := sqrt(GM / (a * a * a)) # replaced if we have proper elements
		
		# M = M0 + n * t
		var M0 := wrapf(M - n * J2000_SEC, 0.0, TAU) # replaced if we have proper elements
		
		
		# [a, e, i, Om, w, M0, n, M, mag, s, g, de]
		_asteroid_elements.append(a) # au
		_asteroid_elements.append(e) # e
		_asteroid_elements.append(i) # i
		_asteroid_elements.append(Om) # Om
		_asteroid_elements.append(w) # w
		_asteroid_elements.append(M0) # M0 provisional (replaced if proper elements)
		_asteroid_elements.append(n) # n provisional (replaced if proper elements)
		_asteroid_elements.append(M) # M, mean anomaly at *source file* epoch
		_asteroid_elements.append(float(mag_str)) # magnitude
		for _i in range(N_ELEMENTS - 9):
			 _asteroid_elements.append(0.0) # will be s, g, de from propers
		
		line = read_file.get_line()
		_index += 1
		if _index == status_index:
			_update_status(func_type, str(_index) + " total asteroids (current: "
					+ astdys2_name + ")")
			status_index += STATUS_INTERVAL
			
		
	read_file.close()
	_update_status(func_type, str(_index) + " total asteroids")
	


func _update_status(func_type: int, message: String) -> void:
	call_deferred("emit_signal", "status", func_type, message)
	print(message)
	


