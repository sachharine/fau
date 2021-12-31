import math, random

#this should be avoided in most cases, but manually turning ints into float32s can be very annoying
converter toFloat32*(i: int): float32 {.inline.} = i.float32

#TODO angle type, distinct float32
#TODO make all angle functions use this
#type Radians = distinct float32
#template deg*(v: float32) = (v * PI / 180.0).Radians
#template rad*(v: float32) = v.Radians
#converter toFloat(r: Radians): float32 {.inline.} = r.float32

## any type that has a time and lifetime
type Timeable* = concept t
  t.time is float32
  t.lifetime is float32

type AnyVec2* = concept t
  t.x is float32
  t.y is float32

## any type that can fade in linearly
type Scaleable* = concept s
  s.fin() is float32

type Vec2i* = object
  x*, y*: int

type Vec2* = object
  x*, y*: float32

#doesn't really belong here, but I need it for shaders.
type Vec3* = object
  x*, y*, z*: float32

#TODO xywh can be vec2s, maybe?
type Rect* = object
  x*, y*, w*, h*: float32

#3x3 matrix for 2D transformations
type Mat* = array[9, float32]

#basic camera
type Cam* = ref object
  #world position
  pos*: Vec2
  #viewport size
  size*: Vec2
  #projection and inverse projection matrix
  mat*, inv*: Mat

iterator d4*(): tuple[x, y: int] =
  yield (1, 0)
  yield (0, 1)
  yield (-1, 0)
  yield (0, -1)

iterator d4i*(): tuple[x, y, i: int] =
  yield (1, 0, 0)
  yield (0, 1, 1)
  yield (-1, 0, 2)
  yield (0, -1, 3)

iterator signs*(): float32 =
  yield 1f
  yield -1f

## fade in from 0 to 1
func fin*(t: Timeable): float32 {.inline.} = t.time / t.lifetime

## fade in from 1 to 0
func fout*(t: Scaleable): float32 {.inline.} = 1.0f - t.fin

## fade in from 0 to 1 to 0
func fouts*(t: Scaleable): float32 {.inline.} = 2.0 * abs(t.fin - 0.5)

## fade in from 1 to 0 to 1
func fins*(t: Scaleable): float32 {.inline.} = 1.0 - t.fouts

func powout*(a, power: float32): float32 {.inline.} = 
  result = pow(a - 1, power) * (if power mod 2 == 0: -1 else: 1) + 1
  if isNan(result): result = 0f

#utility functions

func zero*(val: float32, margin: float32 = 0.0001f): bool {.inline.} = abs(val) <= margin
func clamp*(val: float32): float32 {.inline.} = clamp(val, 0f, 1f)

func lerp*(a, b, progress: float32): float32 {.inline.} = a + (b - a) * progress
func lerpc*(a, b, progress: float32): float32 {.inline.} = a + (b - a) * clamp(progress)

func inv*(f: float32): float32 {.inline.} = 1f / f

## euclid mod functions (equivalent versions are coming in a future Nim release)
func emod*(a, b: float32): float32 {.inline.} =
  result = a mod b
  if result >= 0: discard
  elif b > 0: result += b
  else: result -= b

func emod*(a, b: int): int {.inline.} =
  result = a mod b
  if result >= 0: discard
  elif b > 0: result += b
  else: result -= b

{.push checks: off.}

## hashes an integer to a random positive integer
func hashInt*(value: int): int {.inline.} =
  var x = value.uint64
  x = x xor (x shr 33)
  x *= 0xff51afd7ed558ccd'u64
  x = x xor (x shr 33)
  x *= 0xc4ceb9fe1a85ec53'u64
  x = x xor (x shr 33)
  return x.int.abs

proc chance*(c: float): bool = rand(0.0..1.0) < c

{.pop.}

#angle/degree functions; all are in radians

const pi2* = PI * 2.0

func rad*(val: float32): float32 {.inline.} = val * PI / 180.0
func deg*(val: float32): float32 {.inline.} = val / (PI / 180.0)

