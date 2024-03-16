#!/bin/bash

# Fail on errors (-e). Make accessing undeclared variables an error (-u).
# See `man bash` or `man bash-builtins` for more details (search for 'set')
set -eu;

# Logging levels
   debug=false;
    info=true;
    warn=true;
   error=true;
critical=true;

# Initialize board array. The board is encoded as an 81-element single-dimensional
# array (Bash does not support multidimensional arrays, I'm pretty sure) read off
# accross the rows. The entries are strings where
#   1st char is the entry value (or blank)
#   2nd char is the entry type
#     's' for a value from starting board
#     'g' for a guessed value
#     ' ' for no current value
# Testing board borrowed from: https://www.puzzle-sudoku.com/?e=MDozMCw2MTAsOTYx
function initTestBoard() {
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
}

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
# Run this function immediately to setup the initial empty array values
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
TPUT_RESET="$(tput sgr0)";

 FAINT="$(tput dim)";
BRIGHT="$(tput bold)";

   RED_FG="$(tput setaf  1)";
 GREEN_FG="$(tput setaf  2)";
YELLOW_FG="$(tput setaf 11)";
  CYAN_FG="$(tput setaf 14)";
PURPLE_FG="$(tput setaf 93)";

BRIGHT_RED_FG="${BRIGHT}${RED_FG}";
FAINT_GREEN_FG="${FAINT}${GREEN_FG}";
BRIGHT_YELLOW_FG="${BRIGHT}${YELLOW_FG}";
BRIGHT_CYAN_FG="${BRIGHT}${CYAN_FG}";
BRIGHT_PURPLE_FG="${BRIGHT}${PURPLE_FG}";

   RED_BG="$(tput setab 9)";
 GREEN_BG="$(tput setab 2)";
YELLOW_BG="$(tput setab 3)";

START_COLOR="${BRIGHT_RED_FG}";
GUESS_COLOR="${BRIGHT_YELLOW_FG}";
BOARD_COLOR="${FAINT_GREEN_FG}";

FLAGGED_START_HIGHLIGHT="${GREEN_BG}";
FLAGGED_GUESS_HIGHLIGHT="${RED_BG}";

   DEBUG_COLOR="${BRIGHT_CYAN_FG}";
    INFO_COLOR="${BRIGHT_PURPLE_FG}";
    WARN_COLOR="${BRIGHT_YELLOW_FG}";
   ERROR_COLOR="${BRIGHT_RED_FG}";
CRITICAL_COLOR="${YELLOW_BG}${BRIGHT_RED_FG}";
  HEADER_COLOR="${YELLOW_BG}${BRIGHT_RED}";

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

# Logging functions
function echoDebug()    { if $debug;     then echo -e "${DEBUG_COLOR}DEBUG:"       "${@}${TPUT_RESET}"; fi; }
function echoInfo()     { if $info;      then echo -e "${INFO_COLOR}INFO:"         "${@}${TPUT_RESET}"; fi; }
function echoWarn()     { if $warn;      then echo -e "${WARN_COLOR}WARN:"         "${@}${TPUT_RESET}"; fi; }
function echoError()    { if $error;     then echo -e "${ERROR_COLOR}ERROR:"       "${@}${TPUT_RESET}"; fi; }
function echoCritical() { if $critical;  then echo -e "${CRITICAL_COLOR}CRITICAL:" "${@}${TPUT_RESET}"; fi; }
function echoHeader()   {                     echo -e "${HEADER_COLOR}"            "${@}${TPUT_RESET}"; }

