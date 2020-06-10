form Start
	word Speaker_gender female
	word Audio_file_name name
	word Label_file_name name
	integer Sampling_rate 160
	integer Number_of_smooths 2
	word Nonvoiced_interval_label voiceless
	word Data_file_name result
endform

gender$ = speaker_gender$
sr = sampling_rate
labelFile$ = label_file_name$
audioFile$ = audio_file_name$
time_step = 1/sr
non_voiced$ = nonvoiced_interval_label$

# for trimming formants
max_bump = 0.1
max_edge = 0.0


Read from file... 'labelFile$'.TextGrid
Read from file... 'audioFile$'.wav

if gender$ == "male"
	maxFormant = 5000
else
	maxFormant = 5500
endif

Create Table with column names... Data 0 WordRep Word Interval RealTime Time F1 F2 F3 F1_s F2_s F3_s

select Sound 'audioFile$'
To Formant (burg)... 0 5 maxFormant 0.025 50

select TextGrid 'labelFile$'
intNum = Get number of intervals... 1

rowNum = 1

# for assigneing values for smoothed arrays
smoothed_row = 1

for int from 1 to intNum
select TextGrid 'labelFile$'

label$ = Get label of interval... 1 int
	if length(label$)
		word$ = replace_regex$(label$, "\d", "", 0)

		start = Get start time of interval... 1 int
		end = Get end time of interval... 1 int
		sampleNum = floor((end - start)*sr)

		for sample from 1 to sampleNum

			time = start + (sample-1)*time_step
			wordTime = sample*time_step - time_step
			select Formant 'audioFile$'
			f1 = Get value at time... 1 time hertz Linear
			f2 = Get value at time... 2 time hertz Linear
			f3 = Get value at time... 3 time hertz Linear
		
			select TextGrid 'labelFile$'
			intervalNum = Get interval at time... 2 time
			interval$ = Get label of interval... 2 intervalNum

			select Table Data
			Append row

			Set numeric value... rowNum RealTime time
			Set numeric value... rowNum Time wordTime
			Set string value... rowNum WordRep 'label$'
			Set string value... rowNum Word 'word$'
			Set string value... rowNum Interval 'interval$'

			if interval$ <> non_voiced$
				Set numeric value... rowNum F1 f1
				Set numeric value... rowNum F2 f2
				Set numeric value... rowNum F3 f3
			endif

			rowNum += 1
		endfor
        
        # trim formants
        select Table Data
        Extract rows where column (text)... WordRep "is equal to" 'label$'
        
        select Table Data_'label$'
        rows = Get number of rows
        
        for r from 1 to rows
            if r == 1 or r == rows
				f1_smoothed[smoothed_row] = Get value... r F1
				f2_smoothed[smoothed_row] = Get value... r F2
				f3_smoothed[smoothed_row] = Get value... r F3
                smoothed_row += 1
            else
				f1_left = Get value... (r-1) F1
				f1_mid = Get value... r F1
				f1_right = Get value... (r+1) F1
            
				f2_left = Get value... (r-1) F2
				f2_mid = Get value... r F2
				f2_right = Get value... (r+1) F2
            
				f3_left = Get value... (r-1) F3
				f3_mid = Get value... r F3
				f3_right = Get value... (r+1) F3
                
				if f1_left <> undefined and f1_right <> undefined
					f1_diff1_hump = f1_mid - f1_left
					f1_diff2_hump = f1_mid - f1_left
					f1_diff1_dip = f1_left - f1_mid
					f1_diff2_dip = f1_right - f1_mid

					f2_diff1_hump = f2_mid - f2_left
					f2_diff2_hump = f2_mid - f2_left
					f2_diff1_dip = f2_left - f2_mid
					f2_diff2_dip = f2_right - f2_mid

					f3_diff1_hump = f3_mid - f3_left
					f3_diff2_hump = f3_mid - f3_left
					f3_diff1_dip = f3_left - f3_mid
					f3_diff2_dip = f3_right - f3_mid
					
					if (f1_diff1_hump > max_bump and f1_diff2_hump > max_edge) or (f1_diff1_dip > max_bump and f1_diff2_dip > max_edge)
						f1_trimmed = f1_left + time_step/(time_step*2)*(f1_right-f1_left)
						f1_smoothed[smoothed_row] = f1_trimmed
					else
						f1_smoothed[smoothed_row] = f1_mid
					endif

					if (f2_diff1_hump > max_bump and f2_diff2_hump > max_edge) or (f2_diff1_dip > max_bump and f2_diff2_dip > max_edge)
						f2_trimmed = f2_left + time_step/(time_step*2)*(f2_right-f2_left)
						f2_smoothed[smoothed_row] = f2_trimmed
					else
						f2_smoothed[smoothed_row] = f2_mid
					endif

					if (f3_diff1_hump > max_bump and f3_diff2_hump > max_edge) or (f3_diff1_dip > max_bump and f3_diff2_dip > max_edge)
						f3_trimmed = f3_left + time_step/(time_step*2)*(f3_right-f3_left)
						f3_smoothed[smoothed_row] = f3_trimmed
					else
						f3_smoothed[smoothed_row] = f3_mid
					endif

					smoothed_row += 1
				elsif f1_right == undefined or f1_left == undefined
					f1_smoothed[smoothed_row] = Get value... r F1
					f2_smoothed[smoothed_row] = Get value... r F2
					f3_smoothed[smoothed_row] = Get value... r F3
					smoothed_row += 1
				else
					f1_smoothed[smoothed_row] =
					f2_smoothed[smoothed_row] =
					f3_smoothed[smoothed_row] =
                    smoothed_row += 1
				endif
            endif
        
        endfor
		select Table Data_'label$'
		Remove
    
	endif

