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

suite "day 15":
    test "parseLine":
        let line = "Sensor at x=2, y=18: closest beacon is at x=-2, y=15"
        let r = parseLine(line)
        check(r.sensor == Coord(x: 2, y: 18))
        check(r.beacon == Coord(x: -2, y: 15))

    test "part1":
        check(part1("example", 10) == 26)
        check(part1("input", 2000000) == 5564017)