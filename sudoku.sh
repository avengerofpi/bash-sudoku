#!/bin/bash

# Fail on errors (-e). Make accessing undeclared variables an error (-u).
# See `man bash` or `man bash-builtins` for more details (search for 'set')
set -eu;

# Initialize board array. The board is encoded as an 81-element single-dimensional
# array (Bash does not support multidimensional arrays, I'm pretty sure) read off
# accross the rows. The entries are strings where
#   1st char is the entry value (or blank)
#   2nd char is the entry type
#     's' for a value from starting board
#     'g' for a guessed value
#     ' ' for no current value
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
);

# Initialize an array that will be used to flag bad entries,
#   e.g., duplicate value in the entry's row, column, or subsquare
# for modified print formatting.
declare -a extraEntryFormatting;

# Clear the extraEntryFormatting array
function clearExtraEntryFormatting() {
  for index in {0..80}; do
    extraEntryFormatting[${index}]="";
  done;
}
clearExtraEntryFormatting;

# Set entryFlag for the current index. Any non-empty string will do.
function setBadEntryFormatting() {
  entry="${board[${index}]}";
  entryType="${entry:1:1}";
  case ${entryType} in
    ${START_ENTRY_TYPE})
      extraEntryFormatting[${index}]="${FLAGGED_START_HIGHLIGHT}";
      ;;
    ${GUESS_ENTRY_TYPE})
      extraEntryFormatting[${index}]="${FLAGGED_GUESS_HIGHLIGHT}";
      ;;
  esac;
}

# Types of entry
START_ENTRY_TYPE='s';
GUESS_ENTRY_TYPE='g';
BLANK_ENTRY_TYPE=' ';

# Coloration
export FAINT="$(tput dim)";
export FAINT_GREEN="${FAINT}$(tput setaf 2)";
export BRIGHT="$(tput dim)";
export BRIGHT_YELLOW="${BRIGHT}$(tput setaf 11)";
export BRIGHT_RED="${BRIGHT}$(tput setaf 1)";
export BRIGHT_CYAN="${BRIGHT}$(tput setaf 14)";
export BRIGHT_PURPLE="${BRIGHT}$(tput setaf 93)";
export TPUT_RESET="$(tput sgr0)";

export RED_BG="$(tput setab 9)";
export GREEN_BG="$(tput setab 2)";
export YELLOW_BG="$(tput setab 3)";

export START_COLOR="${BRIGHT_RED}";
export GUESS_COLOR="${BRIGHT_YELLOW}";
export FLAGGED_START_HIGHLIGHT="${GREEN_BG}";
export FLAGGED_GUESS_HIGHLIGHT="${RED_BG}";
export BOARD_COLOR="${FAINT_GREEN}";

export    DEBUG_COLOR="${BRIGHT_CYAN}";
export     INFO_COLOR="${BRIGHT_PURPLE}";
export     WARN_COLOR="${BRIGHT_YELLOW}";
export    ERROR_COLOR="${BRIGHT_RED}";
export CRITICAL_COLOR="${YELLOW_BG}${BRIGHT_RED}";

# Helper functions to print parts of the board.
# 'entry' is the entry at the current coordinate.
function echoStartEntry() { echo -n "${extraEntryFormatting[${index}]}${START_COLOR}${entryValue}${TPUT_RESET} "; }
function echoGuessEntry() { echo -n "${extraEntryFormatting[${index}]}${GUESS_COLOR}${entryValue}${TPUT_RESET} "; }
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
      echoCritical "ERROR: invalid \${entry}: '${entry}'";
      exit 1;
    ;;
  esac;
}

# Debug printing
function echoDebug()    { echo "${DEBUG_COLOR}DEBUG:"       "${@}${TPUT_RESET}"; }
function echoInfo()     { echo "${INFO_COLOR}INFO:"         "${@}${TPUT_RESET}"; }
function echoWarn()     { echo "${WARN_COLOR}WARN:"         "${@}${TPUT_RESET}"; }
function echoError()    { echo "${ERROR_COLOR}ERROR:"       "${@}${TPUT_RESET}"; }
function echoCritical() { echo "${CRITICAL_COLOR}CRITICAL:" "${@}${TPUT_RESET}"; }

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

