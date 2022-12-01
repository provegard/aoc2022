import pathlib

def readInputLines(scriptPath):
    inputPath = pathlib.Path(scriptPath).parent.resolve()
    inputPath = str(inputPath) + "/input"
    f = open(inputPath, "r")
    for line in f.readlines():
        yield line.strip()