# Get a random board from https://www.puzzle-sudoku.com
#baseUrl="https://www.puzzle-sudoku.com/?size=";
URL="https://www.puzzle-sudoku.com/";
declare -A difficultyToSizeMap difficultyToLowerBoundMap difficultyToUpperBoundMap;
declare -a difficulties;
# Difficulties
difficulties=( "BASIC" "EASY" "INTERMEDIATE" "ADVANCED" "EXTREME" "EVIL" );
numDifficulties=${#difficulties[@]};
# difficultyToSizeMap
difficultyToSizeMap["BASIC"]="0";
difficultyToSizeMap["EASY"]="1";
difficultyToSizeMap["INTERMEDIATE"]="2";
difficultyToSizeMap["ADVANCED"]="3";
difficultyToSizeMap["EXTREME"]="4";
difficultyToSizeMap["EVIL"]="5";
# difficultyToLowerBoundMap
difficultyToLowerBoundMap["BASIC"]="1";
difficultyToLowerBoundMap["EASY"]="1";
difficultyToLowerBoundMap["INTERMEDIATE"]="1";
difficultyToLowerBoundMap["ADVANCED"]="1";
difficultyToLowerBoundMap["EXTREME"]="1";
difficultyToLowerBoundMap["EVIL"]="1";
# difficultyToUpperBoundMap
difficultyToUpperBoundMap["BASIC"]="88000000";
difficultyToUpperBoundMap["EASY"]="88000000";
difficultyToUpperBoundMap["INTERMEDIATE"]="88000000";
difficultyToUpperBoundMap["ADVANCED"]="63000000";
difficultyToUpperBoundMap["EXTREME"]="16000000";
difficultyToUpperBoundMap["EVIL"]="12000000";
# Default(s)
DEFAULT_DIFFICULTY="${difficulties[0]}";

function printDifficultyPrompt() {
  echo "Choose your difficulty:";
  local difficulty;
  for (( idx=0; numDifficulties - idx; idx++ )); do
    difficulty="${difficulties[${idx}]}";
    echo "  ${idx}: ${difficulty}";
  done;
}
function chooseDifficulty() {
  printDifficultyPrompt;
  promptDifficulty="Choose your difficulty: ";
  read -p "${promptDifficulty}" difficultyNum;

  if [ ${difficultyNum} -ge 0 -a ${difficultyNum} -lt ${numDifficulties} ]; then
    difficulty="${difficulties[${difficultyNum}]}";
  else
    difficulty="${difficulties[${difficultyNum}]}";
  fi;
  echoDebug "difficulty: ${difficulty}";
}

function chooseBoardNumber() {
  # TODO: give user a chance to choose...right now is just random or hardcoded choice

  boardNumLowerBound=${difficultyToLowerBoundMap[${difficulty}]};
  boardNumUpperBound=${difficultyToUpperBoundMap[${difficulty}]};
  modulus=$(( boardNumUpperBound - boardNumLowerBound + 1 ));
  # The range for RANDOM is 0..32767, but we want to use a larger range
  myRandom=$(( (1 + RANDOM) * (1 + RANDOM) * (1 + RANDOM) ))
  boardNumber=$(( (RANDOM % modulus) + boardNumLowerBound ));
  loadBoard;
}

unset board;
declare -a board;
function loadBoard() {
  local boardSize=${difficultyToSizeMap[${difficulty}]};
  local dataRaw="specific=1&size=${boardSize}&specid=${boardNumber}";
  local BOARD_LINE_REGEX="task = ";
  local ENCODED_BOARD_REGEX="s@.*task = '\([_a-z0-9]\+\)'.*@\1@";
  encodedBoard=`curl -sS -X POST "${URL}" --data-raw "${dataRaw}" | grep "${BOARD_LINE_REGEX}" | sed -e "${ENCODED_BOARD_REGEX}"`;
  #encodedBoard="b1c3b9_3j4_6a2_1b2c8e6a7_2e7_1a5b6_5a3d8b9c6f9c3a";
  #encodedBoard="8b4f2a6b5g7d5_1b6d6b1_9b2b4_8c3c5b2i6_7_1c7b3b";

  # Decode an encoded board
  #   Sample: a8c6_4_5a6a4g7_9a4k3_4b3c6_9a1e2b5c6_8_9b4b5_1b6_8c2c7a
  # Boards are encoded as the concatenation of two-char strings, which we will call digrams.
  # The first char of a digram represents the distance from  (number of empty
  # spaces after) the last starting square (or the start of the board, for the
  # first digram), where '_' is 0, 'a' is 1, 'b' is 2, etc. The second char of
  # the digram is the starting board value at the next space.
  #   Note: The one exception is if the first square has a value, in which case the
  #   first 'digram' is just that value char (e.g., '8' instead of '_8').

  local encodedBoardLen=${#encodedBoard};
  echoDebug "encodedBoard: '${encodedBoard}'"
  if [ ${encodedBoardLen} -eq 0 ]; then
    echoError "Could not fetch a board. Exiting.";
    exit 1;
  fi

  # Create an array to map the "distance chars" to their distance values
  declare -A distances;
  local distancesStr="_abcdefghijklmnopqrstuvwxyz";
  local distancesStrLen=${#distancesStr};
  local idx;
  for (( idx=0; distancesStrLen - idx; idx += 1 )); do
    c=${distancesStr:${idx}:1};
    distances[${c}]=${idx};
  done;

  local idxBoard;
  idx=0;
  # Set all entries to blank before loading start board, to ensure every position is defined
  local BLANK_SPACE="  ";
  for (( idxBoard=0; 81 - idxBoard; idxBoard++ )); do
    board[${idxBoard}]="${BLANK_SPACE}";
  done;
  # Load start board
  # Since we always jump one extra space on processing a digram, initialize idxBoard to '-1'
  idxBoard=-1;
  # In case the final "digram" is just the 'dStr' (no starting value in row 9/column 9)
  local encodedBoardLenOffset=$(( encodedBoardLen % 2 ));
  # Check if first entry is a number. If it is, it means the first space is filled
  # and the first 'digram' is just the single char value (e.g., '8' instead of '_8').
  local firstChar="${encodedBoard:0:1}"
  if [[ "${firstChar}" =~ [1-9] ]]; then
    encodedBoard="_${encodedBoard}"
  fi
  echoDebug "encodedBoard: '${encodedBoard}' (after checking first entry)"

  local digram dStr d value;
  for (( idx=0; encodedBoardLen - idx - encodedBoardLenOffset; idx+=2 )); do
    digram=${encodedBoard:${idx}:2};
    dStr=${digram:0:1};
    echoDebug "dStr: '${dStr}'";
    d=${distances[${dStr}]};
    value=${digram:1:1};
    idxBoard=$((idxBoard + d + 1));
    board[${idxBoard}]="${value}${START_ENTRY_TYPE}";
  done;
} # loadBoard

# Print a row/subsquare seperator line if it is time for that.
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
    # Print seperator details
    j=10;
    echoSeperatorBar;
    echo;
    echoSeperatorLine;
  done;
}

# Functions to check whether parts of the board are solved
# Check row i. It is "valid" if and only if all digits 1..9 occur.
function checkRow() {
  validRow=true;
  # Use 'checkerArray' to track values that have been used (explain this more...)
  local checkerArray=( "."  "" "" ""  "" "" ""  "" "" "" );
  for j in {1..9}; do
    computeIndex;
    entry=${board[${index}]};
    entryValue="${entry:0:1}";
    # append ${j}
    checkerArray[${entryValue}]="${checkerArray[${entryValue}]}${j}";
  done;
  # Index v in checkerArray is set if and only if v=0 (ignored) or the
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
}

# Check column j. It is "valid" if and only if all digits 1..9 occur.
function checkColumn() {
  validColumn=true;
  # Use 'checkerArray' to track values that have been used (explain this more...)
  local checkerArray=( "."  "" "" ""  "" "" ""  "" "" "" );
  for i in {1..9}; do
    computeIndex;
    entry=${board[${index}]};
    entryValue="${entry:0:1}";
    # append ${i}
    checkerArray[${entryValue}]="${checkerArray[${entryValue}]}${i}";
  done;
  # Index v in checkerArray is set if and only if v=0 (ignored) or the
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
}

# Check subsquare (ii, jj). It is "valid" if and only if all digits 1..9 occur.
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
      # append ${i} and ${j}
      checkerArrayI[${entryValue}]="${checkerArrayI[${entryValue}]}${i}";
      checkerArrayJ[${entryValue}]="${checkerArrayJ[${entryValue}]}${j}";
    done;
  done;
  # Index v in checkerArrayI (or checkerArrayJ) is set if and only if v=0 (ignored) or the
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
  # If move is 'help' then print the instructions again
  if [ "${move}" == 'help' -o "${move}" == "h" ]; then
    printInstructions;
    return;
  fi

  # If move is 'reset' then reset the board to starting state (remove all guesses)
  if [ "${move}" == 'reset' -o "${move}" == "r" ]; then
    echo "Reseting the board to its starting state.";
    resetBoard;
    return;
  fi

  # If move is 'exit' then end the game
  if [ "${move}" == 'exit' -o "${move}" == "e" ]; then
    echo "Ending the game early.";
    exit 0;
  fi

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
      echo;
      ;;
    ${START_ENTRY_TYPE})
      echo "INVALID MOVE - the selected coordinate was part of the starting board";
      ;;
    *)
      echoCritical "ERROR - somehow the current board has an invalid entry type at the selected coordinate";
      exit 2;
  esac;
}

# Reset board
function resetBoard() {
  loadBoard;
}

# Print instructions / help
function printInstructions() {
  for line in "${instructionsMove[@]}"; do
    echoHeader "${line}";
  done
}

# Main program
instructionsMove=(
  "Choose your next move. You may set a value on any blank space or overwrite",
  "any guess on a non-hint space.  Entries should be input as a 3-digit number, where",
  "  The 1st digit is the row",
  "  The 2nd digit is the column",
  "  The 3rd digit is the value you want to set (or blank or '.' to clear a value)",
  "Or choose",
  "  'help'  or 'h' to re-print this message",
  "  'reset' or 'r' to reset the board",
  "  'exit'  or 'x' to end the current game"
);
promptMove="Enter your next move: ";
chooseDifficulty;
chooseBoardNumber;
solved=false;
printInstructions;
while ! ${solved}; do
  printBoard;
  clearExtraEntryFormatting;
  read -p "${promptMove}" move;
  processMove;
  checkBoardCompletion;
done;

# Game over
printBoard
echo "GAME COMPLETED!";
