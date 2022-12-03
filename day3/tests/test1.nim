import std/unittest
import std/options
import ../src/lib

suite "functions":

    test "priority":
        check(priority('a') == 1)
        check(priority('z') == 26)
        check(priority('A') == 27)
        check(priority('Z') == 52)

    test "compartments":
        check(compartments("ab") == @[@['a'], @['b']])
        check(compartments("abcd") == @[@['a', 'b'], @['c', 'd']])

    test "sharedInCompartments":
        check(sharedInCompartments("ab") == none(char))
        check(sharedInCompartments("aA") == none(char))
        check(sharedInCompartments("aa") == some('a'))
        check(sharedInCompartments("abca") == some('a'))

    test "rucksackPriority":
        check(rucksackPriority("vJrwpWtwJgWrhcsFMMfFFhFp") == 16)

    test "part1":
        check(part1("example") == 157)
        check(part1("input") == 8072)

    test "sharedAmongElves":
        check(sharedAmongElves(@["abc", "dea", "qra"]) == some('a'))
        check(sharedAmongElves(@["abc", "def", "ghi"]) == none(char))

    test "part2":
        check(part2("example") == 70)
        check(part2("input") == 2567)