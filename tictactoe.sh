#! /bin/bash
## Tic tac toe game
## Copyright Koen Prange, 2023

##=============================================================
##=============================================================
## Function definition section

##=============================================================
# Function to draw the game board given a 'board' array as input
function draw.board {
	THEBOARD=( "$@" )
	echo ""
	echo "    1   2   3"
	echo "  +---+---+---+"
	echo "A | ${THEBOARD[0]} | ${THEBOARD[1]} | ${THEBOARD[2]} |"
	echo "  +---+---+---+"
	echo "B | ${THEBOARD[3]} | ${THEBOARD[4]} | ${THEBOARD[5]} |"
	echo "  +---+---+---+"
	echo "C | ${THEBOARD[6]} | ${THEBOARD[7]} | ${THEBOARD[8]} |"
	echo "  +---+---+---+"
	echo ""
}

##=============================================================
# Function to execute a move by a human player given their mark and a 'board' array as input
function do.player.logic {
	MARK=$1
	shift
	THEBOARD=( "$@" )
	
	# Record a valid move
	VALID_MOVE=0
	while [[ $VALID_MOVE == "0" ]]
	do
		MOVE=0
		while [[ ! "$MOVE" =~ ^[a-cA-C][1-3]$ ]]
		do
			# Get user input
			read -n 2 -p "Input tile coord (A1..C3):" MOVE
			echo "" >&2
			if [[ ! "$MOVE" =~ ^[a-cA-C][1-3]$ ]]
			then
				echo "Please enter valid tile coords!" >&2
			fi
		done
		# Convert to board array index
		MOVE=$(tile.index $MOVE)
		
		# Check if this tile was still empty	
		if [[ "${THEBOARD[$MOVE]}" == "." ]]
		then
			VALID_MOVE=1
		else
			echo "Tile already played! Please choose another..." >&2
		fi
	done
	
	# Update the board
	THEBOARD[$MOVE]=$MARK
	
	# Broadcast the move
	echo "$MARK plays: $(tile.coord $MOVE)" >&2
	
	# Return the board
	echo ${THEBOARD[@]} 
}

##=============================================================
# Function to execute a move by the CPU player given their mark and a 'board' array as input
function do.CPU.logic {
	MARK=$1
	shift
	THEBOARD=( "$@" )
	
	# Play the move with the requested CPU strength
	case $CPU_LEVEL in
		1)
		THEBOARD=( $(Qui.Bot.Jin $MARK ${THEBOARD[@]}) )
		;;
		
		2)
		THEBOARD=( $(Obi.Bot.Kenobi $MARK ${THEBOARD[@]}) )
		;;
		
		3)
		THEBOARD=( $(Anakin.Botwalker $MARK ${THEBOARD[@]}) )
		;;
	esac
	
	# Return the board
	echo ${THEBOARD[@]} 
}

