#!/bin/bash
#
# beats - folder specific music-player, written in bash.



# Colors
COL0='\e[0;30m'
COL1='\e[0;31m'
COL2='\e[0;32m'
COL3='\e[0;33m'
COL4='\e[0;34m'
COL5='\e[0;35m'
COL6='\e[0;36m'
COL7='\e[0;37m'
COLR='\e[0m'

# version (YY.MM.DD)
Version=22.12.09

player_start_(){
	# Setup the terminal for the TUI.
	printf '\e[?1049h'	# Use alternative screen buffer.
    	printf '\e[2J'		# Clear the screen.
	printf '\e[?25l'	# Hide the cursor.
	printf '\e[?7l'		# Disable line wrapping.
	printf '\e[1;%sr' "$LINES" # Limit scrolling.
	stty -echo		# Hide echoing of user input
	clear
}

player_exit_(){
	# Kill Player
	if [[ $DontKillPlayer != 'true' ]]; then
		kill $PlayerPID 2>/dev/null
		echo "Status=\"Stopped\"" >> "$CASHE_FILE"
	fi

	# Reset terminal to useable state
    	printf '\e[2J'		# Clear screen.
	printf '\e[?7h'
	printf '\e[?25h'	# Restore cursor.
	printf '\e[;r'		# Rest Scrolling limit.
	printf '\e[?1049l'	# Return to main screen.
	stty echo		# Show echoing of user.
	exit 0
}

search_beats_(){
	# Store beats name into Beat_Name array.
	local Index
	if [[ -z "$1" ]]; then
		unset Beat_Name

		# Leaving 0 Index of Beat_Name(array) empty.
		Beat_Name=("")
		for Index in *; do
			case "$Index" in
				*'.mp3')	Beat_Name+=("$Index") ;;
				*'.opus')	Beat_Name+=("$Index") ;;
				*'.m4a')	Beat_Name+=("$Index") ;;
			esac
		done
		Searched=false
	else
		# Short/Search beats.

		# Search for beats again and then short/search it.
		[[ "$Searched" == 'true' ]] && search_beats_
		unset List
		for Index in "${!Beat_Name[@]}"; do
			[[ "${Beat_Name[$Index]^^}" == *"${1^^}"* ]] && {
			List+=("${Beat_Name[$Index]}")
		}
		done
		unset Beat_Name
		Beat_Name=("")
		Beat_Name+=("${List[@]}")
		Searched=true
	fi
}

draw_screen_(){
	# Reset cursor to the top left edge.
	echo -en "\e[0;0H"

	# List beats and color selected.
	[[ $ListStart -lt 1 ]] && ListStart=0
	for (( i=$ListStart; i<$ListEnd; i++ )); do
		[[ "$i" -lt 1 || $i -gt $Total ]] && Temp="" || Temp="${Beat_Name[$i]%.*}"

		if [[ $Selected -eq $i ]]; then
			echo -en "$COL2${Temp^^}$COLR\e[K\n"
		elif [[ $LastPlayedIndex -eq $i ]]; then
			echo -en "$COL3${Temp}$COLR\e[K\n"
		else
			echo -en "$Temp\e[K\n"
		fi
	done
}

