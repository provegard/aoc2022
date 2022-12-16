import sequtils
import strutils
import unittest
import options
import algorithm
import strformat
import math
import std/nre except toSeq
import tables
import ../utils/utils
import times

type
    Valve = ref object
        id: string
        flowRate: int
        open: bool
        totalPressure: int
        next: seq[string]

proc newValve(id: string, flowRate: int, next: seq[string]): Valve =
    Valve(id: id, flowRate: flowRate, next: next)

proc openValve(v: Valve, timeLeft: int): Valve =
    var v2 = newValve(v.id, v.flowRate, v.next)
    v2.open = true
    v2.totalPressure = timeLeft * v.flowRate
    return v2

let lineMatch = re"^Valve ([A-Z]+) has flow rate=([0-9]+); tunnels? leads? to valves? (.+)$"

proc parseLine(line: string): Valve =
    let m = line.match(lineMatch)
    assert m.isSome
    let id = m.get.captures[0]
    let fr = m.get.captures[1].parseInt()
    let next = m.get.captures[2].replace(",", "").split(" ")
    return newValve(id, fr, next)

proc createLookup(valves: seq[Valve]): Table[string, Valve] =
    var tab = initTable[string, Valve]()
    for v in valves:
        tab[v.id] = v
    return tab

proc neighbors(tab: Table[string, Valve], id: string): seq[string] = tab[id].next

proc findPath(tab: Table[string, Valve], start: string, target: string): seq[string] =
    var dist = initTable[string, int]()
    var prev = initTable[string, string]()
    for id in tab.keys:
        dist[id] = 10000

    proc minF(c: string, d: Table[string, int]): int = d[c]

    dist[start] = 0
    var q = tab.keys.toSeq
    while q.len() > 0:
        let uidx = minByIdx(q, minF, dist)
        let u = q[uidx]

        if u == target:
            var s = newSeq[string]()
            var x = target
            if prev.contains(x) or x == start:
                while true:
                    s.add(x)
                    if not prev.contains(x):
                        break
                    x = prev[x]
            reverse(s)
            return s

        q.delete(uidx)
        for v in neighbors(tab, u):
            let alt = dist[u] + 1
            if alt < dist[v]:
                dist[v] = alt
                prev[v] = u
    return newSeq[string]()

proc sumPressures(tab: Table[string, Valve]): int = tab.values.toSeq.mapIt(it.totalPressure).sum()


proc next(tab: Table[string, Valve], timeLeft: int, currentId: string, cache: var Table[string, int], distCache: var Table[(string, string), int]): int =
    let valve = tab[currentId]

    let cacheKeyParts = concat(tab.values.toSeq.filterIt(it.open).mapIt(it.id), @[currentId, $timeLeft])
    let cacheKey = cacheKeyParts.join("|")

    if cache.contains(cacheKey):
        return cache[cacheKey]

    if timeLeft <= 0:
        let ret = sumPressures(tab)
        cache[cacheKey] = ret
        return ret

    var newTimeLeft = timeLeft

    var tableCopy = tab
    let canOpen = valve.flowRate > 0 and not valve.open
    if canOpen:
        newTimeLeft -= 1 # takes one minute to open
        let openedValve = valve.openValve(newTimeLeft) # makes a copy
        tableCopy[openedValve.id] = openedValve

    # consider closed valves that can be opened
    let targets = tableCopy.values.toSeq.filterIt(not it.open and it.flowRate > 0)

    if newTimeLeft == 0 or targets.len() == 0:
        return sumPressures(tableCopy)

    var results = newSeq[int]()
    for target in targets:
        let pathKey = (currentId, target.id)
        # find path to target
        let pathLen = if distCache.contains(pathKey):
            distCache[pathKey]
        else:
            findPath(tab, currentId, target.id).len()
        distCache[pathKey] = pathLen
        if pathLen == 0:
            # no path to target
            continue

        let moveTime = pathLen - 1 # path includes start, so subtract 1
        let res = next(tableCopy, newTimeLeft - moveTime, target.id, cache, distCache)
        results.add(res)

    assert results.len() > 0

    let ret = results.max()

    cache[cacheKey] = ret

    return ret

proc naive(tab: Table[string, Valve]): int =
    var cache = initTable[string, int]()
    var distCache = initTable[(string, string), int]()
    return next(tab, 30, "AA", cache, distCache)

proc part1(file: string): int =
    let lookup = createLookup(lines(file).toSeq.map(parseLine))
    let before = cpuTime()
    let ret = naive(lookup)
    let elapsed = int(1000 * (cpuTime() - before))
    echo &"file {file} took {elapsed} ms"
    return ret

suite "day 16":
    test "parseLine":
        let v = parseLine("Valve AA has flow rate=2; tunnels lead to valves DD, II, BB")
        check(v.id == "AA")
        check(v.flowRate == 2)
        check(v.open == false)
        check(v.next == @["DD", "II", "BB"])
        check(v.totalPressure == 0)

    test "part1":
        check(part1("example") == 1651)
        check(part1("input") == 1792)