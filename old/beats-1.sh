#! /bin/bash




# predefine
Version=2.0.0
lastupdated="2 DEC 2021"
pwd1=$PWD
Red='\033[0;31m'
Purple='\033[0;35m'
Grey='\033[0;37m'
Lblue='\033[0;36m'
Brown='\033[0;33m'
Noc='\033[0m'


cd


# Note while playing music
title() {
	clear
	echo -e "${Purple}" '   ____             __      \n   / __ )___  ______/ /______\n  / __  / _ \/ __  / __/ ___/\n / /_/ /  __/ /_/ / /_(__  ) \n/_____/\___/\____/\__/____/ '  "${Noc}"
	sleep 0.2
	echo
	echo
	echo -e "$Brown \bType CTRL+c to exit $Noc"
}

# Note after exit
afterexit() {
	clear
	echo -e "$Brown \bPlayed beat location: $pwd2 $Noc"

}

# Animation while playing music
animation() {
	chars="◷◶◵◴"
	while :; do
  	for (( i=0; i<${#chars}; i++ )); do
	    sleep 0.4
	    echo -en "$Brown \bPlaying Beat from $pwd2 $Noc ${chars:$i:1}" "\r"
	    loo=4
	done
	done
}

# Core of music playing system
playmusic() {
	# select method to play music
	if [[ -e $pwd1/beatinp ]]; then
		if [[ -e /bin/beatinp ]]; then
			echo 
		else
			sudo cp $pwd1/beatinp /bin
		fi
		playmethod="beatinp"
	elif [[ -e /bin/beatinp ]]; then
			playmethod="beatinp"
	elif [[ -e /bin/ffplay ]]; then
		playmethod="ffplay"
	else
		clear
		echo -e "$Red \bOpps! depedency file not exist"
		echo
		echo -e "$Red \bPlease either install ffplay, or copy \"beatinp\" file from https://github.com/Randomguy-8/Beats into $pwd1/"
		exit
	fi
pwd2=$PWD
if [[ -e $b ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b | animation
	afterexit
elif [[ -e $b\ $c ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b\ $c | animation
elif [[ -e $b\ $c\ $d ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b\ $c\ $d | animation
elif [[ -e $b\ $c\ $d\ $e ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b\ $c\ $d\ $e | animation
elif [[ -e $b\ $c\ $d\ $e\ $f ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b\ $c\ $d\ $e\ $f | animation
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b\ $c\ $d\ $e\ $f\ $g | animation
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g\ $h ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b\ $c\ $d\ $e\ $f\ $g\ $h | animation
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i | animation
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i\ $j ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i\ $j | animation
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i\ $j\ $k ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i\ $j\ $k | animation
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i\ $j\ $k\ $l ]]
then
	title
	$playmethod -nodisp >/dev/null 2>&1 $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i\ $j\ $k\ $l | animation
else
	clear
	echo -e "$Red \bOpps! file not found $Noc"
fi
}

# cheks if music exist or not
musicexist() {
if [[ -e $b ]]
	then
	pwd2=$PWD
elif [[ -e $b\ $c ]]
	then
	pwd2=$PWD
elif [[ -e $b\ $c\ $d ]]
	then
	pwd2=$PWD
elif [[ -e $b\ $c\ $d\ $e ]]
	then
	pwd2=$PWD
elif [[ -e $b\ $c\ $d\ $e\ $f ]]
	then
	pwd2=$PWD
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g ]]
	then
	pwd2=$PWD
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g\ $h ]]
	then
	pwd2=$PWD
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i ]]
	then
	pwd2=$PWD
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i\ $j ]]
	then
	pwd2=$PWD
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i\ $j\ $k ]]
	then
	pwd2=$PWD
elif [[ -e $b\ $c\ $d\ $e\ $f\ $g\ $h\ $i\ $j\ $k\ $l ]]
	then
	pwd2=$PWD
else
	cd $pwd1
	pwd2=$PWD
fi
}

# Main page here
b=$1
c=$2
d=$3
e=$4
f=$5
g=$6
h=$7
i=$8
j=$9


# If given input is a Directory or a regular file
if [[ -d $1 ]]; then
	clear
	echo -e "$Red \bIts a directory not a file!$Noc"
else
	# Taking specific arguments (-about, -help)
	if [[ $1 = "-about" ]] || [[ $1 = "-a" ]]; then
		sleep 0.4 && echo "beat 		- A simple bash scripted Music player" && exit
	elif [[ $1 = "-help" ]] || [[ $1 = "-h" ]]; then
		sleep 0.4 && echo -e "Beat is a simple bash based Music player \n\n++ About\n\n  Version = $Version \n  Build date = $lastupdated \n\n++ If you need any further help check: https://github.com/Randomguy-8/Beats"
	elif [[ $1 = "-"* ]]; then
		sleep 0.4
		echo -e "\"$0 -a\" $Grey 	- About $Noc"
		echo -e "\"$0 -h\" $Grey 	- Help $Noc"
	# Checks if $1 is null or not
	elif [[ -z $1 ]]; then
		clear
		echo -n -e "$Lblue \bFile: $HOME/$Noc" && read b c d e f g h i j k l
		if [[ -z $b ]]; then
			clear
			echo -n -e "$Lblue \bFile from root: $Noc" && read b c d e f g h i j k l
		fi
		clear
		musicexist
		playmusic
	else
		clear
		musicexist
		playmusic

	fi
fi
