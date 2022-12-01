from utils.utils import readInputLines

def caloriesPerElf(lines):
    cals = []
    for line in lines:
        if line != "":
            cals.append(int(line))
        else:
            yield sum(cals)
            cals = []
    if len(cals) != 0:
        yield sum(cals)

def part1():
    lines = readInputLines(__file__)
    sums = caloriesPerElf(lines)
    print(max(sums))

def part2():
    lines = readInputLines(__file__)
    sums = caloriesPerElf(lines)
    sortedSums = sorted(sums, reverse=True)
    top3 = sortedSums[0:3]
    print(sum(top3))

if __name__ == "__main__":
    part1()
    part2()