## angle lerp
func alerp*(fromDegrees, toDegrees, progress: float32): float32 = ((fromDegrees + (((toDegrees - fromDegrees + 360.rad + 180.rad) mod 360.rad) - 180.rad) * progress + 360.0.rad)) mod 360.rad

## angle dist
func adist*(a, b: float32): float32 {.inline.} = min(if a - b < 0: a - b + 360.0.rad else: a - b, if b - a < 0: b - a + 360.0.rad else: b - a)

## angle within other angle
func awithin*(a, b: float32, tolerance = 0.01f): bool {.inline.} = adist(a, b) <= tolerance

## angle approach
func aapproach*(a, b, amount: float32): float32 =
  let 
    forw = abs(a - b)
    back = 360.0.rad - forw
    diff = adist(a, b)
  
  return if diff <= amount: b
  elif (a > b) == (back > forw): (a - amount).emod 360.rad
  else: (a + amount).emod 360.rad

## angle clamp
func aclamp*(angle, dest, dst: float32): float32 =
  let diff = adist(angle, dest)
  if diff <= dst: angle
  else: angle.aapproach(dest, diff - dst)

func dst*(x1, y1, z1, x2, y2, z2: float32): float32 {.inline.} =
  let 
    a = x1 - x2
    b = y1 - y2
    c = z1 - z2
  return sqrt(a*a + b*b + c*c)

func dst*(x1, y1, x2, y2: float32): float32 {.inline.} =
  let 
    a = x1 - x2
    b = y1 - y2
  return sqrt(a*a + b*b)

func len*(x, y: float32): float32 {.inline.} = sqrt(x*x + y*y)
func len2*(x, y: float32): float32 {.inline.} = x*x + y*y

func sign*(x: float32): float32 {.inline.} = 
  if x < 0: -1 else: 1
func sign*(x: bool): float32 {.inline.} = 
  if x: 1 else: -1
func signi*(x: bool): int {.inline.} = 
  if x: 1 else: -1

func sin*(x, scl, mag: float32): float32 {.inline} = sin(x / scl) * mag
func cos*(x, scl, mag: float32): float32 {.inline} = cos(x / scl) * mag

func absin*(x, scl, mag: float32): float32 {.inline} = (sin(x / scl) * mag).abs
func abcos*(x, scl, mag: float32): float32 {.inline} = (cos(x / scl) * mag).abs

template vec2*(cx, cy: float32): Vec2 = Vec2(x: cx, y: cy)
proc vec2*(xy: float32): Vec2 {.inline.} = Vec2(x: xy, y: xy)
proc vec2*(pos: AnyVec2): Vec2 {.inline.} = Vec2(x: pos.x, y: pos.y)
template vec2*(): Vec2 = Vec2()
func vec2l*(angle, mag: float32): Vec2 {.inline.} = vec2(mag * cos(angle), mag * sin(angle))
proc randVec*(len: float32): Vec2 {.inline.} = vec2l(rand(0f..(PI.float32 * 2f)), rand(0f..len))
proc randRangeVec*(r: float32): Vec2 {.inline.} = vec2(rand(-r..r), rand(-r..r))

#vec2i stuff

func vec2i*(x, y: int): Vec2i {.inline.} = Vec2i(x: x, y: y)
func vec2i*(xy: int): Vec2i {.inline.} = Vec2i(x: xy, y: xy)
func vec2i*(): Vec2i {.inline.} = Vec2i()
func vec2*(v: Vec2i): Vec2 {.inline.} = vec2(v.x.float32, v.y.float32)
func vec2i*(v: Vec2): Vec2i {.inline.} = vec2i(v.x.int, v.y.int)

#vector-vector operations

