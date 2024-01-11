#!/usr/bin/env bash

# Add config
## improve appearnce (colors) == Done on [1-7-2022]
### Adding Dev.debug line == Done
# Adding more status (play, pause, stop, repaly, shuffel)
## Improving functionality == Done on [30-6-2022] [21-7-2022]
## Setting right key for right functions(vim keybindings) = Done
# Documentation
# Adding Short by (List by Alphabet, size, album)
## Allow window to resize upto 1 line and 10 columns = Done
# Can take ininteractive inputs
## Cleaning Code - (Rearranging functions, removing useless code, ) = Done on [10-6-2022] [30-6-2022] [21-7-2022] [17-10-2022]


### Code Style ###
#
# function_	# Function
# VARIABLE	# Unchangeable Variable
# Variable	# Changeable Variable
# Array_	# Array

Black='\e[0;30m'; Red='\e[0;31m'
Green='\e[0;32m'; Yellow='\e[0;33m'
Blue='\e[0;34m'; Purple='\e[0;35m'
Cyan='\e[0;36m'; White='\e[0;37m'
Noc='\e[0m'

Version=22.6.6

center_sim_(){  # $1=text
	local Temp i j
	Temp="${#1}"
       	j=$(( (Columns/2)-(Temp/2) ))

	for (( i=0; i<$j; i++ )); do printf ' '; done
	[[ "$Temp" -gt "$Columns" ]] && printf "${1:: $((Columns-3))}..." || printf "$1"
	for (( i=0; i<$(( Columns-(j+Temp) )); i++ )); do printf ' '; done
}

center_abs_(){  # $1=Line | $2=Text | $3=Parameters | $4=Column
	local Temp k
	Temp="${#k}"; k="$2"

	[[ -z $4 ]] && CentCol=$(( (Columns/2) - (${#k}/2) + 1)) || CentCol=$4
	[[ "$Temp" -gt "$Columns" ]] && k="${k::$((Columns-3))}..."

	echo -e $3 "$Noc\e[${1};${CentCol}H$k$Noc"
}

filter_(){
	local Temp
	case "$Input" in
		*)
			for ((i=0; i<$Total; i++)); do
				[[ "${Beat2_[$i]}" == *$Input* ]] && Filters_+="${Beat2_[$i]}"
			done
			;;
	esac
	echo -en "\e[0;0H" # Reset cursor
	for (( i=0; i<${#Filters_[@]}; i++ )); do
		[[ "$i" -lt 0 || $i -gt ${#Filters_[@]} ]] && Temp="\e[K\n" || Temp="${Filters_[$i]}"
		[[ $Selected -eq $i ]] && printf "$Red${Filters_[$i]^^}$Noc" || printf "$Temp"
	done

}

beats_(){
	local i Temp
	case "$Event" in
		":")
			input_ ":"
			if [[ "$Input" =~ ^[0-9]+$ ]]; then
				[[ "$Input" -gt "$Total" ]] && Selected="$Total" || Selected="$Input"
				[[ "$Input" -lt 0 ]] && Selected="0"
				ListStart="$((Selected-(Lines/2)+1))"
				ListEnd="$((ListStart+(Lines-1)))"
				Input=""
			fi
			case "$Input" in
				"") Event="";;
				"!"*)
					clear
					echo "${Input##*!}" | ${SHELL:-"/usr/bin/sh"}
					read -rsn1 -p "Press ENTER to continue."
					;;
				"play "*)
					Input="${Input##play }"
					if [[ "$Input" =~ ^[0-9]+$ ]]; then
						play_ "${Beat_[$Input]}"
					else
						if [[ -e "$Input" ]]; then
							play_ "$Input"
						else
							status_ "Not found! \"$Input\""
							sleep 0.5
						fi
					fi
					;;
				"q") Event="q" ;;
				"s") Event="s" ;;
				"r") Event="r" ;;
				"Volp") Event="h" ;;
				"Volm") Event="l" ;;
				"/"*) Event="$Input" ;;
				*) status_ "Not an Player's command: ${Input}"; sleep 0.8 ;;
			esac
	esac

	case "$Event" in
		"UP"|"k")
			if [[ $Selected -eq 0 ]]; then
				Selected=0
			else
				Selected=$((Selected-1))
				ListStart=$((ListStart-1))
				ListEnd=$((ListEnd-1))
			fi
		       	;;
		"DOWN"|"j")
			if [[ $Selected -eq $Total ]]; then
				Selected="$Total"
			else
				Selected=$((Selected+1))
				ListStart=$((ListStart+1))
				ListEnd=$((ListEnd+1))
			fi
			;;
		"h"|"LEFT")
			amixer set Master 1%- 1>/dev/null 2>/dev/null
			;;
		"l"|"RIGHT")
			amixer set Master 1%+ 1>/dev/null 2>/dev/null
			;;
		"ENTER")
			kill "$PlayerPID" 1>/dev/null 2>/dev/null
			play_ "${Beat_[$Selected]}"
			;;
		"SPACE")
			case "$Status" in
				"Playing")
					CurrTime="$CTot"
					Selected="$CurrPlaying"
					kill "$PlayerPID" 1>/dev/null 2>/dev/null
					Status="Paused"
					;;
				"Paused")
					play_ "${Beat_[$CurrPlaying]}" "-ss $CurrTime"
					;;
			esac
			;;
		"s") [[ "$Shuffel" -eq 1 ]] && Shuffel=0 || Shuffel=1 ;;
		"/"*) input_ "/"; Refresh=1 ;;
		"r") Refresh=1 ;;
		"q") exit_ ;;
	esac

	list_ "Beat2_" $ListStart $ListEnd

	# Get current played time
	Current="$(ps -eo "%t %c" 2>/dev/null | grep ffplay 2>/dev/null)"
	if [[ -z "$Current" && $DTot -ne 0 && "$Status" != "Stopped" ]]; then
		Status="Stopped"
		rm /tmp/beats.cashe 2>/dev/null
		[[ $Shuffel -eq 1 ]] && shuffel_
	fi
	Current="${Current// /}"; Current="${Current/ffplay/}"
	Current="${Current:-"00:00:00"}"
	[[ "$Current" != ???????? ]] && Current="00:${Current}"
	CSec="${Current: -2}"
	CMin="${Current: 3:2}"
	CHour="${Current:: 2}"
	CTot=$(bc <<<"$CSec+($CMin*60)+($CHour*120)"  2>/dev/null)
	Volume=$(amixer get Master 2>/dev/null | tail -n1  2>/dev/null | sed -r "s/.*\[(.*)%\].*/\1/"  2>/dev/null)
	DS=$(cat /tmp/beats.cashe 2>/dev/null)
	DN=$(cat /tmp/beats.now 2>/dev/null)
	status_ "${Green}$Status $Total (${Volume}%) [$Shuffel] | $DN $DS | {$ListStart-$ListEnd:$Selected} <$CurrPlaying> $DTot/$CTot  $Event"
}