keys_(){
	local Input1 Input2

	# This also defines the update time when the script is Idel.
	read -t 0.9 -rs -N 1 Input1
	read -t 0.01 -rsn5 Input2
	case "$Input1$Input2" in

		# Play selected beat.
		$'\n')
			data_update_ 're'
			case "$Status" in
				'Playing')
					ffplay_play_ "${Beat_Name[$Selected]}"
				;;

				'Paused')
					ffplay_play_ "${Beat_Name[$Selected]}"
				;;

				'Stopped')
					ffplay_play_ "${Beat_Name[$Selected]}"
				;;
			esac
			LastPlayedIndex=$Selected
			;;

		# Pause/resume beat.
		' ')
			case "$Status" in
				'Playing')
					kill $PlayerPID 2>/dev/null
					Status='Paused'
					;;

				'Paused')
					ffplay_play_ "$LastPlayed" "-ss $CurrDuration"
					;;

				'Stopped')
					if [[ "$CurrDuration" != 'Done' ]]; then
						ffplay_play_ "$LastPlayed" "-ss $CurrDuration"
					else
						ffplay_play_ "${Beat_Name[$Selected]}"
						LastPlayedIndex=$Selected
					fi
				;;
			esac

			;;

		# Do nothing.
		# NULL (CTRL + D)
		'') ;;

		# Show time.
		# !Tab must remain below space and enter
		$'\t'|[[:blank:]])
			;;

		# Move selection up.
		$'\e[A'|'k'|'K')
			if [[ $Selected -eq 1 ]]; then
				Selected=1
			else
				Selected=$((Selected-1))
				ListStart=$((ListStart-1))
				ListEnd=$((ListEnd-1))
			fi
		       	;;

		# Move selection down.
		$'\e[B'|'j'|'J')
			if [[ $Selected -eq $Total ]]; then
				Selected="$Total"
			else
				Selected=$((Selected+1))
				ListStart=$((ListStart+1))
				ListEnd=$((ListEnd+1))
			fi
			;;

		$'\E[D')
			printf 'EFT'
			;;

		$'\E[C')
			printf 'RIGHT'
			;;

		# Seek Backward.
		'['|'{')
			local Temp="$(bc <<<"$CurrDuration-$SeekInterval" 2>/dev/null)"

			# Dont let CurrDuration go below 0.
			if [[ $(bc <<<"$Temp < 0" 2>/dev/null) -eq 1 ]]; then
				echo "0" >"$CASHE_FILE2"
			else
				echo "$(awk '{printf "%f", $0}' <<<"$Temp")" >"$CASHE_FILE2"
			fi
			[[ "$Status" == 'Playing' ]] && ffplay_play_ "$LastPlayed" "-ss $(cat $CASHE_FILE2 2>/dev/null)"
			;;

		# Seek Forward.
		']'|'}')
			local Temp="$(bc <<<"$CurrDuration+$SeekInterval" 2>/dev/null)"

			if [[ $(bc <<<"$Temp > $TotalDuration" 2>/dev/null) -eq 1 ]]; then
				echo "$TotalDuration" >"$CASHE_FILE2"
			else
				echo "$(awk '{printf "%f", $0}' <<<"$Temp")" >"$CASHE_FILE2"
			fi
			[[ "$Status" == 'Playing' ]] && ffplay_play_ "$LastPlayed" "-ss $(cat $CASHE_FILE2 2>/dev/null)"
			;;

		# Exit and Stop Music.
		'q'|'Q')
			exit
			;;

		# Refresh.
		'r'|'R')
			COLUMNS=0	# This will break the main loop.
			# LINES=0
			;;

		# Stops Music.
		'x'|'X')
			kill $PlayerPID 2>/dev/null
			Status='Stopped'
			;;

		# Search from listed beats.
		"/")
			unset SInput SOutput
			status_ "/"

			stty echo
			while read -rsn 1 -p $'\e[43m\e[30m'"$SOutput" SInput; do
			printf '\e[0m'	# Reset color.
				case "$SInput" in

					# Backspace
					$'\177'|$'\b')
						SOutput="${SOutput%?}"
						;;

					# Escape.
					$'\e')
						SOutput=""
						break
						;;

					# Enter/Return.
					"")
						break
						;;
					*)
						SOutput="$SOutput$SInput"
						;;
				esac
			status_ "/"
			done
			stty -echo

			# Search beats Contaning given Strings.
			search_beats_ "$SOutput"
			initialise_player_
			;;

		# Quit without stoping Music/Go to Previous Screen.
		$'\E'|$'\e')
			if [[ "$Searched" == 'true' ]]; then
				search_beats_
				initialise_player_
			elif [[ "$Status" == "Playing" ]]; then
				DontKillPlayer=true
				exit
			else
				exit
			fi
		;;
	esac
}

