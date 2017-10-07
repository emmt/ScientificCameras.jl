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

- `xoff`:   Horizontal offset of the ROI relative to detector.
- `yoff`:   Vertical offset of the ROI relative to detector.
- `width`:  Width of the ROI.
- `height`: Height of the ROI.

All fields are integer valued (of type `Int`) and given in pixels.  A ROI is
constructed by:

    ROI(xoff, yoff, width, height)

or

    ROI(width, height)

which assumes zero offsets.  Note that for efficiency reasons, there is no
testing of the validity of the settings but you may use `checkroi` for that.

See also: [`getroi`](@ref), [`setroi!`](@ref), [`checkroi`](@ref).

"""
struct ROI
    xoff::Int
    yoff::Int
    width::Int
    height::Int
    ROI(xoff::Integer, yoff::Integer, width::Integer, height::Integer) =
        new(xoff, yoff, width, height)
    ROI(width::Integer, height::Integer) =
        new(0, 0, width, height)
end

# Custom exception to report errors for non-extended methods.
struct NotImplementedException <: Exception
   sym::Symbol
end

# Color types (note that the constructors always use red, green, blue order
# whatever is the order in memory).
#
# (FIXME: use Julia package ColorTypes at https://github.com/JuliaGraphics/ColorTypes.jl)
struct RGB{T}
    r::T
    g::T
    b::T
    RGB{T}(r, g, b) where {T} = new{T}(r, g, b)
end
struct BGR{T}
    b::T
    g::T
    r::T
    BGR{T}(r, g, b) where {T} = new{T}(b, g, r)
end
const RGB24 = RGB{UInt8}
const RGB48 = RGB{UInt16}
const BGR24 = BGR{UInt8}
const BGR48 = BGR{UInt16}
