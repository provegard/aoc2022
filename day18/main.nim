import sequtils
import strutils
import unittest
import sets
import strformat
import math
import ../utils/move
import hashes

proc parseLine(line: string): Coord3D =
    let parts = line.split(",").map(parseInt)
    return Coord3D(x: parts[0], y: parts[1], z: parts[2])

proc areAdjacent(a, b: Coord3D): bool = manhattan(a, b) == 1

iterator nonDiagonalNeighbors(c: Coord3D): Coord3D =
    yield Coord3D(x: c.x + 1, y: c.y, z: c.z)
    yield Coord3D(x: c.x, y: c.y + 1, z: c.z)
    yield Coord3D(x: c.x, y: c.y, z: c.z + 1)
    yield Coord3D(x: c.x - 1, y: c.y, z: c.z)
    yield Coord3D(x: c.x, y: c.y - 1, z: c.z)
    yield Coord3D(x: c.x, y: c.y, z: c.z - 1)

proc countArea(cubes: seq[Coord3D]): int =
    let cubePositions = cubes.toHashSet

    var area = 0
    for c in cubes:
        let neighborCount = nonDiagonalNeighbors(c).toSeq.filterIt(cubePositions.contains(it)).len()
        area += 6 - neighborCount

    return area

proc part1(file: string): int =
    var cubes = lines(file).toSeq.map(parseLine)
    return countArea(cubes)

suite "day 18":
    test "parseLine":
        check(parseLine("1,2,3") == Coord3D(x: 1, y: 2, z: 3))
        check(parseLine("-1,2,3") == Coord3D(x: -1, y: 2, z: 3))        

    test "countArea":
        check(countArea(@[
           Coord3D(x: 1, y: 1, z: 1),
           Coord3D(x: 2, y: 1, z: 1)
        ]) == 10)

        check(countArea(@[
            Coord3D(x: 1, y: 1, z: 1),
            Coord3D(x: 2, y: 1, z: 1),
            Coord3D(x: 3, y: 1, z: 1)
        ]) == 14)


    test "part 1":
       check(part1("example") == 64)
       check(part1("input") == 3522)