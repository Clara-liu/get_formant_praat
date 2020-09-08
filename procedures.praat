################################### PROCEDURES ##############################
procedure getEMA
	beginPause: "EMA parameters"
		word: "Measurements file name", "measures.txt"
		word: "EMA file extension", ".txt"
		choice: "EMA data delimiter", 1
			option: "Comma"
			option: "Tab"
	clicked = endPause: "Continue", 1
	
	for file from 1 to fileNum
		# read raw ema data
		currentName$ = fileNames$[file]
		thisFile$ = working_directory$ + currentName$ + eMA_file_extension$
		if eMA_data_delimiter$ == "Comma"
			Read Table from comma-separated file... 'thisFile$'
		else
			Read Table from tab-separated file... 'thisFile$'
		endif
		select Table 'currentName$'
		Rename... 'currentName$'_ema

		# calculate sampling rate and add time col in ema data
		Append column... Time
		rows = Get number of rows
		select Sound 'currentName$'
		duration = Get total duration
		time_step = duration/rows
		for row from 1 to rows
			time = (row-1)*time_step
			select Table 'currentName$'_ema
			Set numeric value... row Time time
		endfor
	endfor
	
	# create string list for ema measurements
	filePath$ = working_directory$ + measurements_file_name$
	Read Strings from raw text file... 'filePath$'
	measureNum = Get number of strings
	Rename... measures

	# add ema cols in the final data
	for measurement from 1 to measureNum
		select Strings measures
		thisMeasure$ = Get string... measurement
		select Table 'df$'
		Append column... 'thisMeasure$'
		measures$[measurement] = thisMeasure$
	endfor
	# calcualte ema data for each measurement at each time point in the formant data

	select Table 'df$'
	len = Get number of rows
	for timePoint from 1 to len
		# get the time and file info
		select Table 'df$'
		currentTime = Get value... timePoint RealTime
		currentFile$ = Get value... timePoint File

		# get t0
		select Table 'currentFile$'_ema
		Extract rows where column (number)... Time "less than or equal to" currentTime
		Rename... pre
		lastRow = Get number of rows
		t_pre = Get value... lastRow Time
		select Table pre
		Remove

		# get t2
		select Table 'currentFile$'_ema
		Extract rows where column (number)... Time "greater than" currentTime
		Rename... post
		t_post = Get value... 1 Time
		select Table post
		Remove

		# calculate ema values and adding to final data
		for m from 1 to measureNum
			# get the measurement values at surrounding time points
			select Table 'currentFile$'_ema
			Extract rows where column (number)... Time "equal to" t_pre
			currentMeasure$ = measures$[m]
			pos_pre = Get value... 1 'currentMeasure$'
			Remove

			select Table 'currentFile$'_ema
			Extract rows where column (number)... Time "equal to" t_post
			pos_post = Get value... 1 'currentMeasure$'
			Remove
			
			pos_current = pos_pre + (currentTime - t_pre)*(pos_post-pos_pre)/(t_post - t_pre)
	
			# inset position value in data
			select Table 'df$'
			Set numeric value... timePoint 'currentMeasure$' pos_current
		endfor
	endfor
	
endproc


procedure getShortest
    shortest = 9000
	# to record alignment time points
	select Strings speakers
	speakerNum = Get number of strings

    for word from 1 to (wordIdx-1)
		for s from 1 to speakerNum
        	currentWord$ = words$[word]
			select Strings speakers
			currentSpeaker$ = Get string... s
			select Table df
        	Extract rows where column (text)... Rep "is equal to" 'currentWord$'
        	tempDf$ = "df_" + currentWord$
        	select Table 'tempDf$'
			nowarn Extract rows where column (text)... Speaker "is equal to" 'currentSpeaker$'
			select Table 'tempDf$'
			Remove
			tempDf$ = tempDf$ + "_" + currentSpeaker$
			select Table 'tempDf$'
        	nowarn Extract rows where column (text)... Interval "is equal to" 'align_at_the_end_of_boundary_labelled$'
        	select Table 'tempDf$'
        	Remove
        	tempDf$ = tempDf$ + "_" + align_at_the_end_of_boundary_labelled$
        	select Table 'tempDf$'
        	length = Get number of rows
			if length
        		duration = Get value... length Time

				# get the last time point of the alignment boundary
				id$ = currentWord$ + currentSpeaker$
				alignPoints[id$] = duration

        		select Table 'tempDf$'
        		Remove
        		if duration < shortest
            		shortest = duration
        		endif
			else
				select Table 'tempDf$'
				Remove
			endif
		endfor
    endfor
    pauseScript: shortest, " seconds before the alignment boundary will be retained for all trajectories."
