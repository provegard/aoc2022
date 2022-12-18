import sequtils
import strutils
import unittest
import sets
import strformat
import ../utils/move

proc parseLine(line: string): Coord3D =
    let parts = line.split(",").map(parseInt)
    return Coord3D(x: parts[0], y: parts[1], z: parts[2])

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

iterator airPockets(airCandidates: HashSet[Coord3D], cubes: HashSet[Coord3D], isOutside: proc (c: Coord3D): bool): seq[Coord3D] =
    var candidates = airCandidates # make a copy

    while candidates.len() > 0:
        let x = candidates.pop()

        if isOutside(x):
            continue

        var group = newSeq[Coord3D]()

        var check = @[x]
        var skipGroup = false
        while check.len() > 0 and not skipGroup:
            let next = check.pop()
            candidates.excl(next)
            group.add(next)
            for n in nonDiagonalNeighbors(next):
                if cubes.contains(n):
                    # not an air neighbor
                    continue
                if isOutside(n):
                    # reached outside of the "big cube", so it cannot be a pocket inside
                    skipGroup = true
                    break
                if check.contains(n) or group.contains(n):
                    continue
                check.add(n)

        if not skipGroup:
            yield group

proc countExternalArea(cubes: seq[Coord3D]): int =
    let cubePositions = cubes.toHashSet

    let xs = cubePositions.items.toSeq.mapIt(it.x)
    let ys = cubePositions.items.toSeq.mapIt(it.y)
    let zs = cubePositions.items.toSeq.mapIt(it.z)
    let minX = xs.min()
    let maxX = xs.max()
    let minY = ys.min()
    let maxY = ys.max()
    let minZ = zs.min()
    let maxZ = zs.max()

    proc isOutsideBigCube(c: Coord3D): bool =
        return c.x < minX or c.y < minY or c.z < minZ or c.x > maxX or c.y > maxY or c.z > maxZ

    var air = initHashSet[Coord3D]()

    var area = 0
    for c in cubes:
        let neighbors = nonDiagonalNeighbors(c).toSeq
        let cubeNeighborCount = neighbors.filterIt(cubePositions.contains(it)).len()
        area += 6 - cubeNeighborCount

        let airNeighbors = neighbors.filterIt(not cubePositions.contains(it))
        for n in airNeighbors:
            air.incl(n)

    for pocket in airPockets(air, cubePositions, isOutsideBigCube):
        let pocketPositions = pocket.toHashSet
        for c in pocket:
            for n in nonDiagonalNeighbors(c):
                assert pocketPositions.contains(n) or cubePositions.contains(n)

        area -= countArea(pocket)

    return area

proc part1(file: string): int =
    var cubes = lines(file).toSeq.map(parseLine)
    return countArea(cubes)

proc part2(file: string): int =
    var cubes = lines(file).toSeq.map(parseLine)
    return countExternalArea(cubes)

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

    test "part 2":
        check(part2("example") == 58)
        check(part2("input") == 2074)