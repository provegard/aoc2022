import sequtils
import strutils
import unittest
import sets
import options
import ../utils/move
import math

type
    Path = seq[Coord]
    Cave = HashSet[Coord]
    OccupiedFn = proc (cave: Cave, c: Coord): bool

proc parseLine(line: string): Path =
    let points = line.split(" -> ")
    return points.map(proc (p: string): Coord =
        let xy = p.split(',')
        return Coord(x: xy[0].parseInt, y: xy[1].parseInt)
    )

proc newCave(): Cave = initHashSet[Coord]()

proc populateWithRock(cave: var Cave, paths: seq[Path]) =
    for path in paths:
        let pairs = zip(path, path[1..^1])
        for pair in pairs:
            let xd = sgn(pair[1].x - pair[0].x)
            let yd = sgn(pair[1].y - pair[0].y)
            var c = pair[0]
            while true:
                cave.incl(c)
                if c == pair[1]:
                    break
                c = Coord(x: c.x + xd, y: c.y + yd)

proc printCave(cave: Cave) =
    var xs = cave.items.toSeq.mapIt(it.x)
    var ys = cave.items.toSeq.mapIt(it.y)
    xs.add(500)
    ys.add(0)

    for y in ys.min()..ys.max()+1:
        for x in xs.min()-1..xs.max()+1:
            let c = Coord(x: x, y: y)
            if cave.contains(c):
                stdout.write('#')
            else:
                stdout.write('.')
        stdout.write('\n')
    flushFile(stdout)

proc nextPos(cave: Cave, c: Coord, isOccupied: OccupiedFn): Option[Coord] =
    let deltas = [(0, 1), (-1, 1), (1, 1)]
    for d in deltas:
        let nxt = Coord(x: c.x + d[0], y: c.y + d[1])
        if not isOccupied(cave, nxt):
            return some(nxt)
    return none[Coord]()

proc dropOneSand(cave: var Cave, maxY: int, isOccupied: OccupiedFn): bool =
    var c = Coord(x: 500, y: 0)
    if isOccupied(cave, c):
        return false
    while c.y < maxY:
        let nextOpt = nextPos(cave, c, isOccupied)
        if nextOpt.isNone:
            # rest
            cave.incl(c)
            return true
        else:
            c = nextOpt.get
    return false

proc findMaxY(cave: Cave): int = cave.items.toSeq.mapIt(it.y).max()

proc occupiedP1(cave: Cave, c: Coord): bool = cave.contains(c)

proc createOccupiedP2(maxY: int): OccupiedFn =
    return proc (cave: Cave, c: Coord): bool =
        if cave.contains(c):
            return true
        return c.y == 2 + maxY

proc setup(file: string): (Cave, int) =
    let paths = lines(file).toSeq.map(parseLine)
    var cave = newCave()

    populateWithRock(cave, paths)
    let maxY = findMaxY(cave)

    return (cave, maxY)


proc part1(file: string): int =
    var (cave, maxY) = setup(file)

    var dropped = 0
    while dropOneSand(cave, maxY, occupiedP1):
        dropped += 1

    return dropped

proc part2(file: string): int =
    var (cave, maxY) = setup(file)

    let occupiedP2 = createOccupiedP2(maxY)
    var dropped = 0
    # Add 3 since we stop at y < max
    while dropOneSand(cave, maxY + 3, occupiedP2):
        dropped += 1

    return dropped

suite "day 14":
    test "parseLine":
        check(parseLine("498,4 -> 498,6 -> 496,6") == @[
            Coord(x: 498, y: 4),
            Coord(x: 498, y: 6),
            Coord(x: 496, y: 6)
        ])

    test "part1":
        check(part1("example") == 24)
        check(part1("input") == 614)

    test "part2":
        check(part2("example") == 93)
        check(part2("input") == 26170)