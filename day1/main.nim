import strutils       # splitLines 
import std/sugar      # for collect
import std/algorithm  # for sort
import std/math       # for sum
import std/sequtils   # for toSeq

proc readLines(): seq[string] =
    return readFile("input").splitLines()

iterator calcCalories(): int =
    let lines = readLines()
    var s = 0
    for line in lines:
        if line != "":
            s += line.parseInt()
        else:
            yield s
            s = 0
    if s != 0:
        yield s

proc part1() =
    let cals = toSeq(calcCalories())
    echo max(cals)

proc part2() =
    var cals = toSeq(calcCalories())
    cals.sort(SortOrder.Descending)
    echo sum(cals[0 ..< 3])

part1()
part2()