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
    while true; do
        randomSudokuMove;
        sleep 2;
    done
}

# Play a game of Sudoku randomly till success (unlikely) or process is killed
function playSudokuRandomly() {
    playRandomSudokuMoves | ./sudoku.sh
}

# Main function
playSudokuRandomly;
