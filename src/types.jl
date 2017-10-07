#
# types.jl -
#
# Type definitions for Julia interface to scientific cameras.
#
#------------------------------------------------------------------------------
#
# This file is part of the `Phoenix.jl` package which is licensed under the MIT
# "Expat" License.
#
# Copyright (C) 2016, Éric Thiébaut & Jonathan Léger.
# Copyright (C) 2017, Éric Thiébaut.
#

"""

Concrete types derived from abstract type `ScientificCamera` are used to
uniquely identify the different camera models or different combinations of
camera and frame grabber.

"""
abstract type ScientificCamera end

"""

`Phoenix.Configuration` is a structure to store acquisition parameters.

For now, each acquisition buffer stores a single image (of size `roi_width` by
`roi_height` pixels).  All acquisition buffers have `buf_stride` bytes per line
and a number of lines greater of equal the height of the images.

The following fields are available:

- `roi_width`:  Width of ROI (in pixels, integer).
- `roi_height`: Height of ROI (in pixels, integer).
- `cam_depth`:  Bits per pixel of the camera (integer).
- `cam_xoff`:   Horizontal offset of ROI relative to detector (in pixels, integer).
- `cam_yoff`:   Vertical offset of ROI relative to detector (in pixels, integer).
- `buf_number`  Number of acquisition buffers (integer).
- `buf_xoff`:   Horizontal offset of ROI relative to buffer (in pixels, integer).
- `buf_yoff`:   Vertical offset of ROI relative to buffer (in pixels, integer).
- `buf_stride`: Bytes per line of an acquisition buffer (integer).
- `buf_height`: Number of lines in an acquisition buffer (integer).
- `buf_format`: Pixel format, *e.g.*, `PHX_DST_FORMAT_Y8` (integer).
- `fps`:        Acquisition frame rate (in Hz, real).
- `exposure`:   Exposure time (in seconds, real).
- `gain`:       Analog gain (real).
- `bias`:       Analog bias or black level (real).
- `gamma`:      Gamma correction (real).
- `blocking`:   Acquisition is blocking? (boolean)
- `continuous`: Acquisition is continuous? (boolean)

Note: *integer* and *real* means that field has respectively integer (`Int`)
and floating-point (`Float64`) value.

See also: [`setconfig!`](@ref), [`getconfig!`](@ref), [`fixconfig!`](@ref).

"""
struct ROI
    xoff::Int
    yoff::Int
    width::Int
    height::Int
    #cam_depth::Int
    #buf_number::Int
    #buf_xoff::Int
    #buf_yoff::Int
    #buf_stride::Int
    #buf_height::Int
    #buf_format::Int
    #fps::Float64
    #exposure::Float64
    #gain::Float64
    #bias::Float64
    #gamma::Float64
    #blocking::Bool
    #continuous::Bool
    ROI(xoff::Integer, yoff::Integer, width::Integer, height::Integer) =
        new(xoff, yoff, width, height)
    ROI(width::Integer, height::Integer) =
        new(0, 0, width, height)
    ROI() =
        new(0, 0, typemax(Int), typemax(Int))
end

# Custom exception to report errors for non-extended methods.
struct NotImplementedException <: Exception
   sym::Symbol
end

# Colors (FIXME: use Julia package ColorTypes at https://github.com/JuliaGraphics/ColorTypes.jl)

struct RGB{T}
    r::T
    g::T
    b::T
end
const RGB24 = RGB{UInt8}
const RGB48 = RGB{UInt16}