endproc


procedure alignTrim
	# record shortest trajectory after aligning
	shortestOverall = 9000

	for word from 1 to (wordIdx-1)
		for s from 1 to speakerNum
			currentWord$ = words$[word]
			select Strings speakers
			currentSpeaker$ = Get string... s
			select Table df
			Extract rows where column (text)... Rep "is equal to" 'currentWord$'
			tempDf$ = "df_" + currentWord$
        	select Table 'tempDf$'
			nowarn Extract rows where column (text)... Speaker "is equal to" 'currentSpeaker$'
			select Table 'tempDf$'
			Remove
			tempDf$ = tempDf$ + "_" + currentSpeaker$
			select Table 'tempDf$'
			exist = Get number of rows
			if exist
				id$ = currentWord$ + currentSpeaker$
				select Table 'tempDf$'
				getRid = alignPoints[id$] - shortest
				nowarn Extract rows where column (number)... Time "greater than" (getRid-time_step/4)
				if word = 1 and s = 1
					Rename... aligned
					len = Get number of rows
					if len < shortestOverall
						shortestOverall = len
					endif
				else
					Rename... current
					len = Get number of rows
					if len < shortestOverall
						shortestOverall = len
					endif
					plus Table aligned
					Append
					select Table aligned
					Remove
					select Table appended
					Rename... aligned
					select Table current
					Remove
				endif
			endif
			select Table 'tempDf$'
			Remove
		endfor
	endfor
	select Table df
	Remove

	if trim_all_trajectories_to_be_the_same_length
		for word from 1 to (wordIdx-1)
			for s from 1 to speakerNum
				currentWord$ = words$[word]
				select Strings speakers
				currentSpeaker$ = Get string... s

				select Table aligned
				Extract rows where column (text)... Rep "is equal to" 'currentWord$'
				tempDf$ = "aligned_" + currentWord$
				select Table 'tempDf$'
				nowarn Extract rows where column (text)... Speaker "is equal to" 'currentSpeaker$'
				select Table 'tempDf$'
				Remove
				tempDf$ = tempDf$ + "_" + currentSpeaker$
				select Table 'tempDf$'
				len = Get number of rows
				if len > 0
					while len > shortestOverall
						Remove row... (shortestOverall+1)
						len = Get number of rows
					endwhile
					if word = 1 and s = 1
						select Table 'tempDf$'
						Rename... trimmed
					else
						select Table trimmed
						plus Table 'tempDf$'
						Append
						select Table trimmed
						plus Table 'tempDf$'
						Remove
						select Table appended
						Rename... trimmed
					endif
				else
					select Table 'tempDf$'
					Remove
				endif
			endfor
		endfor

		select Table aligned
		Remove
	endif
endproc

procedure getTime
	if trim_all_trajectories_to_be_the_same_length
		name$ = "trimmed"
	else
		name$ = "aligned"
	endif
	select Table 'name$'

	rows = Get number of rows
	thisWord$ = "start"
	thisSpeaker$ = "start"
	for row from 1 to rows
		currentWord$ = Get value... row Rep
		currentSpeaker$ = Get value... row Speaker
		if currentWord$ <> thisWord$ or currentSpeaker$ <> thisSpeaker$
			select Table 'name$'
			Set numeric value... row Time -(shortest)
			thisWord$ = currentWord$
			thisSpeaker$ = currentSpeaker$
		else
			select Table 'name$'
			lastTime = Get value... (row-1) Time
			currentTime = lastTime + 1/sampling_rate
			currentTime$ = fixed$(currentTime, 6)
			currentTime = number(currentTime$)
			Set numeric value... row Time currentTime
		endif
	endfor
endproc


