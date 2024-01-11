#!/bin/bash

phase_it(){
	while read -rs Index; do
		echo "$Index" >>data2
		[[ "$Index" == "Stream"* ]] && {
			break
		}
	done

	while read -r -d $'\r' Index; do
		echo -en "[ ${Index%% *} ]" >data
	done
}

ffplay -nodisp -autoexit "$@" 2>&1 | phase_it