endfor

select Formant 'audioFile$'
Remove

select Table Data
total_rows = Get number of rows

for r from 1 to total_rows
	interval$ = Get value... r Interval
	if interval$ <> non_voiced$
    	Set numeric value... r F1_s f1_smoothed[r]
    	Set numeric value... r F2_s f2_smoothed[r]
    	Set numeric value... r F3_s f3_smoothed[r]
	endif
endfor

# calculate smoothed formant arrays
if number_of_smooths > 0
	for smooth from 1 to number_of_smooths
        resmoothed_row = 1
        for int from 1 to intNum
            select TextGrid 'labelFile$'
            label$ = Get label of interval... 1 int
            if length(label$)
                select Table Data
                Extract rows where column (text)... WordRep "is equal to" 'label$'
                
                select Table Data_'label$'
                rows = Get number of rows
                for r from 1 to rows
                    if r == 1 or r == rows
                        f1_smoothed[resmoothed_row] = Get value... r F1
                        f2_smoothed[resmoothed_row] = Get value... r F2
                        f3_smoothed[resmoothed_row] = Get value... r F3
                        resmoothed_row += 1
                    else
                        f1_s_left = Get value... (r-1) F1_s
                        f1_s_mid = Get value... r F1_s
                        f1_s_right = Get value... (r+1) F1_s
                    
                        f2_s_left = Get value... (r-1) F2_s
                        f2_s_mid = Get value... r F2_s
                        f2_s_right = Get value... (r+1) F2_s
                    
                        f3_s_left = Get value... (r-1) F3_s
                        f3_s_mid = Get value... r F3_s
                        f3_s_right = Get value... (r+1) F3_s
                        
                        if f1_s_left <> undefined and f1_s_right <> undefined
                            f1_smoothed[resmoothed_row] = (f1_s_left + f1_s_mid + f1_s_right)/3
                            f2_smoothed[resmoothed_row] = (f2_s_left + f2_s_mid + f2_s_right)/3
                            f3_smoothed[resmoothed_row] = (f3_s_left + f3_s_mid + f3_s_right)/3
                            resmoothed_row += 1
                        elsif f1_s_right == undefined or f1_s_left == undefined
                            f1_smoothed[resmoothed_row] = Get value... r F1_s
                            f2_smoothed[resmoothed_row] = Get value... r F2_s
                            f3_smoothed[resmoothed_row] = Get value... r F3_s
                            resmoothed_row += 1
                        else
                            f1_smoothed[resmoothed_row] =
                            f2_smoothed[resmoothed_row] =
                            f3_smoothed[resmoothed_row] =
                            resmoothed_row += 1
                        endif
                    endif
                
                endfor
                select Table Data_'label$'
                Remove
                
            endif
        endfor
    endfor
endif

select Table Data

for r from 1 to total_rows
    interval$ = Get value... r Interval
    if interval$ <> non_voiced$
        Set numeric value... r F1_s f1_smoothed[r]
        Set numeric value... r F2_s f2_smoothed[r]
        Set numeric value... r F3_s f3_smoothed[r]
    endif
endfor

Save as comma-separated file... 'data_file_name$'.csv
Remove

select Sound 'audioFile$'
plus TextGrid 'labelFile$'
Remove