template op(td: typedesc, comp: typedesc, cons: typed, op1, op2: untyped): untyped =
  func op1*(vec: td, other: td): td {.inline.} = cons(op1(vec.x, other.x), op1(vec.y, other.y))
  func op1*(vec: td, other: comp): td {.inline.} = cons(op1(vec.x, other), op1(vec.y, other))
  func op2*(vec: var td, other: td) {.inline.} = vec = cons(op1(vec.x, other.x), op1(vec.y, other.y))
  func op2*(vec: var td, other: comp) {.inline.} = vec = cons(op1(vec.x, other), op1(vec.y, other))

op(Vec2, float32, vec2, `+`, `+=`)
op(Vec2, float32, vec2, `-`, `-=`)
op(Vec2, float32, vec2, `*`, `*=`)
op(Vec2, float32, vec2, `/`, `/=`)

func `-`*(vec: Vec2): Vec2 {.inline.} = vec2(-vec.x, -vec.y)

op(Vec2i, int, vec2i, `+`, `+=`)
op(Vec2i, int, vec2i, `-`, `-=`)
op(Vec2i, int, vec2i, `*`, `*=`)
op(Vec2i, int, vec2i, `div`, `div=`)

func `-`*(vec: Vec2i): Vec2i {.inline.} = vec2i(-vec.x, -vec.y)

#utility methods

func `lerp`*(vec: var Vec2, other: Vec2, alpha: float32) {.inline.} = 
  let invAlpha = 1.0f - alpha
  vec = vec2((vec.x * invAlpha) + (other.x * alpha), (vec.y * invAlpha) + (other.y * alpha))

func `lerp`*(vec: Vec2, other: Vec2, alpha: float32): Vec2 {.inline.} = 
  let invAlpha = 1.0f - alpha
  return vec2((vec.x * invAlpha) + (other.x * alpha), (vec.y * invAlpha) + (other.y * alpha))

func floor*(vec: Vec2): Vec2 {.inline.} = vec2(vec.x.floor, vec.y.floor)

func abs*(vec: Vec2): Vec2 {.inline.} = vec2(vec.x.abs, vec.y.abs)

#returns this vector's x/y aspect ratio
func ratio*(vec: Vec2): float32 {.inline.} = vec.x / vec.y

#all angles are in radians

func angle*(vec: Vec2): float32 {.inline.} = 
  let res = arctan2(vec.y, vec.x)
  return if res < 0: res + PI*2.0 else: res

func angle*(x, y: float32): float32 {.inline.} =
  let res = arctan2(y, x)
  return if res < 0: res + PI*2.0 else: res

func angle*(vec: Vec2, other: Vec2): float32 {.inline.} = 
  let res = arctan2(other.y - vec.y, other.x - vec.x)
  return if res < 0: res + PI*2.0 else: res

func rotate*(vec: Vec2, rads: float32): Vec2 = 
  let co = cos(rads)
  let si = sin(rads)
  return vec2(vec.x * co - vec.y * si, vec.x * si + vec.y * co)

func len*(vec: Vec2): float32 {.inline.} = sqrt(vec.x * vec.x + vec.y * vec.y)
func len2*(vec: Vec2): float32 {.inline.} = vec.x * vec.x + vec.y * vec.y
func `len=`*(vec: var Vec2, b: float32) = vec *= b / vec.len

func angled*(vec: Vec2, angle: float32): Vec2 {.inline.} =
  vec2l(angle, vec.len)

func nor*(vec: Vec2): Vec2 {.inline.} = 
  let len = vec.len
  return if len == 0f: vec else: vec / len

func lim*(vec: Vec2, limit: float32): Vec2 = 
  let l2 = vec.len2
  let limit2 = limit*limit
  return if l2 > limit2: vec * sqrt(limit2 / l2) else: vec

func dst2*(vec: Vec2, other: Vec2): float32 {.inline.} = 
  let dx = vec.x - other.x
  let dy = vec.y - other.y
  return dx * dx + dy * dy

func dst*(vec: Vec2, other: Vec2): float32 {.inline.} = sqrt(vec.dst2(other))

