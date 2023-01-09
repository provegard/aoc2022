import strformat
type
  Directions* = enum
    dUp, dRight, dLeft, dDown

let directions* = @[Directions.dUp, Directions.dDown, Directions.dLeft, Directions.dRight]

type Coord* = object
    x*: int
    y*: int

type Coord3D* = object
    x*: int
    y*: int
    z*: int

proc move*(c: Coord, dir: Directions, steps: int = 1): Coord =
    return case dir:
        of Directions.dUp:    Coord(x: c.x, y: c.y - steps)
        of Directions.dDown:  Coord(x: c.x, y: c.y + steps)
        of Directions.dLeft:  Coord(x: c.x - steps, y: c.y)
        of Directions.dRight: Coord(x: c.x + steps, y: c.y)

iterator coordinates*(lines: seq[string]): Coord =
    let columns = lines[0].len()
    for r in 0..<lines.len():
        for c in 0..<columns:
            yield Coord(y: r, x: c)

proc manhattan*(a, b: Coord): int =
    return abs(a.x - b.x) + abs(a.y - b.y)

proc addCoords*(a, b: Coord): Coord = Coord(x: a.x + b.x, y: a.y + b.y)
proc `+`*(a, b: Coord): Coord = addCoords(a, b)
proc `-`*(a, b: Coord): Coord = Coord(x: a.x - b.x, y: a.y - b.y)

proc manhattan*(a, b: Coord3D): int =
    return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)

proc `+`*(a, b: Coord3D): Coord3D = Coord3D(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)
proc `-`*(a, b: Coord3D): Coord3D = Coord3D(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)
proc `$`*(c: Coord3D): string = &"Coord3D(x={c.x}, y={c.y}, z={c.z})"
proc `$`*(c: Coord): string = &"Coord(x={c.x}, y={c.y})"

proc cross_product*(a, b: Coord3D): Coord3D =
    # u=a1i+a2j+a3k
    # v=b1i+b2j+b3k
    # u×v=(a2b3−a3b2)i+(a3b1−a1b3)j+(a1b2−a2b1)k
    let cx = a.y * b.z - a.z * b.y
    let cy = a.z * b.x - a.x * b.z
    let cz = a.x * b.y - a.y * b.x
    result = Coord3D(x: cx, y: cy, z: cz)