function_(){
	# !Senstive function.
	# Variables and aligned sequently as need,
	# be carefull while making any changes.

	# Variables related beat Duration..
	OldCurrDuration=${CurrDuration:-0}	# Fix the problem, when cat doesn't output anything.
	CurrDuration="$(cat $CASHE_FILE2 2>/dev/null)"
	CurrDuration=${CurrDuration:-$OldCurrDuration}
	[[ "$CurrDuration" == 'Done' ]] && Status='Stopped'	# Thins means, Beat end.
	TotalDuration=${TotalDuration:-0}

	# Variables related progress bar.
	PlayProgress="$(bc <<< "scale=6;$CurrDuration/($TotalDuration/ $COLUMNS)" 2>/dev/null)"
	PlayProgress=${PlayProgress%%.*}
	PlayPercentage="$(bc <<< "scale=2;($CurrDuration/$TotalDuration)*100" 2>/dev/null)%"


	# Modes
	Mode='Shuffle'
	#Mode='Repeat'
	#Mode='Random'
	#Mode='None'

	# Apply Modes, when a beat completed playing.
	case "$Mode-$Status-$CurrDuration" in

		# Shuffle, play one after another.
		'Shuffle-Stopped-Done')
				LastPlayedIndex=$((LastPlayedIndex+1))
				if [[ $LastPlayedIndex -lt 1 ]]; then
					LastPlayedIndex=$Total
				elif [[ $LastPlayedIndex -gt $Total ]]; then
					LastPlayedIndex=1
				fi

				ffplay_play_ "${Beat_Name[$LastPlayedIndex]}"
				SourceData=true
			;;

		# Repeat a particular beat.
		'Repeat-Stopped-Done')
				ffplay_play_ "$LastPlayed"
			;;

		# Randomly play any beat.
		'Random-Stopped-Done')
				local Temp=$((RANDOM%10))
				## WIP
				ffplay_play_ "${Beat_Name[$Temp]}"
			;;
	esac


	# This must remain below Mode function.
	[[ "$CurrDuration" == 'Done' ]] && CurrDuration=0

	# Source data files when needed.
	if [[ "$SourceData" == 'true' ]]; then
		data_update_ 'sr'
		SourceData=false
	fi
}

data_update_(){
	case "$1" in

		# Removes/Empty data.
		're')
			printf '' >$CASHE_FILE
			printf '' >$CASHE_FILE2
			unset CurrDuration TotalDuration 2>/dev/null
			unset DurationH DurationM DurationS 2>/dev/null
			# Don't unset PlayerPID and LastPlayed as, they are
			# needed for misc tasks(kill ffplay) and for next start.
			;;

		# Creates data file.
		'cr')
			touch /tmp/beats.cashe /tmp/beats2.cashe 2>/dev/null
			CASHE_FILE="/tmp/beats.cashe"
			CASHE_FILE2="/tmp/beats2.cashe"
			;;

		# Source data file.
		'sr')
			# Loop until data file exist.
			until [[ -e "$CASHE_FILE" ]]; do
				sleep 0.1
			done

			# Loop until relational variables are initialised.
			while [[ -z $DurationS ]]; do
				sleep 0.1
				source "$CASHE_FILE" 2>/dev/null
			done
			;;

		# Update data.
		*)
			# Seprates every character.
			for (( i=0; i<${#1}; i++ )); do
				arg[$i]=${1:$i:1}
			done

			for i in "${!arg[@]}" ; do
				case "${arg[i]}" in

					# Exceptional case, in which 2nd argument is required.
					# L = LastPlayed
					'L'|'l')
						echo "LastPlayed=\"$2\"" >> "$CASHE_FILE"
						;;

					# I = PlayerPID
					'I'|'i')
						echo "PlayerPID=\"$PlayerPID\"" >> "$CASHE_FILE"
						;;

					# A = Status
					'A'|'a')
						echo "Status=\"$Status\"" >> "$CASHE_FILE"
						;;

					# H = Duration Hour
					'H'|'h')
						echo "DurationH=\"${Duration[0]}\"" >> "$CASHE_FILE"
						;;

					# M = Duration Minute
					'M'|'m')
						echo "DurationM=\"${Duration[1]}\"" >> "$CASHE_FILE"
						;;

					# S = Duration Seconds
					'S'|'s')
						echo "DurationS=\"${Duration[2]}\"" >> "$CASHE_FILE"
						;;

					# T = Total Duration
					'T'|'t')
						echo "TotalDuration=\"$(bc <<< "(${Duration[0]} * 3600) + \
										(${Duration[1]} * 60.0) + \
										${Duration[2]}" |\
										awk '{printf "%f", $0}')\"" >> "$CASHE_FILE"
						;;
				esac
			done

			;;
	esac

}

