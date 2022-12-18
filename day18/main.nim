import sequtils
import strutils
import unittest
import sets
import options
import sugar
import algorithm
import strformat
import math
import ../utils/move

proc parseLine(line: string): Coord3D =
    let parts = line.split(",").map(parseInt)
    return Coord3D(x: parts[0], y: parts[1], z: parts[2])

proc areAdjacent(a, b: Coord3D): bool = manhattan(a, b) == 1

type
    Cube = ref object
        pos: Coord3D
        adjacent: seq[Cube]

proc `$`(c: Cube): string =
    return &"[(x: {c.pos.x}, y: {c.pos.y}, z: {c.pos.z}), adjacent = {c.adjacent.len()}]"

proc newCube(pos: Coord3D): Cube = Cube(pos: pos, adjacent: newSeq[Cube]())

proc cubeGroup(c: Cube): seq[Cube] =
    var all = newSeq[Cube]()
    var list = @[c]
    while list.len() > 0:
        let next = list.pop()
        all.add(next)
        for a in next.adjacent:
            if all.contains(a) or list.contains(a):
                continue
            list.add(a)
    return all

proc connectCubes(cubes: var seq[Cube]) =
    for i in 0..<cubes.len():
        for j in (i+1)..<cubes.len():
            var c1 = cubes[i]
            var c2 = cubes[j]
            if areAdjacent(c1.pos, c2.pos):
                c1.adjacent.add(c2)
                c2.adjacent.add(c1)

proc countArea(cubes: seq[Cube]): int =
    var allCubes = cubes
    connectCubes(allCubes)

    var area = 0
    while allCubes.len() > 0:
        let c = allCubes.pop()
        let group = cubeGroup(c)

        for c2 in group:
            let idx = allCubes.find(c2)
            if idx >= 0:
                allCubes.delete(idx)
            area += 6 - c2.adjacent.len()

    return area

proc part1(file: string): int =
    var cubes = lines(file).toSeq.map(parseLine).map(newCube)
    return countArea(cubes)

suite "day 18":
    test "parseLine":
        check(parseLine("1,2,3") == Coord3D(x: 1, y: 2, z: 3))
        check(parseLine("-1,2,3") == Coord3D(x: -1, y: 2, z: 3))        

    test "countArea":
        check(countArea(@[
           newCube(Coord3D(x: 1, y: 1, z: 1)),
           newCube(Coord3D(x: 2, y: 1, z: 1))
        ]) == 10)

        check(countArea(@[
            newCube(Coord3D(x: 1, y: 1, z: 1)),
            newCube(Coord3D(x: 2, y: 1, z: 1)),
            newCube(Coord3D(x: 3, y: 1, z: 1))
        ]) == 14)


    test "part 1":
       check(part1("example") == 64)
       check(part1("input") == 3522)