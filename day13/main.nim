import sequtils
import strutils
import unittest
import sets
import options
import sugar
import algorithm
import math
import strformat

type
    ItemKind = enum
        ikNumber,
        ikList
    List = seq[Item]
    Item = ref object
        case kind: ItemKind
            of ikNumber: numVal: int
            of ikList: listVal: List
    Packet = Item

proc `$`(item: Item): string =
    case item.kind 
        of ItemKind.ikNumber: $item.numVal
        of ItemKind.ikList: $item.listVal

proc `==`(a, b: Item): bool =
    if a.kind != b.kind:
        return false
    return case a.kind
        of ItemKind.ikNumber: a.numVal == b.numVal
        of ItemKind.ikList: a.listVal == b.listVal

proc newNumItem(num: int): Item = Item(kind: ItemKind.ikNumber, numVal: num)
proc newListItem(items: List): Item = Item(kind: ItemKind.ikList, listVal: items)

proc `<`(a, b: Item): bool =
    if a.kind == b.kind:
        case a.kind
            of ItemKind.ikNumber:
                return a.numVal < b.numVal
            of ItemKind.ikList:
                var idx = 0
                for item in a.listVal:
                    if idx >= b.listVal.len():
                        # b is shorter
                        return false
                    if item < b.listVal[idx]:
                        return true
                    if b.listVal[idx] < item:
                        return false
                    idx += 1
                if idx < b.listVal.len():
                    # a is shorter
                    return true
                return false
    if a.kind == ItemKind.ikNumber:
        return newListItem(@[a]) < b
    if b.kind == ItemKind.ikNumber:
        return a < newListItem(@[b])
    return false

proc parseItem(line: string, start: int): (Item, int) =
    var idx = start
    var num = 0
    while idx < line.len():
        let ich = int(line[idx])
        if ich < int('0') or ich > int('9'):
            break
        let val = ich - int('0')
        num = 10 * num + val
        idx += 1
    return (newNumItem(num), idx)

proc parseList(line: string, start: int): (Item, int) =
    var items = newSeq[Item]()
    var idx = start + 1
    while idx < line.len():
        let ch = line[idx]
        case ch
            of '[':
                let (subList, nextIdx) = parseList(line, idx)
                items.add(subList)
                idx = nextIdx
            of ',':
                idx += 1
            of ']':
                idx += 1 # skip closing bracket
                break
            else:
                let (item, nextIdx) = parseItem(line, idx)
                items.add(item)
                idx = nextIdx
    return (newListItem(items), idx)

proc parseLine(line: string): Packet =
    let (list, _) = parseList(line, 0)
    return list

iterator pairs(ll: seq[string]): (Packet, Packet) =
    var packets = newSeq[Packet]()
    for line in ll:
        if line == "":
            yield (packets[0], packets[1])
            packets.setLen(0)
        else:
            packets.add(parseLine(line))
    if packets.len() > 0:
        yield (packets[0], packets[1])

proc part1(file: string): int =
    let ll = lines(file).toSeq
    let pp = pairs(ll).toSeq
    var s = 0
    for idx, pair in pp:
        if pair[0] < pair[1]:
            s += idx + 1
    return s

proc compareItems(a, b: Item): int =
    if a < b:
        return -1
    if a > b:
        return 1
    return 0

proc part2(file: string): int =
    var packets = lines(file).toSeq.filterIt(it != "").map(parseLine)
    let div1 = parseLine("[[2]]")
    let div2 = parseLine("[[6]]")
    packets.add(div1)
    packets.add(div2)

    sort(packets, compareItems)

    let idx1 = 1 + find(packets, div1)
    let idx2 = 1 + find(packets, div2)

    return idx1 * idx2

suite "day 13":
    test "parseLine":
        check(parseLine("[5]") == newListItem(@[newNumItem(5)]))
        check(parseLine("[5,6]") == newListItem(@[newNumItem(5), newNumItem(6)]))
        check(parseLine("[5,[6]]") == newListItem(@[newNumItem(5), newListItem(@[newNumItem(6)])]))
        check(parseLine("[[1],[2]]") == newListItem(@[
            newListItem(@[newNumItem(1)]),
            newListItem(@[newNumItem(2)]),
        ]))        
        check(parseLine("[[1],[2,3,4]]") == newListItem(@[
            newListItem(@[newNumItem(1)]),
            newListItem(@[newNumItem(2), newNumItem(3), newNumItem(4)]),
        ]))

    test "compare":
        check(parseItem("5", 0)[0] < parseItem("6", 0)[0] == true)
        check(parseItem("6", 0)[0] < parseItem("5", 0)[0] == false)

        check(parseList("[5]", 0)[0] < parseList("[6]", 0)[0] == true)
        check(parseList("[6]", 0)[0] < parseList("[5]", 0)[0] == false)
        check(parseList("[5]", 0)[0] < parseList("[5,1]", 0)[0] == true)
        check(parseList("[5,1]", 0)[0] < parseList("[5]", 0)[0] == false)
        check(parseList("[5,1]", 0)[0] < parseList("[5,2]", 0)[0] == true)
        check(parseList("[5,2]", 0)[0] < parseList("[5,1]", 0)[0] == false)

        check(parseItem("5", 0)[0] < parseList("[6]", 0)[0] == true)
        check(parseItem("6", 0)[0] < parseList("[5]", 0)[0] == false)
        check(parseList("[5]", 0)[0] < parseItem("6", 0)[0] == true)

        check(parseLine("[[[]]]") < parseLine("[[]]") == false)
        check(parseLine("[1,1,3,1,1]") < parseLine("[1,1,5,1,1]") == true)
        check(parseLine("[[1],[2,3,4]]") < parseLine("[[1],4]") == true)
        check(parseLine("[9]") < parseLine("[[8,7,6]]") == false)

    test "part1":
        check(part1("example") == 13)
        check(part1("input") == 6070)

    test "part2":
        check(part2("example") == 140)
        check(part2("input") == 20758)