# Functions to check whether parts of the board are solved
# Check row i
function checkRow() {
  validRow=true;
  # Use 'checkerStr' to track values that have been used (explain this more...)
  local checkerArray=( "."  "" "" ""  "" "" ""  "" "" "" );
  for j in {1..9}; do
    computeIndex;
    entry=${board[${index}]};
    entryValue="${entry:0:1}";
    checkerArray[${entryValue}]="${checkerArray[${entryValue}]}${j}"; # append ${j}
  done;
  # Index v in checkerArray is set iff v=0 (ignored) or the
  # value 'v' occurs in row i at least once.
  for v in {1..9}; do
    local checkerStr="${checkerArray[${v}]}";
    if [[ "${checkerStr}" == "" ]]; then
      # The value 'v' does not currently exist in this row
      validRow=false;
    else
      # The value 'v' has occurred at least once in this row
      local n=${#checkerStr};
      if [ ${n} -gt 1 ]; then
        # The value 'v' occurred more than once; flag the offending entries
        for (( hitNumber=0 ; n - hitNumber ; hitNumber += 1 )); do
          j=${checkerStr:${hitNumber}:1};
          computeIndex;
          setBadEntryFormatting;
        done;
      fi;
    fi;
  done;
}

# Check rows
function checkRows() {
  validRows=true;
  for i in {1..9}; do
    checkRow;
    ${validRow} || validRows=false;
  done;
  echo;
}

# Check column j
function checkColumn() {
  validColumn=true;
  # Use 'checkerStr' to track values that have been used (explain this more...)
  local checkerArray=( "."  "" "" ""  "" "" ""  "" "" "" );
  for i in {1..9}; do
    computeIndex;
    entry=${board[${index}]};
    entryValue="${entry:0:1}";
    checkerArray[${entryValue}]="${checkerArray[${entryValue}]}${i}"; # append ${i}
  done;
  # Index v in checkerArray is set iff v=0 (ignored) or the
  # value 'v' occurs in column j at least once.
  for v in {1..9}; do
    local checkerStr="${checkerArray[${v}]}";
    if [[ "${checkerStr}" == "" ]]; then
      # The value 'v' does not currently exist in this row
      validColumn=false;
    else
      # The value 'v' has occurred at least once in this column
      local n=${#checkerStr};
      if [ ${n} -gt 1 ]; then
        # The value 'v' occurred more than once; flag the offending entries
        for (( hitNumber=0 ; n - hitNumber ; hitNumber += 1 )); do
          i=${checkerStr:${hitNumber}:1};
          computeIndex;
          setBadEntryFormatting;
        done;
      fi;
    fi;
  done;
}

# Check columns
function checkColumns() {
  validColumns=true;
  for j in {1..9}; do
    checkColumn;
    ${validColumn} || validColumns=false;
  done;
  echo;
}

# Check subsquare (ii, jj)
function checkSubSquare() {
  validSubSquare=true;
  # Use 'checkerArrayI' and 'checkerArrayJ' to track values that have been used (explain this more...)
  local checkerArrayI=( "."  "" "" ""  "" "" ""  "" "" "" );
  local checkerArrayJ=( "."  "" "" ""  "" "" ""  "" "" "" );
  imin=$(( (ii - 1) * 3 + 1 ));
  jmin=$(( (jj - 1) * 3 + 1 ));
  imax=$(( imin + 3 ));
  jmax=$(( jmin + 3 ));
  for (( i=imin ; i - imax ; i += 1 )); do
    for (( j=jmin ; j - jmax ; j += 1 )); do
      computeIndex;
      entry=${board[${index}]};
      entryValue="${entry:0:1}";
      checkerArrayI[${entryValue}]="${checkerArrayI[${entryValue}]}${i}"; # append ${i}
      checkerArrayJ[${entryValue}]="${checkerArrayJ[${entryValue}]}${j}"; # append ${j}
    done;
  done;
  # Index v in checkerArrayI (or checkerArrayJ) is set iff v=0 (ignored) or the
  # value 'v' occurs in subsquare (ii, jj) at least once.
  for v in {1..9}; do
    local checkerStrI="${checkerArrayI[${v}]}";
    local checkerStrJ="${checkerArrayJ[${v}]}";
    # Just check one of checkerStrI or checkerStrJ (they should correspond)
    if [[ "${checkerStrI}" == "" ]]; then
      # The value 'v' does not currently exist in this subSquare
      validSubSquare=false;
    else
      # The value 'v' has occurred at least once in this subSquare
      # Just check one of checkerStrI or checkerStrJ (they should correspond)
      local n=${#checkerStrI};
      if [ ${n} -gt 1 ]; then
        # The value 'v' occurred more than once; flag the offending entries
        for (( hitNumber=0 ; n - hitNumber ; hitNumber += 1 )); do
          i=${checkerStrI:${hitNumber}:1};
          j=${checkerStrJ:${hitNumber}:1};
          computeIndex;
          setBadEntryFormatting;
        done;
      fi;
    fi;
  done;
}

# Check subsquares
function checkSubSquares() {
  validSubSquares=true;
  for ii in {1..3}; do
    for jj in {1..3}; do
      checkSubSquare;
      ${validSubSquare} || validSubSquares=false;
    done;
  done;
  echo;
}

# Check whether the board is solved
function checkBoardCompletion() {
  solved=true;

  checkRows;
  ${validRows}       || solved=false;

  checkColumns;
  ${validColumns}    || solved=false;

  checkSubSquares;
  ${validSubSquares} || solved=false;
}

# Compute index from current ${i} and ${j} values
function computeIndex() { index=$(( 9 * (i-1) + (j-1) )); }

# Preprocess and validate the structure of the current `move`
DIGIT_PATTERN="^[1-9]$";
VALUE_PATTERN="^[\.1-9]?$";
function preprocessAndValidateMove() {
  validMove=true;
  i=${move:0:1};
  j=${move:1:1};
  value=${move:2:1};
  len=${#move};
  # Check each element. For each, if invalid then log the issue and set 'validMove' to false
  [ ${len} -gt 3 ] && { echoError "Invalid entry length (too long), try again"  && validMove=false && return 0; };
  [ ${len} -lt 2 ] && { echoError "Invalid entry length (too short), try again" && validMove=false && return 0; };
  [[ ${i}     =~ ${DIGIT_PATTERN} ]] || { echoError "Invalid row index ${i}"    && validMove=false; };
  [[ ${j}     =~ ${DIGIT_PATTERN} ]] || { echoError "Invalid column index ${j}" && validMove=false; };
  [[ ${value} =~ ${VALUE_PATTERN} ]] || { echoError "Invalid value ${value}"    && validMove=false; };
}

# Process the latest move
function processMove() {
  # TODO: maybe: use three inputs (i, j, value) on `read` rather than one input with post-processing

  # Exit function if the move was invalid
  preprocessAndValidateMove;
  ${validMove} || return 0;

  # Move was valid. Update the Sudoku board.
  computeIndex;
  case "${value}" in
    "" | ".")
      newEntryType="${BLANK_ENTRY_TYPE}";
      value=" ";
      ;;
    [1-9])
      newEntryType="${GUESS_ENTRY_TYPE}";
      ;;
    *)
      # This should have been defeated, so error if it happens.
      echoCritical "ERROR - the current move has an invalid value '${value}' that somehow passed earlier/initial validation";
      exit 3;
  esac;
  newEntry="${value}${newEntryType}";
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
      echoCritical "ERROR - somehow the current board has an invalid entry type at the selected coordinate";
      exit 2;
  esac;
}

# Main program
instructions="Choose your next move. You may set a value on any blank space or overwrite
any guess on a non-hint space.  Entries should be input as a 3-digit number, where
  The 1st digit is the row
  The 2nd digit is the column
  The 3rd digit is the value you want to set (or blank or '.' to clear a value)";
prompt="Enter your next move: ";
solved=false;
echo "${instructions}";
while ! ${solved}; do
  printBoard;
  clearExtraEntryFormatting;
  read -p "${prompt}" move;
  processMove;
  checkBoardCompletion;
  echo;
done;

printBoard
echo "GAME COMPLETED!";