ffplay_play_(){
	# If file is moved, Don't do anything.
	if [[ -e "$1" ]]; then

		# Kill Previously playing beat, if any.
		kill $PlayerPID 2>/dev/null
		ffPlayErr=false

		ffplay -nodisp -autoexit $2 "$1" 2>&1 | ffplay_parse_ &

		PlayerPID="$!"
		local Temp=false

		for (( i=0; i<15; i++ )); do
			if [[ -e /tmp/beatsffparsing ]]; then
				continue
			else
				Temp=true
				LastPlayed="$1"
				Status='Playing'
				data_update_ 'LIA' "$1"
				SourceData=true
				break
			fi
			sleep 0.1
		done

		[[ $Temp == 'false' ]] && ffplayErr=true
	else
		status_ "Beat don't exist anymore."
		sleep 0.5
	fi
}

ffplay_parse_(){

	touch /tmp/beatsffparsing

	# Once-time parse.
	while read -s LINES; do
		Words=($LINES)

		# Get beats playing duration.
		if [[ "${Words[0]}" == "Duration:" ]]; then
			IFS2="$IFS"
			IFS=:
			read -a Duration <<< "${Words[1]//,/}"
			IFS="$IFS2"
		elif [[ "${Words[0]}" == "Stream" ]]; then
			break
		elif [[ "$ffplayErr" == 'true' ]]; then
			break
		fi
	done

	rm /tmp/beatsffparsing

	# Don't use data_update_ function here, it will
	# conflict with same function, inside ffplay_play_
	echo "DurationH=\"${Duration[0]}\"" >> "$CASHE_FILE"
	echo "DurationM=\"${Duration[1]}\"" >> "$CASHE_FILE"
	echo "DurationS=\"${Duration[2]}\"" >> "$CASHE_FILE"
	echo "TotalDuration=\"$(bc <<< "(${Duration[0]} * 3600) + \
					(${Duration[1]} * 60.0) + \
					${Duration[2]}" 2>/dev/null |\
					awk '{printf "%f", $0}' 2>/dev/null)\"" >> "$CASHE_FILE"

	# Loop Until numbers(Current Duration) appears.
	while read -r -d $'\r' Index; do
		[[ "${Index%%.*}" == [0-9]* ]] && break
	done

	# Loop Parse(Loop until Music is Stops/Ends).
	while read -r -d $'\r' Index; do
		echo -en "${Index%% *}" > "$CASHE_FILE2"
	done

	echo -en "Done" > "$CASHE_FILE2"	# When done playing.
}

