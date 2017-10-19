#
# types.jl -
#
# Type definitions for Julia interface to scientific cameras.
#
#------------------------------------------------------------------------------
#
# This file is part of the `ScientificCameras.jl` package which is licensed
# under the MIT "Expat" License.
#
# Copyright (C) 2017, Éric Thiébaut.
#

"""

Concrete types derived from abstract type `ScientificCamera` are used to
uniquely identify the different camera models or different combinations of
camera model and frame grabber.

"""
abstract type ScientificCamera end

"""

`ROI` is a structure to store a region of interest (ROI), its fields are:

- `xsub`:   Horizontal size of macro-pixels (in pixels).
- `ysub`:   Vertical size of macro-pixels (in pixels).
- `xoff`:   Horizontal offset in pixels of the ROI relative to the sensor.
- `yoff`:   Vertical offset in pixels of the ROI relative to the sensor.
- `width`:  Width in macro-pixels of the ROI.
- `height`: Height in macro-pixels of the ROI.

All fields are integer valued (of type `Int`).  A ROI is constructed by:

    ROI(xsub, ysub, xoff, yoff, width, height)

or

    ROI(xoff, yoff, width, height)

which assumes macro-pixels of same size as pixels, or

    ROI(width, height)

which assumes macro-pixels of same size as pixels and zero offsets.  Note that
for efficiency reasons, there is no testing of the validity of the settings but
you may use `checkroi` for that.

See also: [`getroi`](@ref), [`setroi!`](@ref), [`resetroi!`](@ref),
          [`checkroi`](@ref).

"""
mutable struct ROI
    xsub::Int
    ysub::Int
    xoff::Int
    yoff::Int
    width::Int
    height::Int
    ROI(xsub::Integer, ysub::Integer, xoff::Integer, yoff::Integer, width::Integer, height::Integer) =
        new(xsub, ysub, xoff, yoff, width, height)
    ROI(xoff::Integer, yoff::Integer, width::Integer, height::Integer) =
        new(1, 1, xoff, yoff, width, height)
    ROI(width::Integer, height::Integer) =
        new(1, 1, 0, 0, width, height)
end

# Custom exception to report errors for non-extended methods.
struct NotImplementedException <: Exception
   sym::Symbol
end

#------------------------------------------------------------------------------
# PIXEL FORMATS AND EQUIVALENT BITS TYPES

"""

`ScientificCameras.PixelFormat{N}` is the super-type of the various pixel
formats and is parameterized by `N` the number of bits per pixel.

Actual pixel formats are concrete sub-types of `PixelFormat{N}`.  The type
hierarchy is:

    PixelFormat{N} (abstract)
     |- Monochrome{N} (concrete)
     `- ColorFormat{N} (abstract)
         |- RGB{N} (concrete)
         |- BGR{N} (concrete)
         |- XRGB{N} (concrete)
         |- XBGR{N} (concrete)
         |- RGBX{N} (concrete)
         |- BGRX{N} (concrete)
         |- BayerFormat{N} (abstract)
         |   |- BayerRGGB{N} (concrete)
         |   |- BayerGRBG{N} (concrete)
         |   |- BayerBGGR{N} (concrete)
         |   `- BayerBGGR{N} (concrete)
         `- YUV422 (concrete)
       (etc.)

Note that *concrete* types (the leaves of the above tree) are all singletons.
This system forbids to have concrete definitions which provide an equivalent
Julia *bits*, that is *plain data*, type.  This is not really an isssue since
pixel formats are just meant to describe the pixel format used by a camera, not
to provide Julia equivalent bits types.  To get the equivalent bits type (when
it exists), call:

    equivalentbitstype(format)

which returns `Void` when there is no possible exact equivalence.

See also: [`equivalentbitstype`](@ref), [`bitsperpixel`](@ref),
          [`ScientificCameras.Monochrome`](@ref),
          [`ScientificCameras.ColorFormat`](@ref).

"""
abstract type PixelFormat{N} end

"""

`ScientificCameras.Monochrome{N}` is a monochrome pixel format where each pixel
is encoded with `N` bits.

See also: [`ScientificCameras.PixelFormat`](@ref).

"""
struct Monochrome{N} <: PixelFormat{N}; end

"""

`ScientificCameras.ColorFormat{N}` is the super-type of colored pixel formats
where each pixel is encoded with `N` bits.

See also: [`ScientificCameras.PixelFormat`](@ref).

"""
abstract type ColorFormat{N} <: PixelFormat{N} end

"""

`ScientificCameras.BayerFormat{N}` is a colored pixel format where the color is
encoded on 4 pixels (1 red, 2 green and 1 blue) each with `N` bits.  There are
several *concrete* sub-types:

- `BayerRGGB{N}` is Bayer format with the mask `['R' 'G'; 'G' 'B']`.
- `BayerGRBG{N}` is Bayer format with the mask `['G' 'R'; 'B' 'G']`.
- `BayerGBRG{N}` is Bayer format with the mask `['G' 'B'; 'R' 'G']`.
- `BayerBGGR{N}` is Bayer format with the mask `['B' 'G'; 'G' 'R']`.

See also: [`ScientificCameras.PixelFormat`](@ref),
          [`ScientificCameras.ColorFormat`](@ref).

"""
abstract type BayerFormat{N} <: ColorFormat{N} end

