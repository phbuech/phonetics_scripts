clearinfo

form: "Basic segment measurements"
	sentence: "input directory" , "path_to_input_directory"
	comment: "Select parameters"
	boolean: "duration",  1
	boolean: "f0", 1
	boolean: "intensity", 1
	boolean: "center of gravity", 1
	boolean: "standard deviation", 1
	boolean: "skewness", 1
	boolean: "kurtosis", 1	
	boolean: "F1", 1
	boolean: "F2", 1
	boolean: "F3", 1
	boolean: "F4", 1
	boolean: "F5", 1
	optionmenu: "Formant ceiling", 2
		option: "5500.0"
		option: "5000.0"
	comment: "Enter target segments (comma-separated)"
	sentence: "targets", "a,i,u"
	positive: "tier", "2"
	sentence: "output", "output.csv"
	comment: "The file will be stored at the location of this script."
 endform

# extract labels
target_label$[0] = ""
label_counter = 1
target_string_length = length(targets$)
str$ = targets$
for char_idx from 1 to target_string_length
	char$ = mid$(targets$,char_idx,1)
	if char$ = ","
		comma_index = index(str$,",")
		target_labels$[label_counter] = left$(str$,comma_index-1)
		label_counter = label_counter + 1
		str_length = length(str$)
		str$ = right$(str$,str_length - comma_index)
	endif
endfor

#add last label
right_index = rindex(targets$,",")
target_labels$[label_counter] = right$(targets$,target_string_length - right_index)



# set formant ceiling
if formant_ceiling = 1
	f_ceiling = 5500.0
elif formant_ceiling = 2
	f_ceiling = 5000.0
endif

# set possible possible options
options$[1] = "DUR"
options$[2] = "f0"
options$[3] = "F1"
options$[4] = "F2"
options$[5] = "F3"
options$[6] = "F4"
options$[7] = "F5"
options$[8] = "COG"
options$[9] = "SD"
options$[10] = "SKEW"
options$[11] = "KURT"
options$[12] = "INT"
number_of_options = 12

# collect measurement selection
measurement_selection["DUR"] = duration
measurement_selection["f0"] = f0
measurement_selection["F1"] = f1
measurement_selection["F2"] = f2
measurement_selection["F3"] = f3
measurement_selection["F4"] = f4
measurement_selection["F5"] = f5
measurement_selection["COG"] = center_of_gravity
measurement_selection["SD"] = standard_deviation
measurement_selection["SKEW"] = skewness
measurement_selection["KURT"] = kurtosis 
measurement_selection["INT"] = intensity

# create file list for all TextGrids in the directory
Create Strings as file list: "TextGridList", "'input_directory$'*.TextGrid"
num_of_files = Get number of strings


pitch_object = 0
formant_object = 0
spectrogram_object = 0
intensity_object = 0

options_cleared$[0] = ""
measurement_selection_cleared[""] = 0
options_counter = 1
for i from 1 to number_of_options
	option$ = options$[i]
	if measurement_selection[option$] = 1
		options_cleared$[options_counter] = options$[i] 
		options_counter = options_counter + 1
	endif
endfor


header$ = "TokenID,Filename,Label,Start[s]"
for option_idx from 1 to options_counter - 1
	option$ = options_cleared$[option_idx]
	header$ = header$ + "," + option$ 
endfor

