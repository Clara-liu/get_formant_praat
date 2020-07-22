# written by Zirui Liu (zirui.liu.17@ucl.ac.uk); all rights reserved.


include procedures.praat


form Parameter settings
	word Speaker_label S1
	word Nonvoiced_interval_label voiceless
	word Data_file_name result
	word Working_directory
	comment Formant settings:
		natural Sampling_rate 160
		boolean Smooth_formant
		integer Number_of_rectangular_smooths 2
		natural Max_number_of_formants 5
		natural Max_formant 5000
		positive Window_length_(s) 0.025
		positive Pre_emphasis_from_(Hz) 50.0
	choice Procedure 2
	    button Align repetitions
	    button Get raw trajectories
	word Align_at_the_end_of_boundary_labelled
	boolean Process_EMA_data 0
endform

working_directory$ = working_directory$ + "/"
resultPath$ = working_directory$ + data_file_name$
time_step = 1/sampling_rate
##########################################
if procedure$ == "Align repetitions"
	beginPause: "Alignment"
		boolean: "Trim all trajectories to be the same length", 0
	clicked = endPause: "Continue", 1
endif

# to record wordrep array for align repetitions
wordIdx = 1

non_voiced$ = nonvoiced_interval_label$

Create Strings as file list... sounds, 'working_directory$'*.wav
Create Strings as file list... labels, 'working_directory$'*.TextGrid

select Strings sounds_
fileNum = Get number of strings

# create object name list
for file from 1 to fileNum
	select Strings sounds_
    soundFile$ = Get string... file
    fileName$ = replace$(soundFile$, ".wav", "", 0)
    fileNames$[file] = fileName$
endfor

for file from 1 to fileNum
    select Strings sounds_
    soundFile$ = Get string... file
    soundPath$ = working_directory$ + soundFile$
    select Strings labels_
    labelFile$ = Get string... file
    labelPath$ = working_directory$ + labelFile$
	Read from file... 'soundPath$'
    Read from file... 'labelPath$'
    currentFile$ = fileNames$[file]

    call getTrimmedFormants 'currentFile$' 'speaker_label$' 'non_voiced$' max_formant max_number_of_formants window_length pre_emphasis_from

    if number_of_rectangular_smooths > 0
       	call smoothFormants number_of_rectangular_smooths 'currentFile$'
    endif
endfor

# concat dfs from all sound files
for df from 1 to fileNum
    df$ = fileNames$[df]
    if df = 1
    	select Table 'df$'
    else
    	plus Table 'df$'
    endif
endfor
Append
select Table appended
Rename... df

if procedure$ == "Align repetitions"
	# create speaker list
	speaker$ = Get value... 1 Speaker
	Create Strings as tokens... 'speaker$' 
	Rename... speakers

	select Table df
	call getShortest
	call alignTrim
	call getTime
	if trim_all_trajectories_to_be_the_same_length
		select Table trimmed
	else
		select Table aligned
	endif
endif

Save as comma-separated file... 'resultPath$'.csv
	


