version       = "0.0.1"
author        = "Anuken"
description   = "WIP Nim game framework"
license       = "MIT"
srcDir        = ""
bin           = @["tools/faupack", "tools/antialias", "tools/fauproject"]
binDir        = "build"

requires "nim >= 1.4.2"
requires "https://github.com/rlipsc/polymorph#0241b43d60ae37aea881f4a0a550705741b28dc0"
requires "https://github.com/treeform/staticglfw#d299a0d1727054749100a901d3b4f4fa92ed72f5"
requires "cligen >= 1.3.2"
requires "chroma >= 0.2.1"
requires "pixie >= 0.0.20"
requires "https://github.com/treeform/typography#684dbf76e723f503c70d795dbb9006e125c16ccf"
requires "stbimage >= 2.5"