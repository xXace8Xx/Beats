#!/bin/bash


### Code Style ###
#
# function_	# Function
# VARIABLE	# Unchangeable Variable
# Variable	# Changeable Variable
# Array_	# Array


# Regular
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
pre_beats_(){
	for (( i=0; i<=$Total; i++)); do
		Beat2_[$i]="$(center_sim_ "${Beat_[$i]%.*}")"
	done
	[[ -z "$Status" ]] && Status="Stopped"
}

beats_(){
	local i Temp
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
		"SPACE"|"ENTER")
			play_ "${Beat_[$Selected]}"
			[[ "$Status" == "P"* ]] && Status="Stopped" || Status="Playing"
			;;
		"/")
			input_ "/"
			search_ "${Beat_[$@]}" "$Temp"
			;;
		":")
			input_ ":"
			if [[ "$Input" == [0-9]* && "$Input" != *[a-zA-Z]* ]]; then
				[[ "$Input" -gt "$Total" ]] && Selected="$Total" || Selected="$Input"
				[[ "$Input" -lt 1 ]] && Selected="1"
				ListStart="$((Selected-(Lines/2)+1))"
				ListEnd="$((ListStart+(Lines-1)))"
			elif [[ "$Input" == '!'* ]]; then
				clear
				echo "${Input##*!}" | ${SHELL:-"/usr/bin/sh"}
				read -rsn1 -p "Press ENTER to continue." Temp
			elif [[ "$Input" == 'q' ]]; then
				clear
				exit
			elif [[ -z "$Input" ]]; then
				Event=""
			else
				status_ "Not an Player's command: ${Input}"
				sleep 1
			fi
			;;
	esac

	echo -en "\e[0;0H" # Reset cursor
	for (( i=$ListStart; i<$ListEnd; i++ )); do
		[[ "$i" -lt 1 || $i -gt $Total ]] && Temp="$Line0" || Temp="${Beat2_[$i]}"
		[[ $Selected -eq $i ]] && printf "$Red${Beat2_[$i]^^}$Noc" || printf "$Temp"
	done
	Current="$(ps -eo "%t %c" | grep ffplay)"
	Current="${Current:-"345678"}"
	status_ "$Status $Selected $Total [$ListStart-$ListEnd] $Duration ${Current:: -6} $Event"
}

search_(){  # 1=List | 2=Pattern
	local Temp
	clear
	Temp=$(echo "${Beat_[$@]}" | grep -n *$2* | head -n 1 | cut -d: -f1)
	echo "$Temp"
	exit
}

status_(){  # $1=Parameters
	local Temp
	[[ "${#1}" -gt "$Columns" ]] && Temp="${1:: $((Columns))}" || Temp="$1"
	echo -en "\e[${Lines};1H${Temp}\e[K"
}

play_(){  # $1=Beat
	local Temp
	ffplay -nodisp -hide_banner -autoexit "$1" 1>/dev/null 2>/tmp/beats.cashe &
	PlayerPID="$!"
	sleep 1
	Temp="$(cat /tmp/beats.cashe | grep Duration)"
	Temp="${Temp#*:}"; Temp="${Temp%%.*}"
	Duration="$Temp"
}

initialize_(){  # 1=Playlist
	local Temp
	unset Beat_

	cd ${Playlist_[$1]}
	status_ "Searching..."

	for Temp in ${Extension[@]}; do Beat_+=("$Temp"); done
	Total="${#Beat_[@]}"

	ListStart=0
	ListEnd="$((Lines-1))"
	[[ "$Total" -le 1 ]] && Selected=1 || Selected=$(( (ListEnd)/2  ))
	Line0="$(center_sim_)"
}

event_(){
	local Temp1 Temp2
	read -t 0.1 -rs -N 1 Event1
	case "$Event1" in
		[[:graph:]])	Event="$Event1"	;;
		$'\n')		Event="ENTER"	;;
		' ')		Event="SPACE"	;;
		'')		Event=""	;;
		[[:blank:]])	Event="TAB"	;; # TAB must remain below SPACE and ENTER
		*)
			read -t 0.01 -rsn5 Event2
			case "$Event2" in
				"[A")		Event="UP" 		;;
				"[B")		Event="DOWN"		;;
				"[D")		Event="LEFT"		;;
				"[C")		Event="RIGHT"		;;
				"[P"|"[3~")	Event="DEL"		;;
				"[4h"|"[2~")	Event="INS"			;;
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
					case "$Event1$Event2" in
						$'\E')		Event="ESC"	;;
						$'\177'|*)	Event="BCKSPC"	;; # Remaining keys will be treated as Backspcae
					esac
					;;
			esac
		;;
	esac
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
			" ") Temp=' ' ;;
			[[:graph:]]) Temp=$Temp  ;;
			*) Temp="" ;;
		esac
	done
	Input="$Temp2"
}

start_(){
	stty -echo; printf "\e[?25l" # Disable Cursor
}

exit_(){
	stty echo; printf "\e[?25h" # Enables Cursor
}

main_(){ clear
	trap exit_ EXIT
	start_

	Extension=(*.mp3 *.m4a)
	Playlist_=($HOME/Projects/beats/Music/\
		$HOME/Projects/beats/Music/new/\
		$HOME/Projects/beats/Music/new2/\
		$HOME/Music/
		)
	## Page: A function that display content on basis of given condition or event
	## Prepage: Onetime fuctions that setup some components of pages
	Page_[0, 0]="beats_"
	Page_[0, 1]="pre_beats_"

	read -r Lines Columns < <(stty size)
	Shuffel=1 InfScroll=0 DebugBar=1

	initialize_ 3 # Default Playlist

	CurrPage=0
	${Page_[$CurrPage, 1]}

	while true; do
		[[ "$(stty size)" != "$Lines $Columns" ]] && break
		${Page_[$CurrPage, 0]}
		event_
	done
}

while true; do main_ "@"; done
