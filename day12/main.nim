import sequtils
import unittest
import sets
import ../utils/move
import tables

let directions = @[Directions.dLeft, Directions.dUp, Directions.dRight, Directions.dDown]

type
    Grid = ref object
        cells: Table[Coord, char]
        start: Coord
        endd: Coord

proc isGridPos(grid: Grid, c: Coord): bool = grid.cells.contains(c)
proc elevation(grid: Grid, c: Coord): int = int(grid.cells[c])

proc parse(ll: seq[string]): Grid =
    var cells = initTable[Coord, char]()
    var s: Coord = Coord()
    var e: Coord = Coord()
    for coord in coordinates(ll):
        var elevation = ll[coord.y][coord.x]
        if elevation == 'S':
            s = coord
            elevation = 'a'
        elif elevation == 'E':
            e = coord
            elevation = 'z'
        cells[coord] = elevation
    return Grid(cells: cells, start: s, endd: e)

proc minByIdx[T, U](s: seq[T], f: proc (a: T, b: U): int, arg: U): int =
    var cur = 0
    for i in 1..<s.len():
        if f(s[i], arg) < f(s[cur], arg):
            cur = i
    return cur

proc neighbors(grid: Grid, coord: Coord, validNeighbor: proc (g: Grid, f: Coord, t: Coord): bool): seq[Coord] =
    return directions.mapIt(move(coord, it)).filterIt(isGridPos(grid, it) and validNeighbor(grid, coord, it))

proc dijkstra(grid: Grid, start: Coord, validNeighbor: proc (g: Grid, f: Coord, t: Coord): bool): (Table[Coord, int], Table[Coord, Coord]) =
    var dist = initTable[Coord, int]()
    var prev = initTable[Coord, Coord]()
    for cell in grid.cells.keys:
        dist[cell] = 10000

    proc minF(c: Coord, d: Table[Coord, int]): int = d[c]

    dist[start] = 0
    var q = grid.cells.keys.toSeq
    while q.len() > 0:
        let uidx = minByIdx(q, minF, dist)
        let u = q[uidx]

        q.delete(uidx)
        for v in neighbors(grid, u, validNeighbor):
            let alt = dist[u] + 1
            if alt < dist[v]:
                dist[v] = alt
                prev[v] = u
    return (dist, prev)

iterator startingCoords(grid: Grid): Coord =
    for c in grid.cells.keys():
        if grid.cells[c] == 'a':
            yield c

proc isValidNeighborReverse(grid: Grid, f: Coord, t: Coord): bool =
    let f_elev = elevation(grid, f)
    let t_elev = elevation(grid, t)
    return not (t_elev < f_elev - 1)

proc part1(file: string): int =
    let ll = lines(file).toSeq
    let grid = parse(ll)

    let (dist, _) = dijkstra(grid, grid.endd, isValidNeighborReverse)

    return dist[grid.start]

proc part2(file: string): int =
    let ll = lines(file).toSeq
    let grid = parse(ll)

    let (dist, _) = dijkstra(grid, grid.endd, isValidNeighborReverse)

    return startingCoords(grid).toSeq.mapIt(dist[it]).min()

suite "day 12":
    test "part1":
        check(part1("example") == 31)
        check(part1("input") == 370)

    test "part2":
        check(part2("example") == 29)
        check(part2("input") == 363)