writeFileLine: output$, header$
tokenid = 0
for file_idx from 1 to num_of_files
	selectObject: "Strings TextGridList"
	textgrid$ = Get string: file_idx

	#load TextGrid
	Read from file: "'input_directory$''textgrid$'"
	filename$ = selected$("TextGrid")

	# load wav file
	Read from file: "'input_directory$''filename$'.wav"

	# prepare pitch, formant and spectrogram objects
	for option_idx from 1 to options_counter - 1
		option$ = options_cleared$[option_idx]
		if option$ = "f0" and pitch_object = 0
			selectObject: "Sound 'filename$'"
			noprogress To Pitch (ac): 0, 75, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, 600
			pitch_object = 1
		elif (option$ = "F1" or option$ = "F2" or option$ = "F3" or option$ = "F4" or option$ = "F5") and formant_object = 0
			selectObject: "Sound 'filename$'"
			noprogress To Formant (burg): 0, 5, 5500, 0.025, 50
			formant_object = 1
		elif (option$ = "COG" or option$ = "SD" or option$ = "SKEW" or option$ = "KURT") and spectrogram_object = 0
			selectObject: "Sound 'filename$'"
			noprogress To Spectrogram: 0.005, 5000, 0.002, 20, "Hamming (raised sine-squared)"
			spectrogram_object = 1
		elif option$ = "INT" and intensity_object = 0
			selectObject: "Sound 'filename$'"
			noprogress To Intensity: 100, 0, "yes"
			intensity_object = 1
		endif
	endfor

	selectObject: "TextGrid 'filename$'"
	num_of_intervals = Get number of intervals: tier

	for interval_idx from 1 to num_of_intervals
		selectObject: "TextGrid 'filename$'"
		current_label$  = Get label of interval: tier, interval_idx
		
		

		for target_label_idx from 1 to label_counter 
			current_target_label$ = target_labels$[target_label_idx]
			if current_label$ = current_target_label$
				tokenid = tokenid + 1
				#initialize array for values
				for i from 1 to options_counter - 1
					values[i] = undefined
				endfor
				value_counter = 1

				tmin = Get start time of interval: tier, interval_idx
				tmax = Get end time of interval: tier, interval_idx
				tmid = (tmin + tmax)/2

				for measurement_option_idx from 1 to options_counter - 1
					mopt$ = options_cleared$[measurement_option_idx]
					if mopt$ = "DUR"
						values[value_counter]  = (tmax - tmin) * 1000
						value_counter = value_counter + 1
					elif mopt$ = "f0"
						selectObject: "Pitch 'filename$'"
						values[value_counter] = Get value at time: tmid, "Hertz", "linear"
						value_counter = value_counter + 1
					elif mopt$ = "F1"
						selectObject: "Formant 'filename$'"
						values[value_counter] = Get value at time: 1, tmid, "hertz", "linear"
						value_counter = value_counter + 1
					elif mopt$ = "F2"
						selectObject: "Formant 'filename$'"
						values[value_counter] =  Get value at time: 2, tmid, "hertz", "linear"
						value_counter = value_counter + 1
					elif mopt$ = "F3"
						selectObject: "Formant 'filename$'"
						values[value_counter] =  Get value at time: 3, tmid, "hertz", "linear"
						value_counter = value_counter + 1
					elif mopt$ = "F4"
						selectObject: "Formant 'filename$'"
						values[value_counter] =  Get value at time: 4, tmid, "hertz", "linear"
						value_counter = value_counter + 1
					elif mopt$ = "F5"
						selectObject: "Formant 'filename$'"
						values[value_counter] =  Get value at time: 5, tmid, "hertz", "linear"
						value_counter = value_counter + 1
					elif mopt$ = "COG"
						selectObject: "Spectrogram 'filename$'"
						To Spectrum (slice): tmid
						values[value_counter] = Get centre of gravity: 2.0
						value_counter = value_counter + 1
						removeObject: "Spectrum 'filename$'"
					elif mopt$ = "SD"
						selectObject: "Spectrogram 'filename$'"
						To Spectrum (slice): tmid
						values[value_counter] = Get standard deviation: 2.0
						value_counter = value_counter + 1
						removeObject: "Spectrum 'filename$'"
					elif mopt$ = "SKEW"
						selectObject: "Spectrogram 'filename$'"
						To Spectrum (slice): tmid
						values[value_counter] = Get skewness: 2.0
						value_counter = value_counter + 1
						removeObject: "Spectrum 'filename$'"
					elif mopt$ = "KURT"
						selectObject: "Spectrogram 'filename$'"
						To Spectrum (slice): tmid
						values[value_counter] = Get kurtosis: 2.0
						value_counter = value_counter + 1
						removeObject: "Spectrum 'filename$'"
					elif mopt$ = "INT"
						selectObject: "Intensity 'filename$'"
                            values[value_counter] = Get value at time: tmid, "cubic"
                            value_counter = value_counter + 1
					endif
				endfor 

			line$ = "'tokenid','filename$','current_label$','tmin'"
			for i from 1 to value_counter - 1
				value = values[i]
				line$ = line$ + ",'value'" 
			endfor
			appendFileLine: output$, line$
			endif
		endfor

	endfor





	if pitch_object = 1
		removeObject: "Pitch 'filename$'"
		pitch_object = 0
	endif
	if formant_object = 1
		removeObject: "Formant 'filename$'"
		formant_object = 0
	endif
	if spectrogram_object = 1
		removeObject: "Spectrogram 'filename$'"
		spectrogram_object = 0
	endif
	if intensity_object = 1
		removeObject: "Intensity 'filename$'"
		intensity_object = 0
	endif
	removeObject: "Sound 'filename$'", "TextGrid 'filename$'"
endfor


removeObject: "Strings TextGridList"

printline done!




