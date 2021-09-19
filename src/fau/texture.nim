import stb_image/read as stbi, gl/[glproc, gltypes], fmath, util/util

type TextureFilter* = enum
  tfNearest,
  tfLinear

type TextureWrap* = enum
  twClamp,
  twRepeat,
  twMirroredRepeat

type TextureObj = object
  handle*: Gluint
  uwrap, vwrap: TextureWrap
  minfilter, magfilter: TextureFilter
  target: Glenum
  size*: Vec2i
type Texture* = ref TextureObj

proc `=destroy`*(texture: var TextureObj) =
  if texture.handle != 0 and glInitialized:
    glDeleteTexture(texture.handle)
    texture.handle = 0

#binds the texture
#TODO do not export, textures should not be used manually.
proc use*(texture: Texture, unit: int = 0) =
  glActiveTexture((GlTexture0.int + unit).GLenum)
  glBindTexture(texture.target, texture.handle)

proc toGlEnum(filter: TextureFilter): GLenum =
  case filter
  of tfNearest: GlNearest
  of tfLinear: GlLinear

proc toGlEnum(wrap: TextureWrap): GLenum =
  case wrap
  of twClamp: GlClampToEdge
  of twRepeat: GlRepeat
  of twMirroredRepeat: GlMirroredRepeat

proc `filterMin=`*(texture: Texture, filter: TextureFilter) =
  if texture.minfilter != filter:
    texture.minfilter = filter
    texture.use()
    glTexParameteri(texture.target, GlTextureMinFilter, texture.minfilter.toGlEnum.GLint)

proc `filterMag=`*(texture: Texture, filter: TextureFilter) =
  if texture.magfilter != filter:
    texture.magfilter = filter
    texture.use()
    glTexParameteri(texture.target, GlTextureMagFilter, texture.magfilter.toGlEnum.GLint)

#assigns min and mag filters
proc `filter=`*(texture: Texture, filter: TextureFilter) =
  texture.filterMin = filter
  texture.filterMag = filter

proc `wrapU=`*(texture: Texture, wrap: TextureWrap) =
  if texture.uwrap != wrap:
    texture.uwrap = wrap
    texture.use()
    glTexParameteri(texture.target, GlTextureWrapS, texture.uwrap.toGlEnum.GLint)

proc `wrapV=`*(texture: Texture, wrap: TextureWrap) =
  if texture.vwrap != wrap:
    texture.vwrap = wrap
    texture.use()
    glTexParameteri(texture.target, GlTextureWrapT, texture.vwrap.toGlEnum.GLint)

#assigns wrap modes for each axis
proc `wrap=`*(texture: Texture, wrap: TextureWrap) =
  texture.wrapU = wrap
  texture.wrapV = wrap

#completely reloads texture data
proc load*(texture: Texture, size: Vec2i, pixels: pointer) =
  #bind texture
  texture.use()
  glPixelStorei(GlUnpackAlignment, 1)
  glTexImage2D(texture.target, 0, GlRGBA.Glint, size.x.GLsizei, size.y.GLsizei, 0, GlRGBA, GlUnsignedByte, pixels)
  texture.size = size

#updates a portion of a texture with some pixels.
proc update*(texture: Texture, pos: Vec2i, size: Vec2i, pixels: pointer) =
  #bind texture
  texture.use()
  glTexSubImage2D(texture.target, 0, pos.x.GLint, pos.y.GLint, size.x.GLsizei, size.y.GLsizei, GlRGBA, GlUnsignedByte, pixels)

#creates a base texture with no data uploaded
proc newTexture*(size: Vec2i = vec2i(1), filter = tfNearest, wrap = twClamp): Texture = 
  result = Texture(handle: glGenTexture(), uwrap: wrap, vwrap: wrap, minfilter: filter, magfilter: filter, target: GlTexture2D, size: size)
  result.use()

  #set parameters
  glTexParameteri(result.target, GlTextureMinFilter, result.minfilter.toGlEnum.GLint)
  glTexParameteri(result.target, GlTextureMagFilter, result.magfilter.toGlEnum.GLint)
  glTexParameteri(result.target, GlTextureWrapS, result.uwrap.toGlEnum.GLint)
  glTexParameteri(result.target, GlTextureWrapT, result.vwrap.toGlEnum.GLint)

#load texture from ptr to decoded PNG data
proc loadTexturePtr*(size: Vec2i, data: pointer): Texture =
  result = newTexture()

  result.size = size
  result.load(size, data)

#load texture from bytes
proc loadTextureBytes*(bytes: string): Texture =
  result = newTexture()

  var
    width, height, channels: int
    data: seq[uint8]

  data = stbi.loadFromMemory(cast[seq[byte]](bytes), width, height, channels, 4)
  result.load(vec2i(width, height), addr data[0])

  
#load texture from path
proc loadTexture*(path: string): Texture = 
  result = newTexture()

  var
    width, height, channels: int
    data: seq[uint8]

  data = stbi.load(path, width, height, channels, 4)
  result.load(vec2i(width, height), addr data[0])

proc loadTextureStatic*(path: static[string]): Texture =
  when not defined(emscripten):
    loadTextureBytes(staticReadString(path))
  else: #load from filesystem on emscripten
    loadTexture("assets/" & path)