func within*(vec: Vec2, other: Vec2, distance: float32): bool {.inline.} = vec.dst2(other) <= distance*distance

proc `$`*(vec: Vec2): string = $vec.x & ", " & $vec.y

proc inside*(x, y, w, h: int): bool {.inline.} = x >= 0 and y >= 0 and x < w and y < h
proc inside*(p: Vec2i, w, h: int): bool {.inline.} = p.x >= 0 and p.y >= 0 and p.x < w and p.y < h
proc inside*(p: Vec2i, size: Vec2i): bool {.inline.} = p.x >= 0 and p.y >= 0 and p.x < size.x and p.y < size.y

#Implementation of bresenham's line algorithm; iterates through a line connecting the two points.
iterator line*(p1, p2: Vec2i): Vec2i =
  let 
    dx = abs(p2.x - p1.x)
    dy = abs(p2.y - p1.y)
    sx = if p1.x < p2.x: 1 else: -1
    sy = if p1.y < p2.y: 1 else: -1

  var
    startX = p1.x
    startY = p1.y

    err = dx - dy
    e2 = 0
  
  while true:
    yield vec2i(startX, startY)
    if startX == p2.x and startY == p2.y: break
    e2 = 2 * err
    if e2 > -dy:
      err -= dy
      startX += sx
    
    if e2 < dx:
      err += dx
      startY += sy
      
#rectangle utility class

proc rect*(x, y, w, h: float32): Rect {.inline.} = Rect(x: x, y: y, w: w, h: h)
proc rect*(xy: Vec2, w, h: float32): Rect {.inline.} = Rect(x: xy.x, y: xy.y, w: w, h: h)
proc rect*(xy: Vec2, size: Vec2): Rect {.inline.} = Rect(x: xy.x, y: xy.y, w: size.x, h: size.y)
proc rectCenter*(x, y, w, h: float32): Rect {.inline.} = Rect(x: x - w/2.0, y: y - h/2.0, w: w, h: h)
proc rectCenter*(x, y, s: float32): Rect {.inline.} = Rect(x: x - s/2.0, y: y - s/2.0, w: s, h: s)

proc xy*(r: Rect): Vec2 {.inline.} = vec2(r.x, r.y)
proc `xy=`*(r: var Rect, pos: Vec2) {.inline.} =
  r.x = pos.x
  r.y = pos.y
proc pos*(r: Rect): Vec2 {.inline.} = vec2(r.x, r.y)
proc size*(r: Rect): Vec2 {.inline.} = vec2(r.w, r.h)

proc top*(r: Rect): float32 {.inline.} = r.y + r.h
proc right*(r: Rect): float32 {.inline.} = r.x + r.w

proc x2*(r: Rect): float32 {.inline.} = r.y + r.h
proc y2*(r: Rect): float32 {.inline.} = r.x + r.w

proc grow*(r: var Rect, amount: float32) = r = rect(r.x - amount/2f, r.y - amount/2f, r.w + amount, r.h + amount)
proc grow*(r: Rect, amount: float32): Rect = rect(r.x - amount/2f, r.y - amount/2f, r.w + amount, r.h + amount)

proc centerX*(r: Rect): float32 {.inline.} = r.x + r.w/2.0
proc centerY*(r: Rect): float32 {.inline.} = r.y + r.h/2.0
proc center*(r: Rect): Vec2 {.inline.} = vec2(r.x + r.w/2.0, r.y + r.h/2.0)

proc merge*(r: Rect, other: Rect): Rect =
  result.x = min(r.x, other.x)
  result.y = min(r.y, other.y)
  result.w = max(r.right, other.right) - result.x
  result.h = max(r.top, other.top) - result.y

proc intersect*(r1: Rect, r2: Rect): Rect =
  var
    x1 = max(r1.x, r2.x)
    y1 = max(r1.y, r2.y)
    x2 = max(r1.x2, r2.x2)
    y2 = max(r1.y2, r2.y2)
  
  if x2 < x1: x2 = x1
  if y2 < y1: y2 = y1
  return rect(x1, y1, x2 - x1, y2 - y1)

