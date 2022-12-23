import sequtils
import unittest
import sets
import strformat
import ../utils/move
import tables

type
    CompassDirection = enum cdNorth, cdNorthEast, cdEast, cdSouthEast, cdSouth, cdSouthWest, cdWest, cdNorthWest
    World = HashSet[Coord]

let consideredDirections = [cdNorth, cdSouth, cdWest, cdEast]

proc nextCoord(c: Coord, cd: CompassDirection): Coord =
    return case cd
        of cdNorth:     Coord(x: c.x, y: c.y - 1)
        of cdNorthEast: Coord(x: c.x + 1, y: c.y - 1)
        of cdEast:      Coord(x: c.x + 1, y: c.y)
        of cdSouthEast: Coord(x: c.x + 1, y: c.y + 1)
        of cdSouth:     Coord(x: c.x, y: c.y + 1)
        of cdSouthWest: Coord(x: c.x - 1, y: c.y + 1)
        of cdWest:      Coord(x: c.x - 1, y: c.y)
        of cdNorthWest: Coord(x: c.x - 1, y: c.y - 1)

proc shouldConsiderDirection(world: World, c: Coord, cd: CompassDirection): bool =
    proc isFree(ccd: CompassDirection): bool = not world.contains(nextCoord(c, ccd))
    return case cd
        of cdNorth: isFree(cdNorth) and isFree(cdNorthWest) and isFree(cdNorthEast)
        of cdEast:  isFree(cdEast)  and isFree(cdNorthEast) and isFree(cdSouthEast)
        of cdSouth: isFree(cdSouth) and isFree(cdSouthEast) and isFree(cdSouthWest)
        of cdWest:  isFree(cdWest)  and isFree(cdSouthWest) and isFree(cdNorthWest)
        else: false

proc shouldMoveAtAll(world: World, c: Coord): bool =
    # If no other Elves are in one of those eight positions, the Elf does not do anything during this round.
    return (cdNorth..cdNorthWest).toSeq.any(proc (cd: CompassDirection): bool = world.contains(nextCoord(c, cd)))

proc oneRound(world: var World, considerationStartIndex: int): bool =
    # first half
    var proposedMoves = initTable[Coord, seq[Coord]]() # key = proposed move, value = elves proposing it
    # figure out where elves propose to move to
    for elf in world.items:
        if not shouldMoveAtAll(world, elf):
            continue
        for idx in 0..3:
            let consideredDirection = consideredDirections[(considerationStartIndex + idx) mod 4]
            if shouldConsiderDirection(world, elf, consideredDirection):
                let proposed = nextCoord(elf, consideredDirection)
                if not proposedMoves.contains(proposed):
                    proposedMoves[proposed] = newSeq[Coord]()
                proposedMoves[proposed].add(elf)
                break

    # move if only one elf proposed it
    var didMove = false
    for (proposition, elves) in proposedMoves.pairs:
        if elves.len() > 1:
            continue
        world.excl(elves[0])
        world.incl(proposition)
        didMove = true

    return didMove

proc printWorld(world: World) =
    let minX = world.items.toSeq.mapIt(it.x).min() - 2
    let maxX = world.items.toSeq.mapIt(it.x).max() + 2
    let minY = world.items.toSeq.mapIt(it.y).min() - 2
    let maxY = world.items.toSeq.mapIt(it.y).max() + 2
    for y in minY..maxY:
        for x in minX..maxX:
            let c = Coord(x: x, y: y)
            if world.contains(c):
                stdout.write('#')
            else:
                stdout.write('.')
        stdout.write('\n')
    flushFile(stdout)


proc moveAround(world: var World, maxRounds: int, debug: bool = false): int =
    if debug:
        echo ""
        echo "Initial state"
        printWorld(world)

    var considerationStartIndex = 0
    var rounds = 0
    while true:
        let didMove = oneRound(world, considerationStartIndex)
        considerationStartIndex += 1
        rounds += 1

        if not didMove:
            if debug:
                echo "did not move"
            break

        if debug:
            echo ""
            echo &"After round {rounds}"
            printWorld(world)

        if rounds == maxRounds:
            if debug:
                echo "reached max rounds"
            break
    return rounds

proc parseFile(file: string): World =
    var world = initHashSet[Coord]()
    for rowIdx, line in lines(file).toSeq:
        for colIdx, ch in line.items.toSeq:
            if ch == '#':
                world.incl(Coord(x: colIdx, y: rowIdx))
    return world

proc part1(file: string): int =
    var world = parseFile(file)
    discard moveAround(world, 10)
    let minX = world.items.toSeq.mapIt(it.x).min()
    let maxX = world.items.toSeq.mapIt(it.x).max()
    let minY = world.items.toSeq.mapIt(it.y).min()
    let maxY = world.items.toSeq.mapIt(it.y).max()
    let tiles = (maxX - minX + 1) * (maxY - minY + 1)
    return tiles - world.len()

proc part2(file: string): int =
    var world = parseFile(file)
    return moveAround(world, high(int))

suite "day 23":
    test "part 1":
        check(part1("example") == 110)
        check(part1("input") == 4045)

    test "part 2":
        check(part2("example") == 20)
        check(part2("input") == 963)