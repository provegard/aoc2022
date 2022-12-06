import std/sequtils
import std/strutils
import std/unittest
import std/sets
import std/options
import sugar
import algorithm

proc findMarkerPos(line: string, markerLen: int = 4): int =
    for i in markerLen..line.len():
        let lastOnes = line[(i-markerLen)..(i-1)]
        if lastOnes.toHashSet().len() == markerLen:
            return i
    return -1

proc part(file: string, markerLen: int): int =
    let firstLine = lines(file).toSeq()[0]
    return findMarkerPos(firstLine, markerLen)

proc part1(file: string): int = part(file, 4)
proc part2(file: string): int = part(file, 14)

suite "day 6":
    test "findMarkerPos":
        check(findMarkerPos("mjqjpqmgbljsphdztnvjfqwrcgsmlb") == 7)
        check(findMarkerPos("bvwbjplbgvbhsrlpgdmjqwftvncz") == 5)
        check(findMarkerPos("nppdvjthqldpwncqszvftbrmjlhg") == 6)

        check(findMarkerPos("mjqjpqmgbljsphdztnvjfqwrcgsmlb", 14) == 19)

    test "part1":
        check(part1("input") == 1929)

    test "part2":
        check(part2("input") == 3298)