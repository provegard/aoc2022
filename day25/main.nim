import sequtils
import strutils
import unittest
import sets
import options
import sugar
import algorithm
import strformat
import math

proc parseDigit(ch: char): int64 =
    return case ch
        of '2': 2'i64
        of '1': 1'i64
        of '0': 0'i64
        of '-': -1'i64
        of '=': -2'i64
        else: 0 # irrelevant

proc parseSnafu(s: string): int64 =
    var mx = int64(pow(5.0, float(s.len() - 1)))
    var value = 0'i64
    for ch in s.items:
        value += parseDigit(ch) * mx
        mx = mx div 5'i64
    return value


proc toSnafu(i: int64): string =
    var mx = 1
    var s = ""
    var nm = i
    var mem = 0
    while nm > 0'i64:
        mem = 0
        let ones = nm mod 5
        if ones <= 2:
            s = &"{ones}{s}"
        elif ones == 3:
            mem = 1
            s = &"={s}"
        elif ones == 4:
            mem = 1
            s = &"-{s}"
        nm = (nm div 5) + mem

    return s

proc part1(file: string): string =
    let s = lines(file).toSeq.map(parseSnafu).sum()
    return toSnafu(s)

suite "day 25":
    test "parseSnafu":
        check(parseSnafu("1") == 1'i64)
        check(parseSnafu("2") == 2'i64)
        check(parseSnafu("1=") == 3'i64)
        check(parseSnafu("1-") == 4'i64)
        check(parseSnafu("1-0") == 20'i64)
        check(parseSnafu("1=11-2") == 2022'i64)
        check(parseSnafu("1121-1110-1=0") == 314159265'i64)

    test "toSnafu":
        check(toSnafu(4890'i64) == "2=-1=0")

    test "part1":
        check(part1("example") == "2=-1=0")
        check(part1("input") == "2-==10--=-0101==1201")