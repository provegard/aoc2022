import sequtils
import unittest
import ../utils/move
import ../utils/utils
import tables
import sets
import math
import strformat
import strutils

type
    TileType = enum ttOpen, ttWall
    Board = Table[Coord, TileType]
    Board3D = Table[Coord3D, TileType]
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

proc rotate3D(refPoint: Coord3D, points: seq[Coord3D], pitchDeg, rollDeg, yawDeg: int): seq[Coord3D] =
    proc toRad(n: int): float = float(n) * PI / 180.0
    let yaw = toRad(yawDeg)
    let pitch = toRad(pitchDeg)
    let roll = toRad(rollDeg)

    let cosa = cos(yaw)
    let sina = sin(yaw)

    let cosb = cos(pitch)
    let sinb = sin(pitch)

    let cosc = cos(roll)
    let sinc = sin(roll)

    let Axx = cosa * cosb
    let Axy = cosa * sinb * sinc - sina * cosc
    let Axz = cosa * sinb * cosc + sina * sinc

    let Ayx = sina * cosb
    let Ayy = sina * sinb * sinc + cosa * cosc
    let Ayz = sina * sinb * cosc - cosa * sinc

    let Azx = -sinb
    let Azy = cosb * sinc
    let Azz = cosb * cosc

    return points.map(proc (p: Coord3D): Coord3D =
        let px = float(p.x - refPoint.x)
        let py = float(p.y - refPoint.y)
        let pz = float(p.z - refPoint.z)

        let px2 = Axx * px + Axy * py + Axz * pz
        let py2 = Ayx * px + Ayy * py + Ayz * pz
        let pz2 = Azx * px + Azy * py + Azz * pz

        return Coord3D(
            x: int(round(px2 + float(refPoint.x))),
            y: int(round(py2 + float(refPoint.y))),
            z: int(round(pz2 + float(refPoint.z)))
        )
    )

let ndir = @[Directions.dUp, Directions.dRight, Directions.dDown, Directions.dLeft]
iterator neighbors(c: Coord, predicate: proc (n: Coord): bool): Coord =
    for dir in ndir:
        let n = move(c, dir)
        if predicate(n):
            yield n

proc connected(b: Board, c: Coord, predicate: proc (n: Coord): bool): HashSet[Coord] =
    var s = initHashSet[Coord]()
    if b.contains(c):
        var q = newSeq[Coord]()
        q.add(c)
        while q.len() > 0:
            let c2 = q.pop()
            s.incl(c2)
            let nn = neighbors(c2, proc (n: Coord): bool = predicate(n) and b.contains(n) and not s.contains(n)).toSeq
            for n in nn:
                q.add(n)
    result = s


proc fold(b: Board, faceMap: FaceMap): Board3D =
    var foldedInRelationTo = initTable[int, int]()

    proc to3D(c: Coord): Coord3D = Coord3D(x: c.x, y: c.y, z: 0)

    var m2To3 = initTable[Coord, Coord3D]()
    for c in b.keys.toSeq:
        m2To3[c] = to3D(c)

    #var all = newSeq[(Coord3D, int)]()        
    for i in 1..6:
        let coordsForI = faceMap.pairs.toSeq.filterIt(it[1] == i).mapIt(it[0])
        let minX = coordsForI.mapIt(it.x).min()
        let minY = coordsForI.mapIt(it.y).min()
        let maxX = coordsForI.mapIt(it.x).max()
        let maxY = coordsForI.mapIt(it.y).max()
        
        let allLeft = connected(b, Coord(x: minX - 1, y: minY), proc (n: Coord): bool = n.x < minX).toSeq
        let allDown = connected(b, Coord(x: minX, y: maxY + 1), proc (n: Coord): bool = n.y > maxY).toSeq

        echo &"face {i}, down = {allDown.len()}, left = {allLeft.len()}"

        if allDown.len() > 0:
            # find the 3D coordinate for each 2D coordinate
            let beforeRotate3D = allDown.mapIt(m2To3[it])

            # determine reference points for rotation and movement in 2D
            let ref0 = Coord(x: minX, y: maxY)
            let ref0b = Coord(x: maxX, y: maxY)
            let lineDiff = m2To3[ref0b] - m2To3[ref0]

            let ref1 = Coord(x: minX, y: maxY + 1)
            let ref2 = Coord(x: minX, y: maxY + 2)
            let ref1Idx = findIndex(allDown, proc (c: Coord): bool = c == ref1)
            let ref2Idx = findIndex(allDown, proc (c: Coord): bool = c == ref2)

            var rotated3D: seq[Coord3D]
            if lineDiff.x == 0:
                rotated3D = rotate3D(m2To3[ref1], beforeRotate3D, 0, 0, 90)
            elif lineDiff.y == 0:
                rotated3D = rotate3D(m2To3[ref1], beforeRotate3D, 0, -90, 0)
            elif lineDiff.z == 0:
                assert false, "TODO 2"
                #let rotated3D = rotate3D(m2To3[ref1], beforeRotate3D, 0, -90, 0)

            let diff = rotated3D[ref2Idx] - rotated3D[ref1Idx] # movement
            for idx, c in rotated3D:
                let orig = allDown[idx]
                m2To3[orig] = c + diff

        if allLeft.len() > 0:
            # find the 3D coordinate for each 2D coordinate
            let beforeRotate3D = allLeft.mapIt(m2To3[it])

            # determine reference points for rotation and movement in 2D
            let ref0 = Coord(x: minX, y: minY)
            let ref0b = Coord(x: minX, y: maxY)
            let lineDiff = m2To3[ref0b] - m2To3[ref0]

            let ref1 = Coord(x: minX - 1, y: minY)
            let ref2 = Coord(x: minX - 2, y: minY)
            let ref1Idx = findIndex(allLeft, proc (c: Coord): bool = c == ref1)
            let ref2Idx = findIndex(allLeft, proc (c: Coord): bool = c == ref2)

            #let faceDiffBefore = m2To3[ref1] - m2To3[ref0]
            #echo &"[left] xxx = {xxx}"

            var rotated3D: seq[Coord3D]
            if lineDiff.y == 0:
                rotated3D = rotate3D(m2To3[ref1], beforeRotate3D, 0, 0, 90)
            elif lineDiff.z == 0:
                rotated3D = rotate3D(m2To3[ref1], beforeRotate3D, 90, 0, 0)
            else:
                assert false, "TODO 3"

            let diff = rotated3D[ref2Idx] - rotated3D[ref1Idx] # movement
            for idx, c in rotated3D:
                let orig = allLeft[idx]
                m2To3[orig] = c + diff

        #if i == 4:
        #    break

    let all = m2To3.pairs.toSeq.mapIt((it[1], faceMap[it[0]]))
    let fc = all.mapIt(&"{it[0].x};{it[0].y};{it[0].z};{it[1]}").join("\n")
    writeFile("coords.csv", fc)

    result = initTable[Coord3D, TileType]()



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

    # test "wrap2":
    #     let (board, _, faceMap, side) = parseFile("example")
    #     let wrap2 = createWrap2(faceMap, side)

    #     check(wrap2(board, Coord(x: 11, y: 5), Coord(x: 12, y: 5), Directions.dRight) == (Coord(x: 14, y: 8), Directions.dDown))

    #     check(wrap2(board, Coord(x: 10, y: 11), Coord(x: 10, y: 12), Directions.dDown) == (Coord(x: 1, y: 7), Directions.dUp))

    test "fold":
        let (board, _, faceMap, side) = parseFile("example2")
        discard fold(board, faceMap)
