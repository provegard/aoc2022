import sequtils
import strutils
import unittest
import sets
import options except flatMap
import sugar
import algorithm
import ../utils/utils
import ../utils/move
import std/nre except toSeq
import strformat

type
    Report = ref object
        sensor: Coord
        beacon: Coord

let lineMatch = re"^Sensor at x=([0-9-]+), y=([0-9-]+): closest beacon is at x=([0-9-]+), y=([0-9-]+)$"

proc sensorRange(r: Report): int =
    return manhattan(r.sensor, r.beacon)

proc parseLine(line: string): Report =
    let m = line.match(lineMatch)
    assert m.isSome
    let x0 = m.get.captures[0].parseInt()
    let y0 = m.get.captures[1].parseInt()
    let x1 = m.get.captures[2].parseInt()
    let y1 = m.get.captures[3].parseInt()
    return Report(sensor: Coord(x: x0, y: y0), beacon: Coord(x: x1, y: y1))
    
proc part1(file: string, y: int): int =
    let ll = lines(file).toSeq
    let reports = ll.map(parseLine)
    let xs = reports.flatMap(proc (r: Report): seq[int] =
        let rng = r.sensorRange()
        return @[r.sensor.x - rng, r.sensor.x + rng]
    )
    let minX = xs.min()
    let maxX = xs.max()

    return (minX..maxX).toSeq().filter(proc (x: int): bool =
        let c = Coord(x: x, y: y)
        return reports.any(proc (r: Report): bool =
            if c == r.sensor or c == r.beacon:
                return false
            let dist = manhattan(r.sensor, c)
            return dist <= r.sensorRange()
        )
    ).len()

proc tuningFreq(c: Coord): int = c.x * 4000000 + c.y

proc draw(xr: (int, int), yr: (int, int), s: HashSet[Coord]) =
    for y in yr[0]..yr[1]:
        for x in xr[0]..xr[1]:
            if s.contains(Coord(x: x, y: y)):
                stdout.write('#')
            else:
                stdout.write('.')
        stdout.write('\n')
    flushFile(stdout)

type Range = (int, int)

proc mergeRanges(a, b: Range): Range = (min(a[0], b[0]), max(a[1], b[1]))

proc overlap(a, b: Range): bool = (b[0] >= a[0] and b[0] <= a[1]) or (a[0] >= b[0] and a[0] <= b[1])

type
    Ranges = ref object
        current: seq[Range]

proc part2(file: string, xMax, yMax: int): int =
    let ll = lines(file).toSeq
    let reports = ll.map(parseLine)

    var ys = newSeq[Ranges](1 + yMax)

    for y in 0..yMax:
        # for each sensor, figure out its x coverage at this y
        var xRanges = newSeq[Range]()
        for r in reports:
            let rng = r.sensorRange()
            let absY = abs(r.sensor.y - y)
            let absX = rng - absY
            if absX < 0:
                # the sensor doesn't see this y
                continue
            # so the x-range is -absX..absX relative to sensor x
            xRanges.add((r.sensor.x - absX, r.sensor.x + absX))

        # merge ranges until there's no overlap
        xRanges.sort(proc (x, y: Range): int = x[0] - y[0])
        var r = xRanges[0]
        for idx in 1..<xRanges.len:
            let r2 = xRanges[idx]
            if not overlap(r, r2):
                # found it!!
                let c = Coord(x: r[1] + 1, y: y)
                return tuningFreq(c)
            r = mergeRanges(r, r2)

    return 0

suite "day 15":
    test "parseLine":
        let line = "Sensor at x=2, y=18: closest beacon is at x=-2, y=15"
        let r = parseLine(line)
        check(r.sensor == Coord(x: 2, y: 18))
        check(r.beacon == Coord(x: -2, y: 15))

    test "part1":
        check(part1("example", 10) == 26)
        check(part1("input", 2000000) == 5564017)

    test "part2":
        check(part2("example", 20, 20) == 56000011)
        check(part2("input", 4000000, 4000000) == 11558423398893)