##=============================================================
# Master bot logic, given their mark and a 'board' array as input
function Qui.Bot.Jin {
	MARK=$1
	shift
	THEBOARD=( "$@" )
	[[ $MARK == "X" ]] && OPP_MARK="O" || OPP_MARK="X"
	BOARD_STRING=$(flatten.board ${BOARD[@]})
	CPU_DONE=0
	OPEN_TILES=$(echo "$BOARD_STRING" | awk -F "." '{print NF-1}')

	## First round
	# First move: randomly start from a corner or an edge (weigh to favour the corners)
	if [[ $BOARD_STRING == "........."  && "$OPEN_TILES" == "9" ]]
	then
		DIECAST=$(($RANDOM % 10 ))
		if [[ $DIECAST -ge "8" ]]
		then
			DIECAST=$(($RANDOM % 4 ))
			case $DIECAST in
				0)
				MOVE=1
				;;
				1)
				MOVE=3
				;;
				2)
				MOVE=5
				;;
				3)
				MOVE=7
				;;
			esac
			
		else
			DIECAST=$(($RANDOM % 4 ))
			case $DIECAST in
				0)
				MOVE=0
				;;
				1)
				MOVE=2
				;;
				2)
				MOVE=6
				;;
				3)
				MOVE=8
				;;
			esac
		fi
		CPU_DONE=1
		
	# Second move: Middle tile taken: play a random corner
	elif [[ $BOARD_STRING == "....$OPP_MARK...."  && "$OPEN_TILES" == "8" ]]
	then
		DIECAST=$(($RANDOM % 4 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=2
			;;
			2)
			MOVE=6
			;;
			3)
			MOVE=8
			;;
		esac
		CPU_DONE=1
		
	# Second move: Corner tile taken: play the middle
	elif [[ ($BOARD_STRING == "$OPP_MARK........" || $BOARD_STRING == "..$OPP_MARK......" || $BOARD_STRING == "......$OPP_MARK.." || $BOARD_STRING == "........$OPP_MARK") && "$OPEN_TILES" == "8" ]]
	then
		MOVE=4
		CPU_DONE=1
		
	# Second move: Edge tile taken: play the middle
	elif [[ ($BOARD_STRING == ".$OPP_MARK......." || $BOARD_STRING == "...$OPP_MARK....." || $BOARD_STRING == ".....$OPP_MARK..." || $BOARD_STRING == ".......$OPP_MARK.") && "$OPEN_TILES" == "8" ]]
	then
		MOVE=4
		CPU_DONE=1
		
	## Second round	
	# First move: We have a corner, opponent has the middle, play the opposite corner
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "$MARK" && "$OPEN_TILES" == "7" ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "$MARK" && "$OPEN_TILES" == "7" ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$MARK" && "$OPEN_TILES" == "7" ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$MARK" && "$OPEN_TILES" == "7" ]]
	then
		MOVE=0
		CPU_DONE=1
		
	# First move: We have the middle, opponent has a corner, play the opposite corner
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:0:1} == "$MARK" && "$OPEN_TILES" == "7" ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:2:1} == "$MARK" && "$OPEN_TILES" == "7" ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && "$OPEN_TILES" == "7" ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && "$OPEN_TILES" == "7" ]]
	then
		MOVE=0
		CPU_DONE=1
		
	# First move: We have a corner, opponent has the opposite corner, play a random corner
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && "$OPEN_TILES" == "7" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=2
			;;
			1)
			MOVE=6
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && "$OPEN_TILES" == "7" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK" && "$OPEN_TILES" == "7" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:0:1} == "$OPP_MARK" && "$OPEN_TILES" == "7" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=6
			;;	
			1)
			MOVE=2
			;;
		esac
		CPU_DONE=1

	# First move: We have a corner, opponent has an adjacent corner, play the opposite corner
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && (${BOARD_STRING:2:1} == "$OPP_MARK" || ${BOARD_STRING:6:1} == "$OPP_MARK") && "$OPEN_TILES" == "7" ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && (${BOARD_STRING:0:1} == "$OPP_MARK" || ${BOARD_STRING:8:1} == "$OPP_MARK") && "$OPEN_TILES" == "7" ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:6:1} == "$MARK" && (${BOARD_STRING:0:1} == "$OPP_MARK" || ${BOARD_STRING:8:1} == "$OPP_MARK") && "$OPEN_TILES" == "7" ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:8:1} == "$MARK" && (${BOARD_STRING:2:1} == "$OPP_MARK" || ${BOARD_STRING:6:1} == "$OPP_MARK") && "$OPEN_TILES" == "7" ]]
	then
		MOVE=0
		CPU_DONE=1
		
	# First move: We have a corner, opponent has an edge, play the middle
	elif [[ ${BOARD_STRING:4:1} == "." && (${BOARD_STRING:0:1} == "$MARK" || ${BOARD_STRING:2:1} == "$MARK" || ${BOARD_STRING:6:1} == "$MARK" || ${BOARD_STRING:8:1} == "$MARK" ) && (${BOARD_STRING:1:1} == "$OPP_MARK" || ${BOARD_STRING:3:1} == "$OPP_MARK" || ${BOARD_STRING:5:1} == "$OPP_MARK" || ${BOARD_STRING:7:1} == "$OPP_MARK" ) && "$OPEN_TILES" == "7" ]]
	then
		MOVE=4
		CPU_DONE=1
		
	# First move: We have a an edge, opponent has an adjacent edge, play the in between corner
	elif [[ (${BOARD_STRING:1:1} == "$MARK" || ${BOARD_STRING:5:1} == "$MARK") && (${BOARD_STRING:1:1} == "$OPP_MARK" || ${BOARD_STRING:5:1} == "$OPP_MARK") && "$OPEN_TILES" == "7" ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ (${BOARD_STRING:5:1} == "$MARK" || ${BOARD_STRING:7:1} == "$MARK") && (${BOARD_STRING:5:1} == "$OPP_MARK" || ${BOARD_STRING:7:1} == "$OPP_MARK") && "$OPEN_TILES" == "7" ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ (${BOARD_STRING:3:1} == "$MARK" || ${BOARD_STRING:7:1} == "$MARK") && (${BOARD_STRING:3:1} == "$OPP_MARK" || ${BOARD_STRING:7:1} == "$OPP_MARK") && "$OPEN_TILES" == "7" ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ (${BOARD_STRING:1:1} == "$MARK" || ${BOARD_STRING:3:1} == "$MARK") && (${BOARD_STRING:1:1} == "$OPP_MARK" || ${BOARD_STRING:3:1} == "$OPP_MARK") && "$OPEN_TILES" == "7" ]]
	then
		MOVE=0
		CPU_DONE=1
	
	# First move: We have aan edge, opponent does not have the middle, play the middle
	elif [[ (${BOARD_STRING:1:1} == "$MARK" || ${BOARD_STRING:3:1} == "$MARK" || ${BOARD_STRING:5:1} == "$MARK" || ${BOARD_STRING:7:1} == "$MARK" ) && ${BOARD_STRING:4:1} == "." && "$OPEN_TILES" == "7" ]]
	then
		MOVE=4
		CPU_DONE=1
		
	# First move: We have aan edge, opponent has the middle, play an opposite corner
	elif [[ ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:4:1} == "$OPP_MARK" && "$OPEN_TILES" == "7" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=6
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:4:1} == "$OPP_MARK" && "$OPEN_TILES" == "7" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=2
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:4:1} == "$OPP_MARK" && "$OPEN_TILES" == "7" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=6
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:4:1} == "$OPP_MARK" && "$OPEN_TILES" == "7" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=2
			;;
		esac
		CPU_DONE=1
		
	# Second move: We have a corner, opponent has the middle and the opposite corner, play any other corner
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && (${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=2
			;;
			1)
			MOVE=6
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && (${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:6:1} == "$MARK" && (${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:8:1} == "$MARK" && (${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=2
			;;
			1)
			MOVE=6
			;;
		esac
		CPU_DONE=1
		
	# Second move: We have the middle, opponent a corner and its opposite corner, play any edge tile
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ((${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK") || (${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK")) && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 4 ))
		case $DIECAST in
			0)
			MOVE=1
			;;
			1)
			MOVE=3
			;;
			2)
			MOVE=5
			;;
			3)
			MOVE=7
			;;
		esac
		CPU_DONE=1
	
	# Second move: We have the middle, opponent an edge and an opposite corner, play anything in between the short path between the opponent's tile (to block 'L' shape formation)
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && (${BOARD_STRING:6:1} == "$OPP_MARK" || ${BOARD_STRING:8:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			[[ ${BOARD_STRING:6:1} == "$OPP_MARK" ]] && MOVE=0
			[[ ${BOARD_STRING:8:1} == "$OPP_MARK" ]] && MOVE=2
			;;
			1)
			[[ ${BOARD_STRING:6:1} == "$OPP_MARK" ]] && MOVE=3
			[[ ${BOARD_STRING:8:1} == "$OPP_MARK" ]] && MOVE=5
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && (${BOARD_STRING:2:1} == "$OPP_MARK" || ${BOARD_STRING:8:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			[[ ${BOARD_STRING:2:1} == "$OPP_MARK" ]] && MOVE=0
			[[ ${BOARD_STRING:8:1} == "$OPP_MARK" ]] && MOVE=6
			;;
			1)
			[[ ${BOARD_STRING:2:1} == "$OPP_MARK" ]] && MOVE=1
			[[ ${BOARD_STRING:8:1} == "$OPP_MARK" ]] && MOVE=7
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && (${BOARD_STRING:0:1} == "$OPP_MARK" || ${BOARD_STRING:6:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			[[ ${BOARD_STRING:0:1} == "$OPP_MARK" ]] && MOVE=1
			[[ ${BOARD_STRING:6:1} == "$OPP_MARK" ]] && MOVE=7
			;;
			1)
			[[ ${BOARD_STRING:0:1} == "$OPP_MARK" ]] && MOVE=2
			[[ ${BOARD_STRING:6:1} == "$OPP_MARK" ]] && MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && (${BOARD_STRING:0:1} == "$OPP_MARK" || ${BOARD_STRING:2:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			[[ ${BOARD_STRING:0:1} == "$OPP_MARK" ]] && MOVE=3
			[[ ${BOARD_STRING:2:1} == "$OPP_MARK" ]] && MOVE=5
			;;
			1)
			[[ ${BOARD_STRING:0:1} == "$OPP_MARK" ]] && MOVE=6
			[[ ${BOARD_STRING:2:1} == "$OPP_MARK" ]] && MOVE=8
			;;
		esac
		CPU_DONE=1
		
	# Second move: We have the middle, opponent an edge and a second edge next to it, play the enclosed corner tile
	elif [[ (${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		MOVE=0
		CPU_DONE=1
	elif [[ (${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ (${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ (${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		MOVE=8
		CPU_DONE=1
			
	# Second move: We have the middle, opponent an edge and its opposite edge, play any edge tile
	elif [[ (${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=3
			;;
			1)
			MOVE=5
			;;
		esac
		CPU_DONE=1
		
	elif [[ (${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK") && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=1
			;;
			1)
			MOVE=7
			;;
		esac
		CPU_DONE=1
		
	# Second move: We have a corner, opponent an adjacent corner and the opposite edge, play anything but the diagonal
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 4 ))
		case $DIECAST in
			0)
			MOVE=1
			;;
			1)
			MOVE=3
			;;
			2)
			MOVE=5
			;;
			3)
			MOVE=6
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 4 ))
		case $DIECAST in
			0)
			MOVE=1
			;;
			1)
			MOVE=3
			;;
			2)
			MOVE=5
			;;
			3)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 4 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=3
			;;
			2)
			MOVE=5
			;;
			3)
			MOVE=7
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 4 ))
		case $DIECAST in
			0)
			MOVE=2
			;;
			1)
			MOVE=3
			;;
			2)
			MOVE=5
			;;
			3)
			MOVE=7
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 4 ))
		case $DIECAST in
			0)
			MOVE=1
			;;
			1)
			MOVE=2
			;;
			2)
			MOVE=3
			;;
			3)
			MOVE=7
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 4 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=1
			;;
			2)
			MOVE=5
			;;
			3)
			MOVE=7
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 4 ))
		case $DIECAST in
			0)
			MOVE=1
			;;
			1)
			MOVE=3
			;;
			2)
			MOVE=7
			;;
			3)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 4 ))
		case $DIECAST in
			0)
			MOVE=1
			;;
			1)
			MOVE=5
			;;
			2)
			MOVE=6
			;;
			3)
			MOVE=7
			;;
		esac
		CPU_DONE=1
		
	# Second move: We have a corner, opponent the opposite edges, play an adjacent corner
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=2
			;;
			1)
			MOVE=6
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=2
			;;
			1)
			MOVE=6
			;;
		esac
		CPU_DONE=1
		
	# Second move: We have a corner, opponent the opposite and near edge (no line), play the adjacent opposite corner
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		MOVE=0
		CPU_DONE=1
	elif [[ ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		MOVE=0
		CPU_DONE=1
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && "$OPEN_TILES" == "6" ]]
	then
		MOVE=2
		CPU_DONE=1	
		
	## Third round
	# First move: We have a an edge, opponent has an adjacent edge, we have the in between corner, play the middle
	elif [[ ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "." && "$OPEN_TILES" == "5" ]]
	then
		MOVE=4
		CPU_DONE=1
	elif [[ ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "."  && "$OPEN_TILES" == "5" ]]
	then
		MOVE=4
		CPU_DONE=1
	elif [[ ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "."  && "$OPEN_TILES" == "5" ]]
	then
		MOVE=4
		CPU_DONE=1
	elif [[ ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "."  && "$OPEN_TILES" == "5" ]]
	then
		MOVE=4
		CPU_DONE=1
	elif [[ ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "."  && "$OPEN_TILES" == "5" ]]
	then
		MOVE=4
		CPU_DONE=1
	elif [[ ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "."  && "$OPEN_TILES" == "5" ]]
	then
		MOVE=4
		CPU_DONE=1
	elif [[ ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "."  && "$OPEN_TILES" == "5" ]]
	then
		MOVE=4
		CPU_DONE=1
	elif [[ ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "."  && "$OPEN_TILES" == "5" ]]
	then
		MOVE=4
		CPU_DONE=1
		
	# First move: We have an edge and the middle, opponent two other edges, play a corner adjacent to our edge
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && (${BOARD_STRING:3:1} == "$OPP_MARK" || ${BOARD_STRING:5:1} == "$OPP_MARK") && "$OPEN_TILES" == "5" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=2
			;;
		esac
		CPU_DONE=1
		
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && (${BOARD_STRING:1:1} == "$OPP_MARK" || ${BOARD_STRING:7:1} == "$OPP_MARK") && "$OPEN_TILES" == "5" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=6
			;;
		esac
		CPU_DONE=1
		
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && (${BOARD_STRING:1:1} == "$OPP_MARK" || ${BOARD_STRING:7:1} == "$OPP_MARK") && "$OPEN_TILES" == "5" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=2
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
		
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && (${BOARD_STRING:3:1} == "$OPP_MARK" || ${BOARD_STRING:5:1} == "$OPP_MARK") && "$OPEN_TILES" == "5" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=6
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1

	
	# Second move: We have an edge and the middle, opponent the three other edges, play a corner adjacent to our edge
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && "$OPEN_TILES" == "4" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=2
			;;
		esac
		CPU_DONE=1
		
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && "$OPEN_TILES" == "4" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=6
			;;
		esac
		CPU_DONE=1
		
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && "$OPEN_TILES" == "4" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=2
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
		
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && "$OPEN_TILES" == "4" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=6
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
		
	# Second move: We have the middle and some other spot outside the 'L', opponent an edge and an opposite corner, play anything in between the short path between the opponent's tile (to block 'L' shape formation)
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "." && ${BOARD_STRING:3:1} == "." && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=3
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "." && ${BOARD_STRING:5:1} == "." && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=2
			;;
			1)
			MOVE=5
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "." && ${BOARD_STRING:1:1} == "." && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=0
			;;
			1)
			MOVE=1
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "." && ${BOARD_STRING:7:1} == "." && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=6
			;;
			1)
			MOVE=7
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:1:1} == "." && ${BOARD_STRING:2:1} == "." && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=1
			;;
			1)
			MOVE=2
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "." && ${BOARD_STRING:8:1} == "." && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=7
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "." && ${BOARD_STRING:6:1} == "." && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=3
			;;
			1)
			MOVE=6
			;;
		esac
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "." && ${BOARD_STRING:8:1} == "." && "$OPEN_TILES" == "6" ]]
	then
		DIECAST=$(($RANDOM % 2 ))
		case $DIECAST in
			0)
			MOVE=5
			;;
			1)
			MOVE=8
			;;
		esac
		CPU_DONE=1
	
	# Second move: We have an edge and the middle, opponent two edges, and the opposite corner, play the corner between their edges
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && (${BOARD_STRING:1:1} == "$MARK" || ${BOARD_STRING:3:1} == "$MARK") && ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && "$OPEN_TILES" == "4" ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && (${BOARD_STRING:1:1} == "$MARK" || ${BOARD_STRING:5:1} == "$MARK") && ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && "$OPEN_TILES" == "4" ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && (${BOARD_STRING:5:1} == "$MARK" || ${BOARD_STRING:7:1} == "$MARK") && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && "$OPEN_TILES" == "4" ]]
	then
		MOVE=0
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && (${BOARD_STRING:3:1} == "$MARK" || ${BOARD_STRING:7:1} == "$MARK") && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && "$OPEN_TILES" == "4" ]]
	then
		MOVE=2
		CPU_DONE=1
	
	fi
	
	# Update stuff if we made a move
	if [[ $CPU_DONE == 1 ]]
	then
		# Update the board
		THEBOARD[$MOVE]=$MARK
	
		# Broadcast the move
		[[ $VERBOSE == "1" && $BATCH_MODE != "1" ]] && echo "Qui Bot Jin plays: $MOVE" >&2
		[[ $BATCH_MODE != "1" ]] && echo "$MARK plays: $(tile.coord $MOVE)" >&2
		[[ $BATCH_MODE == "1" ]] && echo ${MOVES[$CURRENT_ROUND]} $(tile.coord $MOVE) > moves.tmp
		
		
	## No standard opening detected, let's look for imminent wins or losses
	else
		# Make a call to the padawan bot to determine the move
		[[ $VERBOSE == "1" && $BATCH_MODE != "1" ]] && echo "Qui Bot Jin passes the baton" >&2
		THEBOARD=( $(Obi.Bot.Kenobi $MARK ${THEBOARD[@]}) )
	fi
	
	# Return the board
	echo ${THEBOARD[@]} 
}