status_(){
	# Show given custom text if given or else show default status.
	if [[ $# -gt 0 ]]; then
		printf '\e[%s;0H\e[43m%*s\r\e[30m' "$LINES" "$COLUMNS"
		echo -en "$@\e[m"

	else
		## Default status.

		# Progress Bar.
		printf '\e[%s;0H\r' "$((LINES-1))"
		echo -en "\e[K"
		for (( i=0; i<${PlayProgress:-0}; i++ )); do
			echo -n "-"
		done
		echo -en ">\e[m"

		# Status Bar.
		printf '\e[%s;0H\e[42m%*s\r\e[30m' "$LINES" "$COLUMNS"
		echo -n "$Selected/$Total ${TotalDuration%%.*}s/${CurrDuration%.*}s  $Status $LastPlayedIndex"
		echo -en "\e[m"
	fi
}

initialise_player_(){
	Total="$((${#Beat_Name[@]} - 1))"	# Exclude empty Beat_Name array with index 0.
	ListStart=1
	ListEnd="$((LINES-1))"			# Two lines are reserved by status

	# Select the available beat if there are one.
	case "$Selected" in
		"")
		if [[ $Total -eq 1 ]]; then
			Selected=1
		elif [[ $Total -lt $ListEnd ]]; then
			# If beats are less than terminal Length(LINES).
			Selected="$((Total/2+1))"
		else
			# Select Middle if n(beats) are more than termianl length(LINES).
			Selected="$((ListEnd/2))"
		fi
		;;
	esac
}

arguments_(){
	# Argument Handler
	local Num=$#
	for (( i=0; i<$Num; i++ )); do
		case "$1" in
			# Check if user need help.
			'-h'|'--help')
				echo "Can't help right now."
				exit 0
				;;
			'-v'|'--version')
				printf '%s\n' "$Version"
				exit 0
				;;
			*)
				# Play beat directly if specified and exists.
				if [[ -f "$1" ]]; then
					## direct play
					echo "not done yet"
					exit
				# Load beats from specified directory.
				elif [[ -d "$1" ]]; then
					BEATS_DIRECTORY="${1//\~/$HOME}"
				else
					printf 'beats: error: Unknown option or file: %s\n' "$1" 1>&2
					exit 2
				fi
		esac
		shift
	done
}


main_(){
	local STIME=$(date +%s.%N)	# Start Time.

	HERE="$(dirname "$0")"
	PLAYER_LOC="$(readlink -f "$HERE")"
	PWD="$(pwd)"

	# Setup Data Files
	data_update_ 'cr'
	source "$CASHE_FILE"

	# Get termwindow Geometry.
	read -r LINES COLUMNS < <(stty size)

	# Search beats in PWD or in specified directory.
	# If PWD is /bin or /sbin then in ~/Music.
	[[ "$HERE" != "/bin" || "$HERE" != "/sbin" ]] && BEATS_DIRECTORY="${BEATS_DIRECTORY:-"$PWD"}"
	cd "${BEATS_DIRECTORY:-$HOME/Music}"

	# Search for beats in that directory and
	# initialise the player to list them.
	search_beats_
	initialise_player_

	# Get the Index of last played beat.
	for (( i=1; i<=$Total; i++ )); do
		if [[ "${Beat_Name[$i]}" == "${LastPlayed}" ]]; then
			LastPlayedIndex="$i"
			break
		fi
	done

	SourceData=false		# If cashe file is sourced.
	SeekInterval='5'		# 5 Seconds
	OldCurrDuration=0
	Status="${Status:-Stopped}"

	local ETIME=$(date +%s.%N)	# End Time.
	STARTTIME=$(bc <<<"scale=3;($ETIME-$STIME)" 2>/dev/null | awk '{printf "%f", $0}' 2>/dev/null)

	while true; do
		[[ "$(stty size)" != "$LINES $COLUMNS" ]] && break

		function_
		draw_screen_
		status_
		keys_

	done
}

[[ $# -gt 0 ]] && arguments_ "$@"

# Functions to run on start and exit.
trap player_exit_ EXIT
player_start_

while true; do main_ ; done
