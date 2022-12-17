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

type
    Rock = ref object
        parts: seq[Coord]
        width: int

let knownRocks = @[
    # ####
    Rock(parts: @[
        Coord(x: 0, y: 0),
        Coord(x: 1, y: 0),
        Coord(x: 2, y: 0),
        Coord(x: 3, y: 0)
    ], width: 4),

    #  #
    # ###
    #  #
    Rock(parts: @[
        Coord(x: 1, y: 0),
        Coord(x: 0, y: -1),
        Coord(x: 1, y: -1),
        Coord(x: 2, y: -1),
        Coord(x: 1, y: -2)
    ], width: 3),

    #   #
    #   #
    # ###
    Rock(parts: @[
        Coord(x: 0, y: 0),
        Coord(x: 1, y: 0),
        Coord(x: 2, y: 0),
        Coord(x: 2, y: -1),
        Coord(x: 2, y: -2)
    ], width: 3),

    # #
    # #
    # #
    # #
    Rock(parts: @[
        Coord(x: 0, y: 0),
        Coord(x: 0, y: -1),
        Coord(x: 0, y: -2),
        Coord(x: 0, y: -3)
    ], width: 1),

    # ##
    # ##
    Rock(parts: @[
        Coord(x: 0, y: 0),
        Coord(x: 1, y: 0),
        Coord(x: 0, y: -1),
        Coord(x: 1, y: -1)
    ], width: 2)
]

type
    Cave = ref object
        occupied: HashSet[Coord]
        minX: int
        maxX: int
        highestY: int # 0 or negative, becaue negative is up
    Jets = ref object
        jets: string
        idx: int
    Rocks = ref object
        rocks: seq[Rock]
        idx: int

proc nextJet(jets: var Jets): char =
    let idx = jets.idx
    jets.idx = (jets.idx + 1) mod jets.jets.len()
    return jets.jets[idx]

proc newJets(jets: string): Jets = Jets(jets: jets, idx: 0)

proc newRocks(): Rocks = Rocks(rocks: knownRocks, idx: 0)

proc nextRock(rocks: var Rocks): Rock =
    let idx = rocks.idx
    rocks.idx = (rocks.idx + 1) mod rocks.rocks.len()
    return rocks.rocks[idx]

proc newCave(width: int): Cave = Cave(occupied: initHashSet[Coord](), minX: 0, maxX: width - 1, highestY: 0)

proc getRockCoords(rock: Rock, c: Coord): seq[Coord] = rock.parts.mapIt(addCoords(c, it))

proc isCollision(cave: Cave, rock: Rock, c: Coord): bool =
    let rockCoords = getRockCoords(rock, c)
    return rockCoords.any(proc (pc: Coord): bool = cave.occupied.contains(pc))

proc isValidPos(cave: Cave, rock: Rock, c: Coord): bool =
    if c.y == 0:
        # hits floor
        return false
    return c.x >= cave.minX and (c.x + rock.width - 1) <= cave.maxX and not isCollision(cave, rock, c)

proc jetAffectedCoord(c: Coord, jet: char): Coord =
    return case jet
        of '<': Coord(x: c.x - 1, y: c.y)
        of '>': Coord(x: c.x + 1, y: c.y)
        else: c

let DOWN = Coord(x: 0, y: 1)
proc moveRock(cave: var Cave, rock: Rock, pos: Coord, jets: var Jets) =
    var newPos = pos
    let jet = jets.nextJet()

    # Try sideways
    let sideCoord = jetAffectedCoord(pos, jet)
    if isValidPos(cave, rock, sideCoord):
        newPos = sideCoord

    # Try down
    let downCoord = addCoords(newPos, DOWN)
    if not isValidPos(cave, rock, downCoord):
        # Cannot move down, it's stuck here
        let rockCoords = getRockCoords(rock, newPos)
        for p in rockCoords:
            cave.occupied.incl(p)
        let highY = rockCoords.mapIt(it.y).min() # up is negative
        cave.highestY = min(highY, cave.highestY)
        return

    newPos = downCoord
    moveRock(cave, rock, newPos, jets)

proc printCave(cave: Cave) =
    for y in cave.highestY..0:
        stdout.write(if y == 0: '+' else: '|')
        for x in cave.minX..cave.maxX:
            let coord = Coord(x: x, y: y)
            if y == 0:
                stdout.write('-')
            elif cave.occupied.contains(coord):
                stdout.write('#')
            else:
                stdout.write('.')
        stdout.write(if y == 0: '+' else: '|')
        stdout.write('\n')
    stdout.write('\n')
    flushFile(stdout)


iterator fall(cave: var Cave, jets: var Jets, rocks: var Rocks): int =
    var stopped = 0

    while true:
        let rockY = cave.highestY - 4 # 3 rows distance
        let rockX = cave.minX + 2
        let rock = rocks.nextRock()
        let pos = Coord(x: rockX, y: rockY)
        moveRock(cave, rock, pos, jets)
        stopped += 1
        yield stopped

proc part1(file: string): int =
    let line = lines(file).toSeq()[0]
    var jets = newJets(line)
    var cave = newCave(7)
    var rocks = newRocks()
    for s in fall(cave, jets, rocks):
        if s == 2022:
            return -cave.highestY
    return 0


suite "day 17":
    test "test":
        check(part1("example") == 3068)
        check(part1("input") == 3048)
