import strutils       # splitLines 
import std/sequtils   # for map
import std/math       # for sum
import src/score

proc readLines(file: string): seq[string] =
    return readFile(file).splitLines()

proc example1(): int = readLines("example").map(calcRoundScore).sum()

proc example2(): int = readLines("example").map(calcRoundScore2).sum()

proc part1(): int = readLines("input").map(calcRoundScore).sum()

proc part2(): int = readLines("input").map(calcRoundScore2).sum()

echo part1()
echo part2()