#collision stuff

proc contains*(r: Rect, x, y: float32): bool {.inline.} = r.x <= x and r.x + r.w >= x and r.y <= y and r.y + r.h >= y
proc contains*(r: Rect, pos: Vec2): bool {.inline.} = r.contains(pos.x, pos.y)

proc overlaps*(a, b: Rect): bool = a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y

proc overlaps(r1: Rect, v1: Vec2, r2: Rect, v2: Vec2, hitPos: var Vec2): bool =
  let vel = v1 - v2

  var invEntry, invExit: Vec2

  if vel.x > 0.0:
    invEntry.x = r2.x - (r1.x + r1.w)
    invExit.x = (r2.x + r2.w) - r1.x
  else:
    invEntry.x = (r2.x + r2.w) - r1.x
    invExit.x = r2.x - (r1.x + r1.w)

  if vel.y > 0.0:
    invEntry.y = r2.y - (r1.y + r1.h)
    invExit.y = (r2.y + r2.h) - r1.y
  else:
    invEntry.y = (r2.y + r2.h) - r1.y
    invExit.y = r2.y - (r1.y + r1.h)

  let 
    entry = invEntry / vel
    exit = invExit / vel
    entryTime = max(entry.x, entry.y)
    exitTime = min(exit.x, exit.y)

  if entryTime > exitTime or exit.x < 0.0 or exit.y < 0.0 or entry.x > 1.0 or entry.y > 1.0:
    return false
  else:
    hitPos = vec2(r1.x + r1.w / 2f + v1.x * entryTime, r1.y + r1.h / 2f + v1.y * entryTime)
    return true

proc penetrationX*(a, b: Rect): float32 {.inline.} =
  let nx = a.centerX - b.centerX
  result = a.w / 2 + b.w / 2 - abs(nx) + 0.000001
  if nx < 0: result = -result

proc penetrationY*(a, b: Rect): float32 {.inline.} =
  let ny = a.centerY - b.centerY
  result = a.h / 2 + b.h / 2 - abs(ny) + 0.000001
  if ny < 0: result = -result

proc penetration*(a, b: Rect): Vec2 = vec2(penetrationX(a, b), penetrationY(a, b))

#moves a hitbox; may be removed later
proc moveDelta*(box: Rect, vel: Vec2, solidity: proc(x, y: int): bool): Vec2 = 
  let
    left = (box.x + 0.5).int - 1
    bottom = (box.y + 0.5).int - 1
    right = (box.x + 0.5 + box.w).int + 1
    top = (box.y + 0.5 + box.h).int + 1
  
  var hitbox = box
  
  hitbox.x += vel.x

  for dx in left..right:
    for dy in bottom..top:
      if solidity(dx, dy):
        let tile = rect((dx).float32 - 0.5f, (dy).float32 - 0.5f, 1, 1)
        if hitbox.overlaps(tile):
          hitbox.x -= tile.penetrationX(hitbox)
  
  hitbox.y += vel.y

  for dx in left..right:
    for dy in bottom..top:
      if solidity(dx, dy):
        let tile = rect((dx).float32 - 0.5f, (dy).float32 - 0.5f, 1, 1)
        if hitbox.overlaps(tile):
          hitbox.y -= tile.penetrationY(hitbox)
  
  return vec2(hitbox.x - box.x, hitbox.y - box.y)

#returns true if the hitbox hits any tiles
proc collidesTiles*(box: Rect, solidity: proc(x, y: int): bool): bool = 
  let
    left = (box.x + 0.5).int - 1
    bottom = (box.y + 0.5).int - 1
    right = (box.x + 0.5 + box.w).int + 1
    top = (box.y + 0.5 + box.h).int + 1

  for dx in left..right:
    for dy in bottom..top:
      if solidity(dx, dy):
        let tile = rect((dx).float32 - 0.5f, (dy).float32 - 0.5f, 1, 1)
        if box.overlaps(tile):
          return true
  
  return false


