import strutils       # splitLines 
import std/sugar      # for collect
import std/algorithm  # for sort
import std/math       # for sum
import std/sequtils   # for toSeq

import tables

# Round points
const
    Win = 6
    Draw = 3
    Lose = 0

# value wins over key
let winner = {
    "Scissors": "Rock",
    "Rock": "Paper",
    "Paper": "Scissors",
}.toTable

# value loses to key
let loser = toSeq(winner.pairs).mapIt((it[1], it[0])).toTable

let scores = {
    "Rock": 1,
    "Paper": 2,
    "Scissors": 3
}.toTable

let handMapping = {
    "A": "Rock",
    "B": "Paper",
    "C": "Scissors",
    "X": "Rock",
    "Y": "Paper",
    "Z": "Scissors",
}.toTable

let strategyMapping = {
    "X": Lose,
    "Y": Draw,
    "Z": Win,
}.toTable

proc calcRoundScore(line: string): int =
    var parts = line.strip().split()
    let theirs = handMapping[parts[0]]
    let mine = handMapping[parts[1]]

    let points =
        if theirs == mine: Draw
        elif winner[theirs] == mine: Win
        else: Lose

    return points + scores[mine]

proc calcRoundScore2(line: string): int =
    var parts = line.strip().split()
    let theirs = handMapping[parts[0]]
    let strategy = strategyMapping[parts[1]]

    let mine =
        if strategy == Win: winner[theirs]
        elif strategy == Draw: theirs
        else: loser[theirs]

    return strategy + scores[mine]

proc readLines(file: string): seq[string] =
    return readFile(file).splitLines()

proc example1(): int = readLines("example").map(calcRoundScore).sum()

proc example2(): int = readLines("example").map(calcRoundScore2).sum()

proc part1(): int = readLines("input").map(calcRoundScore).sum()

proc part2(): int = readLines("input").map(calcRoundScore2).sum()

echo part1()
echo part2()