version       = "0.0.1"
author        = "Anuken"
description   = "Basic Nim game framework"
license       = "MIT"
srcDir        = ""
bin           = @["tools/fusepack", "tools/antialias", "tools/fuseproject"]
binDir        = "build"

requires "nim >= 1.4.2"
requires "https://github.com/treeform/staticglfw#d299a0d1727054749100a901d3b4f4fa92ed72f5"
requires "nimPNG >= 0.3.1"
requires "nimterop >= 0.6.13"
requires "chroma >= 0.2.1"
requires "https://github.com/treeform/flippy#badc4e3772ce93790d5b69e330c7f1fc2d354069"