## Returns a point on the segment nearest to the specified point.
proc nearestSegmentPoint*(a, b, point: Vec2): Vec2 =
  let length2 = a.dst2(b)
  if length2 == 0f: return a
  let t = ((point.x - a.x) * (b.x - a.x) + (point.y - a.y) * (b.y - a.y)) / length2
  if t < 0: return a
  if t > 1: return b
  return a + (b - a) * t

## Returns the distance between the given segment and point.
proc distanceSegmentPoint*(a, b, point: Vec2): float32 = nearestSegmentPoint(a, b, point).dst(point)

## Distance between a rectangle and a point.
proc dst*(r: Rect, point: Vec2): float32 =
  if r.contains(point): 0f
  else: min(
    min(
      distanceSegmentPoint(r.xy, r.xy + vec2(r.w, 0f), point),
      distanceSegmentPoint(r.xy, r.xy + vec2(0f, r.h), point)
    ),
    min(
      distanceSegmentPoint(r.xy + r.size, r.xy + vec2(r.w, 0f), point),
      distanceSegmentPoint(r.xy + r.size, r.xy + vec2(0f, r.h), point)
    )
  )

const 
  M00 = 0
  M01 = 3
  M02 = 6
  M10 = 1
  M11 = 4
  M12 = 7
  M20 = 2
  M21 = 5
  M22 = 8

#converts a 2D orthographics 3x3 matrix to a 4x4 matrix for shaders
proc toMat4*(matrix: Mat): array[16, float32] =
  result[4] = matrix[M01]
  result[1] = matrix[M10]

  result[0] = matrix[M00]
  result[5] = matrix[M11]
  result[10] = matrix[M22]
  result[12] = matrix[M02]
  result[13] = matrix[M12]
  result[15] = 1

#creates an identity matrix
proc idt*(): Mat = [1f, 0, 0, 0, 1, 0, 0, 0, 1]

#orthographic projection matrix
proc ortho*(x, y, width, height: float32): Mat =
  let right = x + width
  let top = y + height
  let xOrth = 2 / (right - x);
  let yOrth = 2 / (top - y);
  let tx = -(right + x) / (right - x);
  let ty = -(top + y) / (top - y);

  return [xOrth, 0, 0, 0, yOrth, 0, tx, ty, 1]

proc ortho*(pos, size: Vec2): Mat {.inline.} = ortho(pos.x, pos.y, size.x, size.y)

proc ortho*(size: Vec2): Mat {.inline.} = ortho(0, 0, size.x, size.y)

proc ortho*(size: Vec2i): Mat {.inline.} = ortho(size.vec2)

proc `*`*(a: Mat, b: Mat): Mat = [
    a[M00] * b[M00] + a[M01] * b[M10] + a[M02] * b[M20], 
    a[M00] * b[M01] + a[M01] * b[M11] + a[M02] * b[M21],
    a[M00] * b[M02] + a[M01] * b[M12] + a[M02] * b[M22],
    a[M10] * b[M00] + a[M11] * b[M10] + a[M12] * b[M20],
    a[M10] * b[M01] + a[M11] * b[M11] + a[M12] * b[M21],
    a[M10] * b[M02] + a[M11] * b[M12] + a[M12] * b[M22],
    a[M20] * b[M00] + a[M21] * b[M10] + a[M22] * b[M20],
    a[M20] * b[M01] + a[M21] * b[M11] + a[M22] * b[M21],
    a[M20] * b[M02] + a[M21] * b[M12] + a[M22] * b[M22]
  ]

proc det*(self: Mat): float32 =
  return self[M00] * self[M11] * self[M22] + self[M01] * self[M12] * self[M20] + self[M02] * self[M10] * self[M21] -
    self[M00] * self[M12] * self[M21] - self[M01] * self[M10] * self[M22] - self[M02] * self[M11] * self[M20]

