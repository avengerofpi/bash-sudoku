#!/bin/bash

# Fail on errors (-e). Make accessing undeclared variables an error (-u).
# See `man bash` or `man bash-builtins` for more details (search for 'set')
set -eu;

# Initialize startingBoard array
# Testing board borrowed from: https://www.puzzle-sudoku.com/?e=MDozMCw2MTAsOTYx
startingBoard=(
  "115"                                     "187" "194"
  "216" "221"                   "267"       "288"      
              "338"             "363" "379"            
        "425" "432"       "451"                        
                    "548" "556" "564"                  
                          "655"       "673" "681"      
              "731" "749"             "774"            
        "829"       "842"                   "886" "897"
  "913" "928"                                     "992"
)

# Initialized guesses array
guesses=( );

# Coloration
export FAINT="$(tput dim)"
export FAINT_GREEN="${FAINT}$(tput setaf 2)"
export BRIGHT="$(tput dim)"
export BRIGHT_YELLOW="${BRIGHT}$(tput setaf 11)"
export BRIGHT_RED="${BRIGHT}$(tput setaf 1)"
export TPUT_RESET="$(tput sgr0)"

export START_COLOR="${BRIGHT_RED}"
export GUESS_COLOR="${BRIGHT_YELLOW}"
export BOARD_COLOR="${FAINT_GREEN}"

# Helper functions to print parts of the board.
# 'value' is the entry at the current coordinate.
function echoStart() { echo -n "${START_COLOR}${value}${TPUT_RESET} "; }
function echoGuess() { echo -n "${GUESS_COLOR}${value}${TPUT_RESET} "; }
function echoBlank() { echo -n "  "; }

# Print a row seperator line if it is time for that.
function echoSeperatorLine() {
  [ $((i % 3)) -ne 0 ] || echo "-------------------------" ;
}

# Print a column seperator char if it is time for that.
function echoSeperatorBar() {
  [ $((j % 3)) -ne 1 ] || echo -n "| ";
}

# Print the current state of the Sudoku board
function printBoard() {
  i=0;
  echoSeperatorLine;
  for i in {1..9}; do
    j=0;
    for j in {1..9}; do
      echoSeperatorBar;
      coor="${i}${j}";
      echoFunction="";
      value="";
      # If this coor is in the startingBoard, print it as such.
      for entry in ${startingBoard[@]}; do
        if [ ${entry:0:2} -eq ${coor} ]; then
          value=${entry:2:1};
          echoStart;
          break;
        fi;
      done;
      [ -n "${value}" ] && continue;

      # If this coor has been guessed, print it as such.
      # Ensure this doesn't happen if the entry is in the startingBoard (don't print twice!)
      for entry in ${guesses[@]}; do
        if [ ${entry:0:2} -eq ${coor} ]; then
          value=${entry:2:1};
          echoGuess;
          break;
        fi;
      done;
      [ -n "${value}" ] && continue;

      # Print blank entry
      echoBlank;
    done;
    # Print seperator lines
    j=10;
    echoSeperatorBar;
    echo;
    echoSeperatorLine;
  done;
}

# Main program
printBoard