list_(){ # 1=ArrayName | 2=Start | 3=End
	local Temp Temp2 i
	Temp=$1[@]
	Temp=("${!Temp}")

	echo -en "\e[0;0H" # Reset cursor
	for (( i=$2; i<$3; i++ )); do
		[[ $i -lt 0 || $i -gt ${#Temp[@]} ]] && Temp2="\e[K\n" || Temp2="${Temp[$i]}"
		[[ $Selected -eq $i ]] && printf "$Red${Temp[$i]^^}$Noc" || printf "$Temp2"
	done
}

status_(){  # 1=Parameters
	local Temp
	[[ "${#1}" -gt "$Columns" ]] && Temp="${1:: $((Columns))}" || Temp="$1"
	echo -en "\e[${Lines};1H${Temp}${Noc}\e[K"
}

initialize_(){  # 1=Playlist
	local Temp
	unset Beat_

	cd "${Playlist_[$1]}"
	status_ "Searching..."
	Beat_=( $(ls *.m4a *.mp3 *.opus 2>/dev/null) )

	for Temp in "$(($Beat_))"; do Beat_+=("$Temp"); done
	Total="${#Beat_[@]}"

	ListStart="${ListStart:-"0"}"
	ListEnd="${ListEnd:-"$((Lines-1))"}"
	[[ "$Total" -le 1 ]] && Selected="${Selected:-"1"}" || Selected="${Selected:-"$((ListEnd/2))"}"

	## pre_beats_
	for (( i=0; i<=$Total; i++)); do
		Beat2_[$i]="$(center_sim_ "${Beat_[$i]%.*}")"
	done
	Status="${Status:-"Stopped"}"
}

shuffel_(){
	exit
	CurrPlaying=$((CurrPlaying+1))
	play_ "${Beat_[$CurrPlaying]}"
}

play_inf_(){
	local Temp
	while read LINE
	do
		WORDS=($LINE)
		CHECK=${WORDS[0]}
		if [ "$CHECK" = "Duration:" ] ; then
        		IFS=',' read -ra PARSE_TEMP <<< "${WORDS[1]}"
        		DURATION_HHMMSS="${PARSE_TEMP[0]}"

        		IFS=':' read -ra HMS <<< "${DURATION_HHMMSS}"
        		DURATION_HH="${HMS[0]}"
        		DURATION_MM="${HMS[1]}"
        		DURATION_SS="${HMS[2]}"

        		DURATION_SECONDS=$(bc <<< "($DURATION_HH * 3600.0) + ($DURATION_MM * 60.0) + $DURATION_SS")
			echo "$DURATION_SECONDS" >/tmp/beats.cashe
		fi
	done
	unset WORDS
      WORDS=($LINE)
      STAMP=${WORDS[0]}
      if [ "$STAMP" != "Seek" ] && [ "$STAMP" != "nan" ]  && [ "${WORDS[1]}" != "@" ] ; then


         if [ $(echo "$STAMP <= 0.0" | bc) -eq 1 ] ; then
            STAMP=0.0
         elif [ $(echo "$STAMP >= $DURATION_SECONDS" | bc) -eq 1 ] ; then
            STAMP="$DURATION_SECONDS"
         fi
         echo $STAMP > /tmp/beats.now

      fi
}
play_(){  # $1=Beat | $2=Parameters
	Status="Playing"
	CurrPlaying="$Selected"
	ffplay -nodisp -autoexit $2 "$1" 3>&1 1>&2 2>&3 | play_inf_ &
	PlayerPID="$!"

	# Get Duration
	until [[ -e "/tmp/beats.cashe" ]]; do sleep 0.5; done
	sleep 0.5
	Duration="$(cat /tmp/beats.cashe | grep Duration)"
	Duration="${Duration#*:}"; Duration="${Duration%%.*}"
	Duration="${Duration:-"00:00:00"}"
	Duration="${Duration// /}"
	DSec="${Duration: -2}"
	DMin="${Duration: 3:2}"
	DHour="${Duration:: 2}"
	DTot=$(bc <<<"$DSec+($DMin*60)+($DHour*120)")
}

input_(){  # $1 Placeholder
	local Temp Temp2
	while true; do
		Temp2+="$Temp"
		status_ "${1}${Temp2}${Blue}|$Noc"
		read -rs -N 1 Temp
		case "$Temp" in
			$'\n') break ;;
			$'\E') Temp2=""; break ;;
			$'\177') [[ -z "$Temp2" ]] || Temp2="${Temp2::-1}"; Temp="" ;;
			" ") Temp=' ' ;; [[:graph:]]) Temp=$Temp  ;;
			*) Temp="" ;;
		esac
	done
	Input="$Temp2"
}