##=============================================================
# Padawan bot logic, given their mark and a 'board' array as input
function Obi.Bot.Kenobi {
	MARK=$1
	shift
	THEBOARD=( "$@" )
	[[ $MARK == "X" ]] && OPP_MARK="O" || OPP_MARK="X"
	BOARD_STRING=$(flatten.board ${BOARD[@]})
	CPU_DONE=0

	## See if old Ben can make a winning move
	# Check the top row
	if   [[ ${BOARD_STRING:0:3} == "$MARK$MARK." ]]
	then
		CPU_DONE=1
		MOVE="2"
	elif [[ ${BOARD_STRING:0:3} == ".$MARK$MARK" ]]
	then
		CPU_DONE=1
		MOVE="0"
	elif [[ ${BOARD_STRING:0:3} == "$MARK.$MARK" ]]
	then
		CPU_DONE=1
		MOVE="1"
	
	# Check the middle row
	elif [[ ${BOARD_STRING:3:3} == "$MARK$MARK." ]]
	then
		CPU_DONE=1
		MOVE="5"
	elif [[ ${BOARD_STRING:3:3} == ".$MARK$MARK" ]]
	then
		CPU_DONE=1
		MOVE="3"
	elif [[ ${BOARD_STRING:3:3} == "$MARK.$MARK" ]]
	then
		CPU_DONE=1
		MOVE="4"
	
	# Check the bottom row
	elif [[ ${BOARD_STRING:6:3} == "$MARK$MARK." ]]
	then
		CPU_DONE=1
		MOVE="8"
	elif [[ ${BOARD_STRING:6:3} == ".$MARK$MARK" ]]
	then
		CPU_DONE=1
		MOVE="6"
	elif [[ ${BOARD_STRING:6:3} == "$MARK.$MARK" ]]
	then
		CPU_DONE=1
		MOVE="7"
	
	# Check the left column
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:3:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="3"
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:6:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="6"
	elif [[ ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:0:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="0"
	
	# Check the middle column
	elif [[ ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:4:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="4"
	elif [[ ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:7:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="7"
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:1:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="1"
	
	# Check the right column
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:5:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="5"
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:8:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="8"
	elif [[ ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:2:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="2"
	
	# Check the top left to bottom right diagonal
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:8:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="8"
	elif [[ ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:4:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="4"
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:0:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="0"
	
	# Check the top right to bottom left diagonal
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:4:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="4"
	elif [[ ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:6:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="6"
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:2:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="2"
		
		
	## Cannot win this round. Determine if there is an imminent threat and defend
	# Check the top row
	elif [[ ${BOARD_STRING:0:3} == "$OPP_MARK$OPP_MARK." ]]
	then
		CPU_DONE=1
		MOVE="2"
	elif [[ ${BOARD_STRING:0:3} == ".$OPP_MARK$OPP_MARK" ]]
	then
		CPU_DONE=1
		MOVE="0"
	elif [[ ${BOARD_STRING:0:3} == "$OPP_MARK.$OPP_MARK" ]]
	then
		CPU_DONE=1
		MOVE="1"
	
	# Check the middle row
	elif [[ ${BOARD_STRING:3:3} == "$OPP_MARK$OPP_MARK." ]]
	then
		CPU_DONE=1
		MOVE="5"
	elif [[ ${BOARD_STRING:3:3} == ".$OPP_MARK$OPP_MARK" ]]
	then
		CPU_DONE=1
		MOVE="3"
	elif [[ ${BOARD_STRING:3:3} == "$OPP_MARK.$OPP_MARK" ]]
	then
		CPU_DONE=1
		MOVE="4"
	
	# Check the bottom row
	elif [[ ${BOARD_STRING:6:3} == "$OPP_MARK$OPP_MARK." ]]
	then
		CPU_DONE=1
		MOVE="8"
	elif [[ ${BOARD_STRING:6:3} == ".$OPP_MARK$OPP_MARK" ]]
	then
		CPU_DONE=1
		MOVE="6"
	elif [[ ${BOARD_STRING:6:3} == "$OPP_MARK.$OPP_MARK" ]]
	then
		CPU_DONE=1
		MOVE="7"
	
	# Check the left column
	elif [[ ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="3"
	elif [[ ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="6"
	elif [[ ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="0"
	
	# Check the middle column
	elif [[ ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="4"
	elif [[ ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="7"
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:1:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="1"
	
	# Check the right column
	elif [[ ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="5"
	elif [[ ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="8"
	elif [[ ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="2"
	
	# Check the top left to bottom right diagonal
	elif [[ ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="8"
	elif [[ ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="4"
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="0"
	
	# Check the top right to bottom left diagonal
	elif [[ ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="4"
	elif [[ ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="6"
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "." ]]
	then
		CPU_DONE=1
		MOVE="2"
	
	
	# Check if we can set up a double win scenario. I.e., make a triangle or 'L' shape
	# Triangle setup
	elif [[ ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:0:1} == "." ]]
	then
		MOVE=0
		CPU_DONE=1
	elif [[ ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:2:1} == "." ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:6:1} == "." ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=8
		CPU_DONE=1
		
	elif [[ ((${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:2:1} == "$MARK") || (${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK") || (${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK") || (${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK")) && ${BOARD_STRING:4:1} == "." ]]
	then
		MOVE=4
		CPU_DONE=1
		
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:2:1} == "." ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:0:1} == "." ]]
	then
		MOVE=0
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:2:1} == "." ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:6:1} == "." ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=8
		CPU_DONE=1	
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:6:1} == "." ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:0:1} == "." ]]
	then
		MOVE=0
		CPU_DONE=1
	
	# 'L' shape setup
	elif [[ ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:2:1} == "." && ${BOARD_STRING:5:1} == "." && ${BOARD_STRING:0:1} == "." ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:1:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:2:1} == "." && ${BOARD_STRING:3:1} == "." && ${BOARD_STRING:0:1} == "." ]]
	then
		MOVE=0
		CPU_DONE=1	
	elif [[ ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:0:1} == "." && ${BOARD_STRING:1:1} == "." && ${BOARD_STRING:6:1} == "." ]]
	then
		MOVE=0
		CPU_DONE=1
	elif [[ ${BOARD_STRING:3:1} == "$MARK" && ${BOARD_STRING:8:1} == "$MARK" && ${BOARD_STRING:0:1} == "." && ${BOARD_STRING:6:1} == "." && ${BOARD_STRING:7:1} == "." ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:1:1} == "." && ${BOARD_STRING:2:1} == "." && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:5:1} == "$MARK" && ${BOARD_STRING:6:1} == "$MARK" && ${BOARD_STRING:2:1} == "." && ${BOARD_STRING:7:1} == "." && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=8
		CPU_DONE=1	
	elif [[ ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:2:1} == "$MARK" && ${BOARD_STRING:6:1} == "." && ${BOARD_STRING:5:1} == "." && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ ${BOARD_STRING:7:1} == "$MARK" && ${BOARD_STRING:0:1} == "$MARK" && ${BOARD_STRING:3:1} == "." && ${BOARD_STRING:6:1} == "." && ${BOARD_STRING:7:1} == "." ]]
	then
		MOVE=6
		CPU_DONE=1
	
	# Check if we need to defend against a double win scenario. I.e., check for potential triangles or 'L' shapes
	# Triangle setup
	elif [[ ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "." ]]
	then
		MOVE=0
		CPU_DONE=1
	elif [[ ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "." ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "." ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=8
		CPU_DONE=1
		
	elif [[ ((${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK") || (${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK") || (${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK") || (${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK")) && ${BOARD_STRING:4:1} == "." ]]
	then
		MOVE=4
		CPU_DONE=1
		
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "." ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "." ]]
	then
		MOVE=0
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "." ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "." ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=8
		CPU_DONE=1	
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "." ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:4:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "." ]]
	then
		MOVE=0
		CPU_DONE=1
	
	# 'L' shape setup
	elif [[ ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "." && ${BOARD_STRING:5:1} == "." && ${BOARD_STRING:0:1} == "." ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:1:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "." && ${BOARD_STRING:3:1} == "." && ${BOARD_STRING:0:1} == "." ]]
	then
		MOVE=0
		CPU_DONE=1	
	elif [[ ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "." && ${BOARD_STRING:1:1} == "." && ${BOARD_STRING:6:1} == "." ]]
	then
		MOVE=0
		CPU_DONE=1
	elif [[ ${BOARD_STRING:3:1} == "$OPP_MARK" && ${BOARD_STRING:8:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "." && ${BOARD_STRING:6:1} == "." && ${BOARD_STRING:7:1} == "." ]]
	then
		MOVE=6
		CPU_DONE=1
	elif [[ ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:1:1} == "." && ${BOARD_STRING:2:1} == "." && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=2
		CPU_DONE=1
	elif [[ ${BOARD_STRING:5:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "." && ${BOARD_STRING:7:1} == "." && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=8
		CPU_DONE=1	
	elif [[ ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:2:1} == "$OPP_MARK" && ${BOARD_STRING:6:1} == "." && ${BOARD_STRING:5:1} == "." && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=8
		CPU_DONE=1
	elif [[ ${BOARD_STRING:7:1} == "$OPP_MARK" && ${BOARD_STRING:0:1} == "$OPP_MARK" && ${BOARD_STRING:3:1} == "." && ${BOARD_STRING:6:1} == "." && ${BOARD_STRING:8:1} == "." ]]
	then
		MOVE=6
		CPU_DONE=1
	
	fi
	
	# Update stuff if we made a move
	if [[ $CPU_DONE == 1 ]]
	then
		# Update the board
		THEBOARD[$MOVE]=$MARK
	
		# Broadcast the move
		[[ $VERBOSE == "1" && $BATCH_MODE != "1" ]] && echo "Obi Bot Kenobi plays: $MOVE" >&2
		[[ $BATCH_MODE != "1" ]] && echo "$MARK plays: $(tile.coord $MOVE)" >&2
		[[ $BATCH_MODE == "1" ]] && echo ${MOVES[$CURRENT_ROUND]} $(tile.coord $MOVE) > moves.tmp

		
	## If there is no imminent threat either, let fate decide
	else
		# Make a call to the youngling bot to determine the move
		[[ $VERBOSE == "1" && $BATCH_MODE != "1" ]] && echo "Obi Bot Kenobi passes the baton" >&2
		THEBOARD=( $(Anakin.Botwalker $MARK ${THEBOARD[@]}) )
	fi
	
	# Return the board
	echo ${THEBOARD[@]} 
}

##=============================================================
# Youngling bot logic, given their mark and a 'board' array as input
function Anakin.Botwalker {
	MARK=$1
	shift
	THEBOARD=( "$@" )
	
	# Record a valid move randomly
	VALID_MOVE=0
	while [[ $VALID_MOVE == "0" ]]
	do
		
		# Select a radnom tile to play
		MOVE=$(($RANDOM % 9))
		
		# Check if this tile was still empty	
		if [[ ${THEBOARD[$MOVE]} == "." ]]
		then
			VALID_MOVE=1
		fi
	done

	# Update the board
	THEBOARD[$MOVE]=$MARK
	
	# Broadcast the move
	[[ $VERBOSE == "1" && $BATCH_MODE != "1" ]] && echo "Anakin Botwalker plays: $MOVE" >&2
	[[ $BATCH_MODE != "1" ]] && echo "$MARK plays: $(tile.coord $MOVE)" >&2
	[[ $BATCH_MODE == "1" ]] && echo ${MOVES[$CURRENT_ROUND]} $(tile.coord $MOVE) > moves.tmp

	
	# Return the board
	echo ${THEBOARD[@]} 
}

##=============================================================
# Function to determine if the win condition was reached given a last played mark and a 'board' array as input
function check.win {
	MARK=$1
	shift
	THEBOARD=( "$@" )
	
	# Check the rows
	[[ (${THEBOARD[0]} == "$MARK" && ${THEBOARD[0]} == ${THEBOARD[1]} && ${THEBOARD[0]} == ${THEBOARD[2]}) || 
	   (${THEBOARD[3]} == "$MARK" && ${THEBOARD[3]} == ${THEBOARD[4]} && ${THEBOARD[3]} == ${THEBOARD[5]}) || 
	   (${THEBOARD[6]} == "$MARK" && ${THEBOARD[6]} == ${THEBOARD[7]} && ${THEBOARD[6]} == ${THEBOARD[8]}) ]] && WIN=1
	   
	# Check the columns
	[[ (${THEBOARD[0]} == "$MARK" && ${THEBOARD[0]} == ${THEBOARD[3]} && ${THEBOARD[0]} == ${THEBOARD[6]}) || 
	   (${THEBOARD[1]} == "$MARK" && ${THEBOARD[1]} == ${THEBOARD[4]} && ${THEBOARD[1]} == ${THEBOARD[7]}) || 
	   (${THEBOARD[2]} == "$MARK" && ${THEBOARD[2]} == ${THEBOARD[5]} && ${THEBOARD[2]} == ${THEBOARD[8]}) ]] && WIN=2
	   
	# Check the diagonals
	[[ (${THEBOARD[0]} == "$MARK" && ${THEBOARD[0]} == ${THEBOARD[4]} && ${THEBOARD[0]} == ${THEBOARD[8]}) || 
	   (${THEBOARD[2]} == "$MARK" && ${THEBOARD[2]} == ${THEBOARD[4]} && ${THEBOARD[2]} == ${THEBOARD[6]}) ]] && WIN=3
	   
	# Play the fanfare if there was win
	if [[ $WIN -gt "0" ]]
	then
		echo "~~~~~~~~~~~~~~~~~"
		echo "$MARK's won!"
		echo "Congratulations!"
		echo "~~~~~~~~~~~~~~~~~"
		echo ""
		GAME_OVER=1
	
	# Check if all tiles are taken and call a draw
	elif [[ ! ${THEBOARD[*]} =~ "." ]]
	then
		echo "It's a draw!"
		GAME_OVER=1
	fi
	
	# Ask for another game
	if [[ $GAME_OVER == 1 ]]
	then
		PLAY_AGAIN=0
		while [[ $PLAY_AGAIN != "y" && $PLAY_AGAIN != "n" ]]
		do
			read -n 1 -p "Play again (y|n):" PLAY_AGAIN
			echo ""
		done
		
		# Exit if requested
		[[ $PLAY_AGAIN == "n" ]] && exit
	fi
}

##=============================================================
# Function to determine if the win condition was reached given a last played mark and a 'board' array as input
# Batch test version of this function logs who won and omits asking for another game
function check.win.batch {
	MARK=$1
	shift
	THEBOARD=( "$@" )
	
	# Check the rows
	[[ (${THEBOARD[0]} == "$MARK" && ${THEBOARD[0]} == ${THEBOARD[1]} && ${THEBOARD[0]} == ${THEBOARD[2]}) || 
	   (${THEBOARD[3]} == "$MARK" && ${THEBOARD[3]} == ${THEBOARD[4]} && ${THEBOARD[3]} == ${THEBOARD[5]}) || 
	   (${THEBOARD[6]} == "$MARK" && ${THEBOARD[6]} == ${THEBOARD[7]} && ${THEBOARD[6]} == ${THEBOARD[8]}) ]] && WIN=1
	   
	# Check the columns
	[[ (${THEBOARD[0]} == "$MARK" && ${THEBOARD[0]} == ${THEBOARD[3]} && ${THEBOARD[0]} == ${THEBOARD[6]}) || 
	   (${THEBOARD[1]} == "$MARK" && ${THEBOARD[1]} == ${THEBOARD[4]} && ${THEBOARD[1]} == ${THEBOARD[7]}) || 
	   (${THEBOARD[2]} == "$MARK" && ${THEBOARD[2]} == ${THEBOARD[5]} && ${THEBOARD[2]} == ${THEBOARD[8]}) ]] && WIN=2
	   
	# Check the diagonals
	[[ (${THEBOARD[0]} == "$MARK" && ${THEBOARD[0]} == ${THEBOARD[4]} && ${THEBOARD[0]} == ${THEBOARD[8]}) || 
	   (${THEBOARD[2]} == "$MARK" && ${THEBOARD[2]} == ${THEBOARD[4]} && ${THEBOARD[2]} == ${THEBOARD[6]}) ]] && WIN=3
	   
	# Play the fanfare if there was win
	if [[ $WIN -gt "0" ]]
	then
		[[ "$MARK" == "O" ]] && let O_WINS++
		[[ "$MARK" == "X" ]] && let X_WINS++
		BOARDS[$CURRENT_ROUND]=$(echo "$MARK"$(flatten.board ${THEBOARD[@]}))
		GAME_OVER=1
		[[ $VERBOSE == "1" ]] && echo "$MARK won game $CURRENT_ROUND with: ${THEBOARD[@]}"
	
	# Check if all tiles are taken and call a draw
	elif [[ ! ${THEBOARD[*]} =~ "." ]]
	then
		let DRAWS++
		BOARDS[$CURRENT_ROUND]=$(echo "D"$(flatten.board ${THEBOARD[@]}))
		GAME_OVER=1
		[[ $VERBOSE == "1" ]] && echo "Game $CURRENT_ROUND was a draw: ${THEBOARD[@]}"
	fi
	
}

##=============================================================
# Function to flatten a board array to a string given a 'board' array as input
function flatten.board {
	THEBOARD=( "$@" )
	OLD_IFS=$IFS
	IFS=""
	echo "${THEBOARD[*]}"
	IFS=$OLD_IFS
}

##=============================================================
# Function to convert an array index to a tile coord, given a number as input
function tile.coord {
	BOARD_INDEX=$1
	
	case $BOARD_INDEX in
		0)
		echo "A1"
		;;
		1)
		echo "A2"
		;;
		2)
		echo "A3"
		;;
		3)
		echo "B1"
		;;
		4)
		echo "B2"
		;;
		5)
		echo "B3"
		;;
		6)
		echo "C1"
		;;
		7)
		echo "C2"
		;;
		8)
		echo "C3"
		;;
	esac	
}

##=============================================================
# Function to convert an tile coord to a board array index, given a tile coord as input
function tile.index {
	TILE_COORD=$1
	
	# Make upper case
	TILE_COORD=$(echo "$1" | tr '[:lower:]' '[:upper:]')
	
	# Convert
	case $TILE_COORD in
			"A1")
			echo "0"
			;;
			"A2")
			echo "1"
			;;		
			"A3")
			echo "2"
			;;
			"B1")
			echo "3"
			;;
			"B2")
			echo "4"
			;;
			"B3")
			echo "5"
			;;
			"C1")
			echo "6"
			;;
			"C2")
			echo "7"
			;;
			"C3")
			echo "8"
			;;
		esac
}

##=============================================================
# Function to run tests in batch mode
function batch.mode {
	[[ $VERBOSE == "1" ]] && echo "Verbose mode."
	
	# Initialise some variables
	BOARD=( "." "." "." "." "." "." "." "." "." )
	ROUNDS="not set"
	NUMBER_RE='^[0-9]+$'
	O_WINS=0
	X_WINS=0
	DRAWS=0
	CURRENT_ROUND=0
	BOARDS=()
	MOVES=()

	# Have the player select a number of rounds
	echo "Game mode selected: CPU batch test."
	while ! [[ $ROUNDS =~ $NUMBER_RE && $ROUNDS -gt "0" ]]
	do
		read -n 4 -p "How many games to simulate? (MAX 9999)" ROUNDS
	done
	echo ""
	
	echo "Choose a level for CPU 1:"
	echo "Master (1) Padawan (2) Youngling (3)"
	CPU_1_LEVEL=0
	while [[ $CPU_1_LEVEL != "1" && $CPU_1_LEVEL != "2" && $CPU_1_LEVEL != "3" ]]
	do
		read -n 1 -p "Select CPU (1) Level (1|2|3):" CPU_1_LEVEL
		echo ""
	done
	
	echo ""
	echo "Choose a level for CPU 2:"
	echo "Master (1) Padawan (2) Youngling (3)"
	CPU_2_LEVEL=0
	while [[ $CPU_2_LEVEL != "1" && $CPU_2_LEVEL != "2" && $CPU_2_LEVEL != "3" ]]
	do
		read -n 1 -p "Select CPU (2) Level (1|2|3):" CPU_2_LEVEL
		echo ""
	done
	
	# Draw the empty board
		[[ $VERBOSE == "1" ]] && echo "Gameboard array: ${BOARD[@]}" >&2
	echo ""
	echo "Running simulations..."

	while [[ "$CURRENT_ROUND" -lt "$ROUNDS" ]]
	do
		let "DISPLAY_ROUND = CURRENT_ROUND + 1"
		echo -ne "	Playing game: $DISPLAY_ROUND of $ROUNDS\r"
		GAME_OVER=0
		MOVES[$CURRENT_ROUND]=""

		# Randomly decide who starts (so neither has a consistent advantage)
		[[ $(($RANDOM % 2)) == "0" ]] && TURN="O" || TURN="X"

		# Enter the main game loop
		while [[ $GAME_OVER == "0" ]]
		do
			# Check whose turn it is
			if [[ $TURN == "O" ]]
			then
				CPU_LEVEL=$CPU_1_LEVEL
				BOARD=( $(do.CPU.logic $TURN ${BOARD[@]}) )
			else
				CPU_LEVEL=$CPU_2_LEVEL
				BOARD=( $(do.CPU.logic $TURN ${BOARD[@]}) )
			fi
			
			# Update the MOVES db
			read -r MOVES_ROUND < moves.tmp
			MOVES[$CURRENT_ROUND]=$MOVES_ROUND
			
			# Check if a winning move was made
			check.win.batch $TURN ${BOARD[@]}

			# Relinquish the turn
			[[ $TURN == "O" ]] && TURN="X" || TURN="O"
		done
		
		#Reset the game
		let CURRENT_ROUND++
		BOARD=( "." "." "." "." "." "." "." "." "." )
		WIN=0
	done
	
	echo ""
	echo "Simulation done!"
	case $CPU_1_LEVEL in
		1)
			CPU_1="Qui Bot Jin (Master)"
			;;
		2)
			CPU_1="Obi Bot Kenobi (Padawan)"
			;;
		3)
			CPU_1="Anakin Botwalker (Youngling)"
			;;
	esac
	
	case $CPU_2_LEVEL in
		1)
			CPU_2="Qui Bot Jin (Master)"
			;;
		2)
			CPU_2="Obi Bot Kenobi (Padawan)"
			;;
		3)
			CPU_2="Anakin Botwalker (Youngling)"
			;;
	esac
	
	# Print basic stats	
	echo "	O won $O_WINS times, playing at $CPU_1 level."
	echo "	X won $X_WINS times, playing at $CPU_2 level."
	echo "	There were $DRAWS draws."
	
	## Examine the gameboards in more detail
	printf "%s\n" "${BOARDS[@]}" > boards.tmp
	grep "^O" boards.tmp  | cut -c2- | uniq -c | sort -k1,1nr | uniq > O_wins.tmp
	grep "^X" boards.tmp  | cut -c2- | uniq -c | sort -k1,1nr | uniq > X_wins.tmp
	
	echo ""
	echo "O won in $(wc -l O_wins.tmp | cut -f1 -d " ") unique ways."
	echo "X won in $(wc -l X_wins.tmp | cut -f1 -d " ") unique ways."
	
	let "WINS = X_WINS + O_WINS"
	if [[ $WINS -gt "0" ]]
	then
		# Have the player select a number of gameboards to display
		echo "How many winning boards per CPU to display?"
		PRINT_GAMES="not set"
		while ! [[ $PRINT_GAMES =~ $NUMBER_RE && $PRINT_GAMES -gt "0" ]]
		do
			read -n 2 -p "Games to draw (MAX 99):" PRINT_GAMES
		done
		echo ""
	
		O_REP_WIN_COUNT=( $(head -n $PRINT_GAMES O_wins.tmp | sed 's/\W\+//' | cut -f1 -d " ") )
		O_REP_WIN=( $(head -n $PRINT_GAMES O_wins.tmp | sed 's/\W\+//' | cut -f2 -d " ") )
	
		X_REP_WIN_COUNT=( $(head -n $PRINT_GAMES X_wins.tmp | sed 's/\W\+//' | cut -f1 -d " ") )
		X_REP_WIN=( $(head -n $PRINT_GAMES X_wins.tmp | sed 's/\W\+//' | cut -f2 -d " ") )
	
		echo ""
		[[ $O_WINS -gt "0" ]] && echo "The first $PRINT_GAMES games won by O sorted by play count were played ${O_REP_WIN_COUNT[@]} times."
		[[ $X_WINS -gt "0" ]] && echo "The first $PRINT_GAMES games won by X sorted by play count were played ${X_REP_WIN_COUNT[@]} times."
	
		if [[ $O_WINS -gt "0" ]]
		then
			[[ $PRINT_GAMES -gt $O_WINS ]] && PRINT_GAMES=$O_WINS
			echo ""
			echo "The first $PRINT_GAMES games won by O sorted by play count are:"
			PRINT_LOOP=0
			while [[ $PRINT_LOOP -lt $PRINT_GAMES ]]
			do
				draw.board $(echo ${O_REP_WIN[$PRINT_LOOP]} | sed 's/./& /g')
			
				CUR_PLAY=$(grep -n ${O_REP_WIN[$PRINT_LOOP]} boards.tmp | cut -f1 -d: | head -n1)
				let CUR_PLAY-- #array starts at 0 so deduct one

				echo "Play progression: ${MOVES[$CUR_PLAY]}"
				let PRINT_LOOP++
			done
		fi
	
		if [[ $X_WINS -gt "0" ]]
		then
			[[ $PRINT_GAMES -gt $X_WINS ]] && PRINT_GAMES=$X_WINS
			echo ""
			echo "The first $PRINT_GAMES games won by X sorted by play count are:"
			PRINT_LOOP=0
			while [[ $PRINT_LOOP -lt $PRINT_GAMES ]]
			do
				draw.board $(echo ${X_REP_WIN[$PRINT_LOOP]} | sed 's/./& /g')
			
				CUR_PLAY=$(grep -n ${X_REP_WIN[$PRINT_LOOP]} boards.tmp | cut -f1 -d: | head -n1)
				let CUR_PLAY-- #array starts at 0 so deduct one
				echo "Play progression: ${MOVES[$CUR_PLAY]}"
				let PRINT_LOOP++
			done
		fi
	fi
	
	# Clean up and leave
	rm X_wins.tmp
	rm O_wins.tmp
	rm boards.tmp
	rm moves.tmp
	exit 1	
}


##=============================================================
##=============================================================
## Main section

# Capture the flags
while getopts ":vb" opt; do
  case $opt in
    v)
    	VERBOSE=1
   	   ;;
   	b)
    	BATCH_MODE=1
   	   ;;
   	   
    '?')
      	echo "Invalid option: -$OPTARG" >&2
      	exit 1
    	  ;;
    ':')
      	echo "Option -$OPTARG requires an argument." >&2
      	exit 1
      	;;
    '*')
    	echo "Unimplemented option: $OPTARG" >&2
    	exit 1
    	;;
  esac
done

# Write a welcome message!
echo "Welcome to tic-tac-toe!"

# Check if we are doing batch mode tests
	[[ $BATCH_MODE == "1" ]] && batch.mode
	
# Write instrucitons
echo "When it's your turn, input board coordinates to play. E.g., A3, or B5"

# Enter Menu loop
while true
do
	## Pre-game setup
	# Initialise the game board
	BOARD=( "." "." "." "." "." "." "." "." "." )
	[[ $VERBOSE == "1" ]] && echo "Verbose mode."
	
	# Initialise game status
	GAME_OVER=0
	WIN=0
	
	# Have the player select a mode
	GAMEMODE=0
	while [[ $GAMEMODE != "1" && $GAMEMODE != "2" ]]
	do
		read -n 1 -p "Select CPU (1) or PvP (2) battle:" GAMEMODE
		echo ""
	done

	# Check the mode and start a game
	if [[ $GAMEMODE == "1" ]]
	then
		echo "Game mode selected: CPU battle!"
		echo "Choose a difficulty:"
		echo "Master (1) Padawan (2) Youngling (3)"
		CPU_LEVEL=0
		while [[ $CPU_LEVEL != "1" && $CPU_LEVEL != "2" && $CPU_LEVEL != "3" ]]
		do
			read -n 1 -p "Select CPU Level (1|2|3):" CPU_LEVEL
			echo ""
		done
		echo "Game start!"
		
		# Randomly decide who starts (so neither has a consistent advantage)
		[[ $(($RANDOM % 2)) == "0" ]] && TURN="O" || TURN="X"

		# Draw the empty board
		[[ $VERBOSE == "1" ]] && echo "Gameboard array: ${BOARD[@]}" >&2
		draw.board ${BOARD[@]}
	
		# Enter the main game loop
		while [[ $GAME_OVER == "0" ]]
		do
			# Check whose turn it is
			if [[ $TURN == "O" ]]
			then
				echo "CPU's move!"
				BOARD=( $(do.CPU.logic $TURN ${BOARD[@]}) )
			else
				echo "Your move!"
				BOARD=( $(do.player.logic $TURN ${BOARD[@]}) )
			fi
		
			# Draw the updated board
			[[ $VERBOSE == "1" ]] && echo "Gameboard array: ${BOARD[@]}" >&2
			draw.board ${BOARD[@]}
		
			# Check if a winning move was made
			check.win $TURN ${BOARD[@]}
		
			# Relinquish the turn
			[[ $TURN == "O" ]] && TURN="X" || TURN="O"
		done
	else
		echo "Game mode selected: PvP battle!"
	
		# Set the starting mark
		TURN="O"
	
		# Draw the empty board
		draw.board ${BOARD[@]}
	
		# Enter the main game loop
		while [[ $GAME_OVER == 0 ]]
		do
			echo "Player $TURN's move!"
			BOARD=( $(do.player.logic $TURN ${BOARD[@]}) )
	
			# Draw the updated board
			draw.board ${BOARD[@]}
	
			# Check if a winning move was made
			check.win $TURN ${BOARD[@]}
		
			# Relinquish the turn
			[[ $TURN == "O" ]] && TURN="X" || TURN="O"
		done
	fi
done