# Concrete sub-types.
struct BayerRGGB{N} <: BayerFormat{N}; end
struct BayerGRBG{N} <: BayerFormat{N}; end
struct BayerGBRG{N} <: BayerFormat{N}; end
struct BayerBGGR{N} <: BayerFormat{N}; end

"""

`ScientificCameras.RGB{N}` is a packed pixel color format where each pixel
counts `N` bits and encodes the red, green and blue levels (in that order).

See also: [`ScientificCameras.ColorFormat`](@ref),
          [`ScientificCameras.BGR`](@ref).

"""
struct RGB{N} <: ColorFormat{N}; end

"""

`ScientificCameras.BGR{N}` is a packed pixel color format where each pixel
counts `N` bits and encodes the blue, green and red levels (in that order).

See also: [`ScientificCameras.ColorFormat`](@ref),
          [`ScientificCameras.RGB`](@ref).

"""
struct BGR{N} <: ColorFormat{N}; end

"""

`ScientificCameras.XRGB{N}` is a packed pixel color format where each pixel
counts `N` bits and encodes some padding (the "X") followed by the red, green
and blue levels (in that order).

`ScientificCameras.XBGR{N}`, `ScientificCameras.RGBX{N}` and
`ScientificCameras.BGRX{N}` are similar packed pixel color formats with
different ordering of the components in memory.

See also: [`ScientificCameras.ColorFormat`](@ref),
          [`ScientificCameras.BGR`](@ref).

"""
struct XRGB{N} <: ColorFormat{N}; end
struct XBGR{N} <: ColorFormat{N}; end
struct RGBX{N} <: ColorFormat{N}; end
struct BGRX{N} <: ColorFormat{N}; end

@doc @doc(XRGB) XBGR
@doc @doc(XRGB) RGBX
@doc @doc(XRGB) BGRX

# Note that whatever the ordering of values in memory, the constructors use
# always the same order: R, G, B and, possibly, X (which defaults to 0).
struct RGB24BitsType
    r::UInt8
    g::UInt8
    b::UInt8
    RGB24BitsType(r, g, b) = new(r, g, b)
end

struct BGR24BitsType
    b::UInt8
    g::UInt8
    r::UInt8
    BGR24BitsType(r, g, b) = new(b, g, r)
end

struct XRGB32BitsType
    x::UInt8
    r::UInt8
    g::UInt8
    b::UInt8
    XRGB32BitsType(r, g, b, x = zero(UInt8)) = new(x, r, g, b)
end

struct XBGR32BitsType
    x::UInt8
    b::UInt8
    g::UInt8
    r::UInt8
    XBGR32BitsType(r, g, b, x = zero(UInt8)) = new(x, b, g, r)
end

struct RGBX32BitsType
    r::UInt8
    g::UInt8
    b::UInt8
    x::UInt8
    RGBX32BitsType(r, g, b, x = zero(UInt8)) = new(r, g, b, x)
end

struct BGRX32BitsType
    b::UInt8
    g::UInt8
    r::UInt8
    x::UInt8
    BGRX32BitsType(r, g, b, x = zero(UInt8)) = new(b, g, r, x)
end

"""

`YUV422` is a 32-bit packed color format which encodes Y, U and V color
components in a macro pixel with 4 bytes U, Y0, V and Y1 (in that order) where
Y0 and Y1 are the lowest and highest significant bytes of Y.

See http://www.fourcc.org/yuv.php and
https://stackoverflow.com/questions/8561185/yuv-422-yuv-420-yuv-444

The equivalent Julia bits type is given by `Y422BitsType`.

See also: [`bitsperpixel`](@ref), [`equivalentbitstype`](@ref),
          [`ScientificCameras.PixelFormat`](@ref).

"""
struct YUV422 <: ColorFormat{32}; end

struct YUV422BitsType
    U  :: UInt8
    Y0 :: UInt8
    V  :: UInt8
    Y1 :: UInt8
end

# Pixel formats are imported in a separate module and then exported so that it
# is easier to import all pixel formats with:
#
#    using ScientificCameras.PixelFormats

module PixelFormats

import
    ..PixelFormat,
    ..Monochrome,
    ..ColorFormat,
    ..RGB,
    ..RGB24BitsType,
    ..BGR,
    ..BGR24BitsType,
    ..XRGB,
    ..XRGB32BitsType,
    ..XBGR,
    ..XBGR32BitsType,
    ..RGBX,
    ..RGBX32BitsType,
    ..BGRX,
    ..BGRX32BitsType,
    ..BayerFormat,
    ..BayerRGGB,
    ..BayerGRBG,
    ..BayerBGGR,
    ..BayerBGGR,
    ..YUV422,
    ..YUV422BitsType

export
    PixelFormat,
    Monochrome,
    ColorFormat,
    RGB,
    RGB24BitsType,
    BGR,
    BGR24BitsType,
    XRGB,
    XRGB32BitsType,
    XBGR,
    XBGR32BitsType,
    RGBX,
    RGBX32BitsType,
    BGRX,
    BGRX32BitsType,
    BayerFormat,
    BayerRGGB,
    BayerGRBG,
    BayerBGGR,
    BayerBGGR,
    YUV422,
    YUV422BitsType

end # module PixelFormats
