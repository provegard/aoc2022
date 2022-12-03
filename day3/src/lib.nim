import std/sequtils
import strutils
import std/options
import std/sets
import std/math

proc readLines(file: string): seq[string] =
    return readFile(file).splitLines()

proc priority*(ch: char): int =
    let n = int(ch)
    return (if n >= 97: n - 96 else: n - 38)

proc compartments*(r: string): seq[seq[char]] = r.items.toSeq().distribute(2)

proc setToOpt[T](s: var HashSet[T]): Option[T] = (if s.len() == 1: some(s.pop()) else: none(T))

proc sharedInCompartments*(r: string): Option[char] =
    let cs = compartments(r)
    var inBoth = cs[0].toHashSet() * cs[1].toHashSet()
    return setToOpt(inBoth)

proc rucksackPriority*(r: string): int =
    return sharedInCompartments(r).map(priority).get(0)

proc sharedAmongElves*(elves: seq[string]): Option[char] =
    let s1 = elves[0].toHashSet()
    let s2 = elves[1].toHashSet()
    let s3 = elves[2].toHashSet()
    var s = s1 * s2 * s3
    return setToOpt(s)

proc part1*(file: string): int = readLines(file).map(rucksackPriority).sum()

proc part2*(file: string): int =
    let ll = readLines(file)

    let groups = ll.distribute(ll.len() div 3)
    
    return groups.map(proc(g: seq[string]): int =
        return sharedAmongElves(g).map(priority).get(0)
    ).sum()
    