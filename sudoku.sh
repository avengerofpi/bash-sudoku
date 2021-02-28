#!/bin/bash

# Fail on errors (-e). Make accessing undeclared variables an error (-u).
# See `man bash` or `man bash-builtins` for more details (search for 'set')
set -eu;

# Initialize board array
# Testing board borrowed from: https://www.puzzle-sudoku.com/?e=MDozMCw2MTAsOTYx
board=(
  "5s" "  " "  " "  " "  " "  " "  " "7s" "4s"
  "6s" "1s" "  " "  " "  " "7s" "  " "8s" "  "
  "  " "  " "8s" "  " "  " "3s" "9s" "  " "  "
  "  " "5s" "2s" "  " "1s" "  " "  " "  " "  "
  "  " "  " "  " "8s" "6s" "4s" "  " "  " "  "
  "  " "  " "  " "  " "5s" "  " "3s" "1s" "  "
  "  " "  " "1s" "9s" "  " "  " "4s" "  " "  "
  "  " "9s" "  " "2s" "  " "  " "  " "6s" "7s"
  "3s" "8s" "  " "  " "  " "  " "  " "  " "2s"
)
# Types of entry
START_ENTRY_TYPE='s';
GUESS_ENTRY_TYPE='g';
BLANK_ENTRY_TYPE=' ';

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
# 'entry' is the entry at the current coordinate.
function echoStartEntry() { echo -n "${START_COLOR}${entryValue}${TPUT_RESET} "; }
function echoGuessEntry() { echo -n "${GUESS_COLOR}${entryValue}${TPUT_RESET} "; }
function echoBlankEntry() { echo -n "  "; }
function echoEntry() {
  entryValue="${entry:0:1}";
  entryType="${entry:1:1}";
  case ${entryType} in
    ${START_ENTRY_TYPE})
      echoStartEntry ;;
    ${GUESS_ENTRY_TYPE})
      echoGuessEntry ;;
    ${BLANK_ENTRY_TYPE})
      echoBlankEntry ;;
    *)
      echo "ERROR: invalid \${entry}: '${entry}'";
      exit 1;
    ;;
  esac;
}

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
      computeIndex;
      entry=${board[${index}]};
      echoEntry;
    done;
    # Print seperator lines
    j=10;
    echoSeperatorBar;
    echo;
    echoSeperatorLine;
  done;
}

# Compute index from current ${i} and ${j} values
function computeIndex() { index=$(( 9 * (i-1) + (j-1) )); }

# Main program
printBoard
