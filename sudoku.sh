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
export BRIGHT_CYAN="${BRIGHT}$(tput setaf 14)"
export TPUT_RESET="$(tput sgr0)"

export START_COLOR="${BRIGHT_RED}"
export GUESS_COLOR="${BRIGHT_YELLOW}"
export BOARD_COLOR="${FAINT_GREEN}"
export DEBUG_COLOR="${BRIGHT_CYAN}"

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

# Debug printing
echoDebug() { echo "${DEBUG_COLOR}DEBUG: ${@}${TPUT_RESET}"; }

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

# Check whether the board is solved
# INCOMPLETE: right now I'm just checking if there are any blank entries
function checkBoardCompletion() {
  solved=true;
  for i in {1..9}; do
    for j in {1..9}; do
      computeIndex;
      entry=${board[${index}]};
      entryType="${entry:1:1}";
      if [[ ${entryType} == ${BLANK_ENTRY_TYPE} ]]; then
        solved=false;
        return;
      fi;
    done;
  done;
}

# Compute index from current ${i} and ${j} values
function computeIndex() { index=$(( 9 * (i-1) + (j-1) )); }

# Preprocess and validate the current `move`
DIGIT_PATTERN="^[0-9]$";
function preprocessAndValidateMove() {
  validMove=true;
  i=${move:0:1};
  j=${move:1:1};
  value=${move:2:1};
  [[ ${i}     =~ ${DIGIT_PATTERN} ]] || { echo "invalid row"    && validMove=false; };
  [[ ${j}     =~ ${DIGIT_PATTERN} ]] || { echo "invalid column" && validMove=false; };
  [[ ${value} =~ ${DIGIT_PATTERN} ]] || { echo "invalid value"  && validMove=false; };
}

# Process the latest move
function processMove() {
  # TODO: maybe: use three inputs (i, j, value) on `read` rather than one input with post-processing

  # Exit function if the move was invalid
  preprocessAndValidateMove;
  ${validMove} || return 0;

  # Move was valid. Update the Sudoku board.
  computeIndex;
  newEntry="${value}${GUESS_ENTRY_TYPE}";
  existingEntry=${board[${index}]};
  existingEntryType=${existingEntry:1:1};
  case ${existingEntryType} in
    ${GUESS_ENTRY_TYPE} | ${BLANK_ENTRY_TYPE})
      board[index]=${newEntry};
      ;;
    ${START_ENTRY_TYPE})
      echo "INVALID MOVE - the selected coordinate was part of the starting board";
      ;;
    *)
      echo "ERROR - somehow the current board has an invalid entry type at the selected coordinate";
      exit 2;
  esac;
}

# Main program
prompt="Choose your next move. You may set a value on any blank space or overwrite any guess on a non-hint space.\
Entries should be input as a 3-digit number.
  The 1st digit is the row
  The 2nd digit is the column
  The 3rd digit is the value you want to set
> "
solved=false;
while ! ${solved}; do
  printBoard
  read -p "${prompt}" move;
  processMove;
  checkBoardCompletion;
  echo;
done;

printBoard
echo "GAME COMPLETED!";
