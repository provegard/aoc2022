import sequtils
import unittest
import ../utils/move
import ../utils/utils
import tables
import sets
import math
import strformat

type
    TileType = enum ttOpen, ttWall
    Board = Table[Coord, TileType]
    FaceMap = Table[Coord, int]
    Path = seq[int]
    WrapFn = proc (b: Board, current: Coord, next: Coord, dir: Directions): (Coord, Directions)

let Left = -1
let Right = -2

iterator parsePath(path: string): int =
    var currentNumber = -1
    for ch in path.items:
        if ch == 'L' or ch == 'R':
            if currentNumber >= 0:
                yield currentNumber
                currentNumber = -1
            yield (if ch == 'L': Left else: Right)
        else:
            if currentNumber < 0:
                currentNumber = 0
            currentNumber = 10 * currentNumber + int(ch) - 48
    if currentNumber >= 0:
        yield currentNumber

proc findStart(b: Board): Coord =
    let minX = b.keys.toSeq.filterIt(it.y == 0).mapIt(it.x).min()
    return Coord(x: minX, y: 0)

proc parseFile(file: string): (Board, Path, FaceMap, int) =
    var board = initTable[Coord, TileType]()
    var parts = lines(file).toSeq.splitByDelimiter(proc (l: string): bool = l == "").toSeq
    for rowIndex, line in parts[0]:
        for colIndex, ch in line.items.toSeq:
            let coord = Coord(x: colIndex, y: rowIndex)
            if ch == '.':
                board[coord] = ttOpen
            elif ch == '#':
                board[coord] = ttWall
    
    let path = parsePath(parts[1][0]).toSeq

    var faceMap = initTable[Coord, int]()
    let tileCount = board.len()
    let side = int(sqrt(tileCount / 6))

    var counts = initCountTable[int]()
    let minY = board.keys.toSeq.mapIt(it.y).min()
    let maxY = board.keys.toSeq.mapIt(it.y).max()
    let minX = board.keys.toSeq.mapIt(it.x).min()
    let maxX = board.keys.toSeq.mapIt(it.x).max()
    for y in minY..maxY:
        for x in minX..maxX:
            let c = Coord(x: x, y: y)
            if board.contains(c) and not faceMap.contains(c):
                let nextFace = (1..6).toSeq.findIndex(proc (i: int): bool = counts[i] == 0) + 1
                assert nextFace > 0
                # this is the upper-left tile
                for yy in y..<(y+side):
                    for xx in x..<(x+side):
                        let cc = Coord(x: xx, y: yy)
                        faceMap[cc] = nextFace
                counts.inc(nextFace)

    return (board, path, faceMap, side)

proc changeDirection(d: Directions, how: int): Directions =
    if d == Directions.dUp:
        return if how == Right: Directions.dRight else: Directions.dLeft
    elif d == Directions.dDown:
        return if how == Right: Directions.dLeft else: Directions.dRight
    elif d == Directions.dRight:
        return if how == Right: Directions.dDown else: Directions.dUp
    # dLeft
    return if how == Right: Directions.dUp else: Directions.dDown

proc isWall(b: Board, c: Coord): bool = b.contains(c) and b[c] == ttWall
proc isOutside(b: Board, c: Coord): bool = not b.contains(c)

proc wrap(b: Board, current: Coord, c: Coord, dir: Directions): (Coord, Directions) =
    assert isOutside(b, c)
    var newCoord: Coord
    if dir == dRight:
        let minX = b.keys.toSeq.filterIt(it.y == c.y).mapIt(it.x).min()
        newCoord = Coord(x: minX, y: c.y)
    elif dir == dLeft:
        let maxX = b.keys.toSeq.filterIt(it.y == c.y).mapIt(it.x).max()
        newCoord = Coord(x: maxX, y: c.y)
    elif dir == dDown:
        let minY = b.keys.toSeq.filterIt(it.x == c.x).mapIt(it.y).min()
        newCoord = Coord(x: c.x, y: minY)
    else:
        # dUp
        let maxY = b.keys.toSeq.filterIt(it.x == c.x).mapIt(it.y).max()
        newCoord = Coord(x: c.x, y: maxY)
    return (newCoord, dir)

proc rotate90CW(origin: Coord, c: Coord): Coord =
    let delta = origin - c
    let rot = Coord(x: delta.y, y: -delta.x)
    return origin + rot

