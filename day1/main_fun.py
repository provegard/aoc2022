from utils.utils import readInputLines
from itertools import *

def calcCaloriesPerElf(lines):
    return [sum([int(c) for c in itemCalories])
            for (nonEmpty, itemCalories)
            in groupby(lines, lambda x: len(x) > 0)
            if nonEmpty]

def caloriesPerElf():
    return calcCaloriesPerElf(readInputLines(__file__))

def part1():
    calories = caloriesPerElf()
    print(max(calories))

def part2():
    calories = sorted(caloriesPerElf(), reverse=True)
    top3 = calories[0:3]
    print(sum(top3))

if __name__ == "__main__":
    part1()
    part2()