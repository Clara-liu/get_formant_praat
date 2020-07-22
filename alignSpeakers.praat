# written by Zirui Liu (zirui.liu.17@ucl.ac.uk); all rights reserved.

include procedures.praat

form Align speakers
	word Working_directory
	word Data_file_name result
	natural Sampling_rate 160
	word Word_file_name word_list.txt
	natural Repetition_number 10
	boolean Trim_all_trajectories_to_be_the_same_length 0
	word Align_at_the_end_of_boundary_labelled
endform

working_directory$ = working_directory$ + "/"
resultPath$ = working_directory$ + data_file_name$
time_step = 1/sampling_rate


Create Strings as file list... files, 'working_directory$'*.csv
select Strings files_
fileNum = Get number of strings
# create speaker list and table name list
for file from 1 to fileNum
	select Strings files_
	file$ = Get string... file
	filePath$ = working_directory$ + file$
	Read Table from comma-separated file... 'filePath$'
	speaker$ = Get value... 1 Speaker
	if file = 1
		Create Strings as tokens... 'speaker$'
		Rename... speakers
	else
		select Strings speakers
		Insert string... 0 'speaker$'
	endif

	fileName$ = replace$(file$, ".csv", "", 0)
	fileNames$[file] = fileName$
endfor

# create word array from txt file
wordsPath$ = working_directory$ + word_file_name$
Read Strings from raw text file... 'wordsPath$'
wordNum = Get number of strings
Rename... word_list
wordIdx = 1
for w from 1 to wordNum
	for r from 1 to repetition_number
		if r < 10
			rep$ = "0" + string$(r)
		else
			rep$ = string$(r)
		endif
		select Strings word_list
		currentWord$ = Get string... w
		wordRep$ = currentWord$ + rep$
		words$[wordIdx] = wordRep$
		wordIdx += 1
	endfor
endfor

# concat dfs from all speakers
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

call getShortest
call alignTrim
call getTime

if trim_all_trajectories_to_be_the_same_length
	select Table trimmed
else
	select Table aligned
endif

Save as comma-separated file... 'resultPath$'.csv