proc createWrap2(faceMap: FaceMap, side: int): WrapFn =

    proc findOrigin(c: Coord): Coord =
        let face = faceMap[c]
        let faceCoords = faceMap.pairs.toSeq.filterIt(it[1] == face).mapIt(it[0])
        let ox = faceCoords.mapIt(it.x).min()
        let oy = faceCoords.mapIt(it.y).min()
        return Coord(x: ox, y: oy)

    return proc (b: Board, current: Coord, next: Coord, dir: Directions): (Coord, Directions) =
        assert isOutside(b, next)

        proc findNextFace(findDir: Directions): (bool, Coord, int) =
            # add 'side' to 'current' and 'next'. If both exist, we have found the next face.
            var steps = 0
            while true:
                steps += 1
                let c2 = current.move(findDir, side)
                let n2 = next.move(findDir, side)
                if isOutside(b, c2):
                    return (false, n2, steps)
                if b.contains(n2):
                    return (true, n2, steps)
        proc rotateDir(steps: int, how: int): Directions =
            var d = dir
            for i in 1..steps:
                d = changeDirection(d, how)
            return d
        proc rotateCoordCW(n: Coord, steps: int): Coord =
            # origin is upper-left, 
            let origin = findOrigin(n)
            var c = n
            for i in 1..steps:
                # 90 degrees CW in relation to upper left means we're in the lower-right quadrant,
                # and end up in the lower-left quadrant, so we must move to the right.
                c = rotate90CW(origin, c) + Coord(x: side - 1, y: 0)
            return c

        if dir == Directions.dRight:
            # TODO: Try both up and down
            let (success, newCoord, steps) = findNextFace(Directions.dDown)
            let newDirection = rotateDir(steps, Right)
            let newCoordRot = rotateCoordCW(newCoord, steps)
            return (newCoordRot, newDirection)


        assert false, "TODO"
        return (next, dir)

proc facingValue(dir: Directions): int =
    return case dir
        of Directions.dRight: 0
        of Directions.dDown: 1
        of Directions.dLeft: 2
        of Directions.dUp: 3

proc move(b: Board, path: Path, wrapFn: WrapFn): (Coord, Directions) =
    var current = findStart(b)
    var dir = Directions.dRight
    for instr in path:
        if instr == Left or instr == Right:
            dir = changeDirection(dir, instr)
        elif instr > 0:
            for i in 1..instr:
                var next = move(current, dir)
                if isOutside(b, next):
                    # wrap
                    (next, dir) = wrapFn(b, current, next, dir)
                if isWall(b, next):
                    # stay
                    break
                current = next

    return (current, dir)

proc part1(file: string): int =
    let (board, path, _, _) = parseFile(file)
    let (pos, dir) = move(board, path, wrap)

    let row = 1 + pos.y
    let col = 1 + pos.x

    return 1000 * row + 4 * col + facingValue(dir)


suite "day 22":
    test "parsePath":
        check(parsePath("R").toSeq == @[Right])
        check(parsePath("10").toSeq == @[10])
        check(parsePath("12L").toSeq == @[12, Left])
        check(parsePath("L5").toSeq == @[Left, 5])
        check(parsePath("0R").toSeq == @[0, Right])
        check(parsePath("R0").toSeq == @[Right, 0])

    test "part 1":
        check(part1("example") == 6032)
        check(part1("input") == 64256)

    test "face map":
        let (_, _, faceMap, side) = parseFile("example")

        check(side == 4)

        let uniqueValues = faceMap.values.toSeq.toHashSet()
        check(uniqueValues.len() == 6)

        check(faceMap[Coord(x: 8, y: 0)] == 1)
        check(faceMap[Coord(x: 0, y: 4)] == 2)
        check(faceMap[Coord(x: 4, y: 4)] == 3)
        check(faceMap[Coord(x: 8, y: 4)] == 4)
        check(faceMap[Coord(x: 8, y: 8)] == 5)
        check(faceMap[Coord(x: 12, y: 8)] == 6)

    test "wrap2":
        let (board, _, faceMap, side) = parseFile("example")
        let wrap2 = createWrap2(faceMap, side)

        check(wrap2(board, Coord(x: 11, y: 5), Coord(x: 12, y: 5), Directions.dRight) == (Coord(x: 14, y: 8), Directions.dDown))