event_(){
	local Temp1 Temp2
	read -t 0.5 -rs -N 1 Temp1
	case "$Temp1" in
		[[:graph:]])	Event="$Temp1"	;;
		$'\n')		Event="ENTER"	;;
		' ')		Event="SPACE"	;;
		'')		Event=""	;;
		[[:blank:]])	Event="TAB"	;; # TAB must remain below SPACE and ENTER
		*)
			read -t 0.01 -rsn5 Temp2
			case "$Temp2" in
				"[A")		Event="UP" 		;;
				"[B")		Event="DOWN"		;;
				"[D")		Event="LEFT"		;;
				"[C")		Event="RIGHT"		;;
				"[P"|"[3~")	Event="DEL"		;;
				"[4h"|"[2~")	Event="INS"		;;
				"[4~"|"[F")	Event="END"		;;
				"[H")		Event="HOM"		;;
				"[5~")		Event="PGUP"		;;
				"[6~")		Event="PGDO"		;;
				"OP")		Event="F1"		;;
				"OQ")		Event="F2"		;;
				"OR")		Event="F3"		;;
				"OS")		Event="F4"		;;
				"[15~")		Event="F5"		;;
			       	"[17~")		Event="F6"		;;
				"[18~")		Event="F7"		;;
				"[19~")		Event="F8"		;;
				"[20~")		Event="F9"		;;
				"[21~")		Event="F10"		;;
				"[23~")		Event="F11"		;;
				"[24~")		Event="F12"		;;
				*)
					case "$Temp1$Temp2" in
						$'\E')		Event="ESC"	;;
						$'\177'|*)	Event="BCKSPC"	;; # Remaining keys will be treated as Backspcae
					esac
					;;
			esac
		;;
	esac
}

start_(){
	stty -echo; printf "\e[?25l" # Disable Cursor
}

exit_(){
	clear
	kill "$PlayerPID" 2>/dev/null
	stty echo; printf "\e[?25h" # Enables Cursor
	exit
}

main_(){
	clear
	trap exit_ EXIT
	start_

	Extension=(*.mp3 *.m4a *.opus)
	Playlist_=($HOME/Projects/beats/Music/\
		$HOME/Projects/beats/Music/new/\
		$HOME/Projects/beats/Music/new2/\
		$HOME/Music/
		)

	read -r Lines Columns < <(stty size)
	Shuffel=1
	Repeat=0
	Backgrounded=0
	[[ -e "/tmp" ]] && Tmp="/tmp" || Tmp="/dev/shm"

	initialize_ 0 # Default Playlist

	while true; do
		[[ "$(stty size)" != "$Lines $Columns" || $Refresh -eq 1 ]] && Refresh=0 && break
		beats_
		event_
	done
}

while true; do main_ "@"; done
