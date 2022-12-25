import sequtils
import strutils
import unittest
import sets
import strformat
import math
import ../utils/move
import ../utils/utils
import tables
import hashes
import deques

type
    Blizzard = (Coord, Directions)
    Blizzards2 = seq[Blizzard]
    Valley = ref object
        width: int
        height: int
        startPos: Coord
        goalPos: Coord

proc deltaAtN(dir: Directions, n: int): (int, int) =
    return case dir
        of Directions.dUp: (0, -n)
        of Directions.dRight: (n, 0)
        of Directions.dDown: (0, n)
        of Directions.dLeft: (-n, 0)

proc makeInRange(value: int, rangeLen: int): int =
    if value < 0:
        var v = value
        while v < 0:
            v += rangeLen
        result = v
    elif value >= rangeLen:
        result = value mod rangeLen
    else:
        result = value

proc blizzardsAt(v: Valley, blizzards: Blizzards2, minutes: int): Blizzards2 =
    return blizzards.map(proc (b: Blizzard): Blizzard =
        let (dx, dy) = deltaAtN(b[1], minutes)

        let newX = makeInRange(b[0].x + dx, v.width)
        let newY = makeInRange(b[0].y + dy, v.height)

        let newC = Coord(x: newX, y: newY)
        return (newC, b[1])
    )

let directions = @[Directions.dRight, Directions.dDown, Directions.dLeft, Directions.dUp]
iterator getNeighbors(c: Coord): Coord =
    for dir in directions:
        yield move(c, dir)

proc isValidPos(v: Valley, c: Coord): bool = c == v.startPos or c == v.goalPos or (c.x >= 0 and c.y >= 0 and c.x < v.width and c.y < v.height)

proc hasBlizzardAt(blizzards: Blizzards2, c: Coord): bool = blizzards.any(proc (b: Blizzard): bool = b[0] == c)

proc valleyToString(v: Valley, pos: Coord, blizzards: Blizzards2): string =
    var t = initTable[Coord, seq[Directions]]()
    for (bc, bd) in blizzards:
        if not t.contains(bc):
            t[bc] = newSeq[Directions]()
        t[bc].add(bd)

    var s = ""
    for y in -1..v.height:
        for x in -1..v.width:
            let c = Coord(x: x, y: y)
            if c == pos:
                s &= 'E'
            elif c == v.startPos or c == v.goalPos:
                s &= '.'
            elif not isValidPos(v, c):
                s &= '#'
            elif t.contains(c):
                let dirs = t[c]
                if dirs.len() > 1:
                    let l = dirs.len()
                    s &= ($l)[0]
                else:
                    let ch = case dirs[0]
                        of Directions.dUp: '^'
                        of Directions.dDown: 'v'
                        of Directions.dRight: '>'
                        of Directions.dLeft: '<'
                    s &= ch
            else:
                s &= '.'
        s &= '\n'
    return s.strip()

proc debugPrint(v: Valley, pos: Coord, b2: Blizzards2, minutes: int) =
    if minutes == 0:
        echo "Initial state:"
    else:
        echo &"Minute {minutes}:"
    echo valleyToString(v, pos, b2)
    echo ""

proc isValidPosB(v: Valley, b: Blizzards2, c: Coord): bool = isValidPos(v, c) and not hasBlizzardAt(b, c)

proc parseValley(file: string): (Valley, Blizzards2) =
    var ll = lines(file).toSeq
    let width = ll[0].len() - 2
    let height = ll.len() - 2
    let startPos = Coord(x: 0, y: -1)
    let goalPos = Coord(x: width - 1, y: height)
    var blizzards2 = newSeq[Blizzard]()
    for rowIdx, line in ll:
        for colIdx, ch in line.items.toSeq:
            let c = Coord(x: colIdx - 1, y: rowIdx - 1)
            case ch
                of '>': blizzards2.add((c, Directions.dRight))
                of '<': blizzards2.add((c, Directions.dLeft))
                of '^': blizzards2.add((c, Directions.dUp))
                of 'v': blizzards2.add((c, Directions.dDown))
                else: discard

    let valley = Valley(width: width, height: height, startPos: startPos, goalPos: goalPos)
    return (valley, blizzards2)

iterator allBlizzards(v: Valley, b: Blizzards2): Blizzards2 =
    let count = lcm(v.width, v.height)
    yield b
    for i in 1..<count:
        yield blizzardsAt(v, b, i)

iterator findPath(v: Valley, b: Blizzards2): int =
    let bb = allBlizzards(v, b).toSeq
    let bbLen = bb.len()

    var queue = @[(v.startPos, 0)].toDeque
    var visited = initHashSet[(Coord, int)]()
    while queue.len() > 0:
        let (c, mn) = queue.popFirst
        if c == v.goalPos:
            yield mn

        let actualMin = mn mod bbLen
        let visitedKey = (c, actualMin)

        if visited.contains(visitedKey):
            continue
        visited.incl(visitedKey)

        let nextMinute = mn + 1
        let blizzardsNextMinute = bb[nextMinute mod bbLen]

        # figure out where we can move next minute
        var nn = getNeighbors(c).toSeq.filterIt(isValidPosB(v, blizzardsNextMinute, it))

        # If we can stay, that is always an option
        let canStay = isValidPosB(v, blizzardsNextMinute, c)
        if canStay:
            queue.addLast((c, nextMinute))

        if nn.len() > 0:
            let gidx = nn.findIndex(proc (n: Coord): bool = n == v.goalPos)
            if gIdx >= 0:
                # found goal, don't bother checking other neighbors
                yield nextMinute
            else:
                for n in nn:
                    queue.addLast((n, nextMinute))
     
proc part1(file: string): int =
    let (valley, blizzards) = parseValley(file)
    for mn in findPath(valley, blizzards):
        # assume the first one is the best...
        return mn
    return -1

suite "day 24":
    test "makeInRange":
        check(makeInRange(0, 6) == 0)
        check(makeInRange(5, 6) == 5)
        check(makeInRange(6, 6) == 0)
        check(makeInRange(12, 6) == 0)
        check(makeInRange(-1, 6) == 5)
        check(makeInRange(-6, 6) == 0)

    test "blizzards, 3":
        let (valley, blizzards) = parseValley("example")
        let s = valleyToString(valley, valley.startPos, blizzardsAt(valley, blizzards, 3))
        let expected = @[
            "#E######",
            "#<^<22.#",
            "#.2<.2.#",
            "#><2>..#",
            "#..><..#",
            "######.#"
        ].join("\n")
        check(s == expected)

    test "blizzards, 4":
        let (valley, blizzards) = parseValley("example")
        let s = valleyToString(valley, valley.startPos, blizzardsAt(valley, blizzards, 4))
        let expected = @[
            "#E######",
            "#.<..22#",
            "#<<.<..#",
            "#<2.>>.#",
            "#.^22^.#",
            "######.#"
        ].join("\n")
        check(s == expected)

    test "part 1":
       check(part1("example") == 18)
       check(part1("input") == 247)
