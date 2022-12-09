import sequtils
import strutils
import unittest
import sets
import options
import sugar
import algorithm
import ../utils/move

iterator coordinates(lines: seq[string]): Coord =
    let columns = lines[0].len()
    var visible = initHashSet[Coord]()
    for r in 0..<lines.len():
        for c in 0..<columns:
            yield (r, c)

proc isValidCoord(c: Coord, lines: seq[string]): bool =
    return c[0] >= 0 and c[0] < lines.len() and c[1] >= 0 and c[1] < lines[0].len()

proc valueAt(c: Coord, lines: seq[string]): int = int(lines[c[0]][c[1]]) - int('0')

proc isVisible(lines: seq[string], coord: Coord, dir: Directions): bool =
    let initVal = valueAt(coord, lines)
    var co = move(coord, dir)
    while isValidCoord(co, lines):
        if valueAt(co, lines) >= initVal:
            return false
        co = move(co, dir)
    return true

proc viewingDistance(lines: seq[string], coord: Coord, dir: Directions): int =
    let initVal = valueAt(coord, lines)
    var co = move(coord, dir)
    var count = 0
    while isValidCoord(co, lines):
        count += 1
        if valueAt(co, lines) >= initVal:
            break
        co = move(co, dir)
    return count

proc scenicScore(lines: seq[string], coord: Coord): int =
    let distances = directions.mapIt(viewingDistance(lines, coord, it))
    return foldl(distances, a * b, 1)

proc getVisible(lines: seq[string]): HashSet[Coord] =
    var visible = initHashSet[Coord]()
    for coord in coordinates(lines):
        for d in directions:
            if isVisible(lines, coord, d):
                visible.incl(coord)
    return visible

proc maxScenicScore(lines: seq[string]): int =
    return coordinates(lines).toSeq().mapIt(scenicScore(lines, it)).max()

proc part1(file: string): int =
    let ll = lines(file).toSeq()
    return getVisible(ll).len()

proc part2(file: string): int =
    let ll = lines(file).toSeq()
    return maxScenicScore(ll)

suite "day 8":
    test "getVisible":
        let ll = lines("example").toSeq()
        let v = getVisible(ll)

        check(v.contains((1, 1)) == true)
        check(v.contains((1, 2)) == true)
        check(v.contains((1, 3)) == false)
        check(v.contains((2, 1)) == true)
        check(v.contains((2, 2)) == false)
        check(v.contains((2, 3)) == true)
        check(v.contains((3, 1)) == false)
        check(v.contains((3, 2)) == true)
        check(v.contains((3, 3)) == false)

    test "part1":
        check(part1("example") == 21)
        check(part1("input") == 1812)

    test "scenicScore":
        let ll = lines("example").toSeq()

        check(scenicScore(ll, (1, 2)) == 4)
        check(scenicScore(ll, (3, 2)) == 8)

    test "part2":
        check(part2("example") == 8)
        check(part2("input") == 315495)