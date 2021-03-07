#!/bin/bash

# Find the max board number for a given board size
#   a: board number that exists
#      lower bound to bump up iteratively
#   b: board number that doesn't exist
#      upper bound to bump down iteratively
function computeNewMiddle() { c=$(( (a + b) / 2 )); }
function resetBounds() {
  aDefault=1;
  bDefault=100000000;
  a=${1-${aDefault}};
  b=${2-${bDefault}};
  computeNewMiddle;
};
# Text that is expected and can be grep'd for if the Puzzle Number is invalid
failText="Unable to load puzzle. No puzzle with such ID.";

# Main program. Compute the largest Puzzle / Board Number for the current Size
# ${s} should already be set
function computeLargeBoardNumber() {
  #[ $# -ne 1 ] && echo "Required input (size) missing. Failing" && return 1;

  resetBounds;
  echo "Size = ${s}";
  echo "  Starting a = ${a}";
  echo "  Starting b = ${b}";
  while [ ${a} -ne ${c} -a ${b} -ne ${c} ]; do
    #echo "c = ${c}";
    #dataRaw="specific=1&size=0&specid=${c}";
    dataRaw="specific=1&size=${s}&specid=${c}";
    res=`curl -sS -X POST 'https://www.puzzle-sudoku.com/' --data-raw "${dataRaw}" | grep "${failText}"`;
    #echo "res=${res:0:5}...";
    if [ -z "${res}" ]; then
      # Board exists; update lower bound
      a=${c};
      #echo "${a}";
    else
      # Board does not exist; update upper bound
      b=${c};
    fi;
    computeNewMiddle;
  done;
  echo "  Largest valid board number: ${a}";
}

# Board sizes over 8 are daily/monthly specials, and only one exists at a time
for s in {0..7}; do
  computeLargeBoardNumber ${s};
done;

