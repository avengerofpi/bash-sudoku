#!/bin/bash

# Generate a random move for a Sudoku board
#  <row><column><value or blank>
function randomSudokuMove() {
    i=$((RANDOM % 9 + 1));
    j=$((RANDOM % 9 + 1));
    m=$((RANDOM % 10));
    [ $m -eq 0 ] && m=" ";
    echo "${i}${j}${m}"
}

# Generate a sequence of random Sudoku moves, possibly with a delay between moves
function playRandomSudokuMoves() {
    # Choose difficulty
    seq 0 5 | shuf | head -1;
    # Start random plays. Continue till success (unlikely) or process is killed
    while true; do
        randomSudokuMove;
        sleep 0.5;
    done
}

# Play a game of Sudoku randomly till success (unlikely) or process is killed
function playSudokuRandomly() {
    playRandomSudokuMoves | ./sudoku.sh
}

# Main function
playSudokuRandomly;