procedure getTrimmedFormants fileName$ speaker$ noVoice$ maxFormant numFormant window preEmph
	Create Table with column names... 'fileName$' 0 Rep Word Interval RealTime Time F1 F2 F3 F1_s F2_s F3_s File Speaker
	select Sound 'fileName$'
	To Formant (burg)... 0 numFormant maxFormant window preEmph
    # for assigning values for trimmed arrays
    smoothed_row = 1

	select TextGrid 'fileName$'
	intNum = Get number of intervals... 1
	rowNum = 1

    for int from 1 to intNum
        select TextGrid 'fileName$'
        label$ = Get label of interval... 1 int
        # check for irregular character
        if index_regex(label$, "[^a-zA-Z0-9]")
            exitScript: "There is a special character in the ", int, "th interval of the 1st tier, remove and try again."
        endif
        if length(label$)
            word$ = replace_regex$(label$, "\d", "", 0)

            start = Get start time of interval... 1 int
            end = Get end time of interval... 1 int
            sampleNum = floor((end - start)*sampling_rate)

            for sample from 1 to sampleNum

                time = start + (sample-1)*time_step
                wordTime = sample*time_step - time_step
                select Formant 'fileName$'
                f1 = Get value at time... 1 time hertz Linear
                f2 = Get value at time... 2 time hertz Linear
                f3 = Get value at time... 3 time hertz Linear

                select TextGrid 'fileName$'
                intervalNum = Get interval at time... 2 time
                interval$ = Get label of interval... 2 intervalNum

                select Table 'fileName$'
                Append row

                Set numeric value... rowNum RealTime time
                Set numeric value... rowNum Time wordTime
                Set string value... rowNum Rep 'label$'
                Set string value... rowNum Word 'word$'
                Set string value... rowNum Interval 'interval$'
                Set string value... rowNum File 'fileName$'
                Set string value... rowNum Speaker 'speaker$'

                if interval$ <> non_voiced$
                    Set numeric value... rowNum F1 f1
                    Set numeric value... rowNum F2 f2
                    Set numeric value... rowNum F3 f3
                endif
                rowNum += 1
            endfor

            # trim formants
            select Table 'fileName$'
            Extract rows where column (text)... Rep "is equal to" 'label$'
            tempName$ = fileName$ + "_" + label$
            select Table 'tempName$'
            rows = Get number of rows
            duration = (rows-1)*time_step
            lastRowTime = Get value... rows Time

            if duration > lastRowTime + 0.002
                exitScript: "There are multiple utterances labelled as ", label$, ", please check and try again."
            endif

            # create wordrep array for alignment repetition procedure
            words$[wordIdx] = label$
            wordIdx += 1

            max_bump = 0.1
            max_edge = 0.0

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
                            f1_trimmed = f1_left + (time_step*(f1_right-f1_left))/(time_step*2)
                            f1_smoothed[smoothed_row] = f1_trimmed
                        else
                            f1_smoothed[smoothed_row] = f1_mid
                        endif

                        if (f2_diff1_hump > max_bump and f2_diff2_hump > max_edge) or (f2_diff1_dip > max_bump and f2_diff2_dip > max_edge)
                            f2_trimmed = f2_left + (time_step*(f2_right-f2_left))/(time_step*2)
                            f2_smoothed[smoothed_row] = f2_trimmed
                        else
                            f2_smoothed[smoothed_row] = f2_mid
                        endif

                        if (f3_diff1_hump > max_bump and f3_diff2_hump > max_edge) or (f3_diff1_dip > max_bump and f3_diff2_dip > max_edge)
                            f3_trimmed = f3_left + (time_step*(f3_right-f3_left))/(time_step*2)
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
            select Table 'tempName$'
            Remove
        endif
    endfor

    select Formant 'fileName$'
    Remove

    select Table 'fileName$'
    total_rows = Get number of rows

    for r from 1 to total_rows
        interval$ = Get value... r Interval
        if interval$ <> noVoice$
            Set numeric value... r F1_s f1_smoothed[r]
            Set numeric value... r F2_s f2_smoothed[r]
            Set numeric value... r F3_s f3_smoothed[r]
        endif
    endfor
endproc


procedure smoothFormants smoothNum name$
    for smooth from 1 to smoothNum
        resmoothed_row = 1
        for int from 1 to intNum
            select TextGrid 'name$'
            label$ = Get label of interval... 1 int
            if length(label$)
                select Table 'name$'
                Extract rows where column (text)... Rep "is equal to" 'label$'
                tempName$ = name$ + "_" + label$
                select Table 'tempName$'
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
                select Table 'tempName$'
                Remove
            endif
        endfor
    endfor

    select Table 'name$'
    total_rows = Get number of rows
    for r from 1 to total_rows
        interval$ = Get value... r Interval
        if interval$ <> non_voiced$
            Set numeric value... r F1_s f1_smoothed[r]
            Set numeric value... r F2_s f2_smoothed[r]
            Set numeric value... r F3_s f3_smoothed[r]
        endif
    endfor
endproc