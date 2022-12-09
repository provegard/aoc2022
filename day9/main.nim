import sequtils
import strutils
import unittest
import sets
import math
import ../utils/move

type
    Move = object
        direction: Directions
        steps: int

type
    Rope = object
        knots: seq[Coord] # head first

proc parseMove(move: string): Move =
    let parts = move.split(' ')
    let dir = case parts[0][0]:
        of 'R': Directions.dRight
        of 'L': Directions.dLeft
        of 'U': Directions.dUp
        of 'D': Directions.dDown
        else: Directions.dRight #assert(false)
    return Move(direction: dir, steps: ($parts[1]).parseInt())

proc areAdjacent(c1, c2: Coord): bool =
    let xDiff = abs(c1.x - c2.x)
    let yDiff = abs(c1.y - c2.y)
    return xDiff <= 1 and yDiff <= 1

proc moveTowards(c, target: Coord): Coord =
    let ym = sgn(target.y - c.y)
    let xm = sgn(target.x - c.x)
    return Coord(y: c.y + ym, x: c.x + xm)

proc executeMove(rope: Rope, m: Move, s: var HashSet[Coord]): Rope =
    var newKnots = rope.knots
    for i in 1..m.steps:
        newKnots[0] = move(newKnots[0], m.direction)
        for i in 1..<newKnots.len():
            if not areAdjacent(newKnots[i - 1], newKnots[i]):
                newKnots[i] = moveTowards(newKnots[i], newKnots[i - 1])
        s.incl(newKnots[^1]) # tail

    return Rope(knots: newKnots)

proc newRope(length: int): Rope = Rope(knots: (1..length).mapIt(Coord(x: 0, y: 0)))

proc part(file: string, ropeLength: int): int =
    let moves = lines(file).toSeq().mapIt(parseMove(it))
    var s = @[Coord(x: 0, y: 0)].toHashSet()
    let res = foldl(moves, executeMove(a, b, s), newRope(ropeLength))
    return s.len()

proc part1(file: string): int = part(file, 2)
proc part2(file: string): int = part(file, 10)

suite "day 9":
    test "parseMove":
        check(parseMove("R 4") == Move(direction: Directions.dRight, steps: 4))
        check(parseMove("L 10") == Move(direction: Directions.dLeft, steps: 10))
        check(parseMove("U 1") == Move(direction: Directions.dUp, steps: 1))
        check(parseMove("D 2") == Move(direction: Directions.dDown, steps: 2))

    test "moveTowards":
        check(moveTowards(Coord(y: 0, x: 0), Coord(y: 0, x: 2)) == Coord(y: 0, x: 1))
        check(moveTowards(Coord(y: 0, x: 0), Coord(y: -2, x: 0)) == Coord(y: -1, x: 0))
        check(moveTowards(Coord(y: 0, x: 0), Coord(y: -2, x: 1)) == Coord(y: -1, x: 1))

    test "part1":
        check(part1("example") == 13)
        check(part1("input") == 6486)

    test "part2":
        check(part2("example") == 1)
        check(part2("input") == 2678)