proc inv*(self: Mat): Mat =
  let invd = 1 / self.det()

  if invd == 0.0: raise newException(Exception, "Can't invert a singular matrix")

  return [
    (self[M11] * self[M22] - self[M21] * self[M12]) * invd,
    (self[M20] * self[M12] - self[M10] * self[M22]) * invd,
    (self[M10] * self[M21] - self[M20] * self[M11]) * invd,
    (self[M21] * self[M02] - self[M01] * self[M22]) * invd,
    (self[M00] * self[M22] - self[M20] * self[M02]) * invd,
    (self[M20] * self[M01] - self[M00] * self[M21]) * invd,
    (self[M01] * self[M12] - self[M11] * self[M02]) * invd,
    (self[M10] * self[M02] - self[M00] * self[M12]) * invd,
    (self[M00] * self[M11] - self[M10] * self[M01]) * invd
  ]

proc `*`*(self: Vec2, mat: Mat): Vec2 = vec2(self.x * mat[0] + self.y * mat[3] + mat[6], self.x * mat[1] + self.y * mat[4] + mat[7])

#PARTICLES

## Stateless particles based on RNG. x/y are injected into template body.
template particles*(seed: int, amount: int, ppos: Vec2, radius: float32, body: untyped) =
  var r {.inject.} = initRand(seed)
  for i in 0..<amount:
    let 
      rot {.inject.} = r.rand(360f.rad).float32
      v = vec2l(rot, r.rand(radius))
      pos {.inject.} = ppos + v
    body

## Stateless particles based on RNG. x/y are injected into template body.
template particlesAngle*(seed: int, amount: int, ppos: Vec2, radius: float32, rotation, spread: float32, body: untyped) =
  var r {.inject.} = initRand(seed)
  for i in 0..<amount:
    let
      rot {.inject.} = rotation + r.rand(-spread..spread).float32
      v = vec2l(rot, r.rand(radius))
      pos {.inject.} = ppos + v
    body

## Stateless particles based on RNG. x/y are injected into template body.
template particlesLife*(seed: int, amount: int, ppos: Vec2, basefin: float32, radius: float32, body: untyped) =
  var r {.inject.} = initRand(seed)
  for i in 0..<amount:
    let
      lscl = r.rand(0.1f..1f)
      fin {.inject.} = basefin / lscl
      fout {.inject.} = 1f - fin
      rot {.inject.} = r.rand(360f.rad).float32
      count {.inject.} = i
      v = vec2l(rot, r.rand(radius * fin))
      pos {.inject.} = ppos + v
    if fin <= 1f:
      body

template circle*(amount: int, body: untyped) =
  for i in 0..<amount:
    let angle {.inject.} = (i.float32 / amount.float32 * 360f).degToRad
    body

template circlev*(amount: int, len: float32, body: untyped) =
  for i in 0..<amount:
    let
      angle {.inject.} = (i.float32 / amount.float32 * 360f).degToRad
      v = vec2l(angle, len)
      x {.inject.} = v.x
      y {.inject.} = v.y
    body

template shotgun*(amount: int, spacing: float32, body: untyped) =
  for i in 0..<amount:
    let angle {.inject.} = ((i - (amount div 2).float32) * spacing).degToRad
    body


#CAMERA

proc width*(cam: Cam): float32 {.inline.} = cam.size.x
proc height*(cam: Cam): float32 {.inline.} = cam.size.y

proc update*(cam: Cam, size: Vec2 = cam.size, pos = cam.pos) = 
  cam.size = size
  cam.pos = pos
  cam.mat = ortho(cam.pos - cam.size/2f, cam.size)
  cam.inv = cam.mat.inv()

proc newCam*(size: Vec2): Cam = 
  result = Cam(pos: vec2(0.0, 0.0), size: size)
  result.update()

proc viewport*(cam: Cam): Rect {.inline.} = rect(cam.pos - cam.size/2f, cam.size)