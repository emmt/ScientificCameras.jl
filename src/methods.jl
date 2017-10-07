#
# methods.jl --
#
# Methods for scientific cameras.  Most of these are unspecialized and are
# meant to be extended for specific camera models.
#
#------------------------------------------------------------------------------
#
# This file is part of the `ScientificCameras.jl` package which is licensed
# under the MIT "Expat" License.
#
# Copyright (C) 2017, Éric Thiébaut.
#

notimplemented(sym::Symbol) = throw(NotImplementedException(sym))

Base.showerror(io::IO, err::NotImplementedException) =
    print(io, "method `$(err.sym)` not implemented for this camera")

"""
    open(C, ...) -> cam

creates a camera instance of type `C`, connects it to the hardware
and returns it.

See also: [`close`](@ref), [`start`](@ref), [`read`](@ref).

"""
open(::Type{C}, args...; kwds...) where {C<:ScientificCamera} =
    notimplemented(:open)

"""
    close(cam)

disconnects camera `cam` from the hardware.

See also: [`open`](@ref).

"""
close(cam::ScientificCamera) =
    notimplemented(:close)

"""
    read(cam, [T,] n = 1) -> imgs

reads `n` images from camera `cam`.  Optional argument `T` is the element type
of the returned images.  If the type is not specified, it may be determined
automatically (not all interfaces can do that and not all interfaces can cope
with arbitrary pixel types).  The result is a vector of images: `imgs[1]` is
the first image, `imgs[2]` is the second image and so on.  Each image is a 2D
Julia array.  For instance, the type of `imgs` is `Array{Array{T,2},1}`.

See also: [`open`](@ref), [`start`](@ref).

"""
read(cam::ScientificCamera, ::Type{T}, n::Integer) where {T} =
    read(cam, T, convert(Int, n))

read(cam::ScientificCamera, n::Integer) =
    read(cam, convert(Int, n))

# This version is meant to be extended.
read(cam::ScientificCamera, ::Type{T}, n::Int = 1) where {T} =
    notimplemented(:read)

# This version is meant to be extended.
read(cam::ScientificCamera, n::Int = 1) =
    notimplemented(:read)

"""
    start(cam, [T,] n = 1) -> imgs

starts continuous acquisition with camera `cam` using `n` image buffers which
are returned.  Optional argument `T` is the element type of the returned
images.  The result is a vector of images, each image is a 2D Julia array.

See also: [`open`](@ref), [`read`](@ref), [`wait`](@ref), [`stop`](@ref),
          [`abort`](@ref).

"""
start(cam::ScientificCamera, ::Type{T}, n::Integer) where {T} =
    start(cam, T, convert(Int, n))

start(cam::ScientificCamera, n::Integer) =
    start(cam, convert(Int, n))

# This version is meant to be extended.
start(cam::ScientificCamera, ::Type{T}, n::Int = 1) where {T} =
    notimplemented(:start)

# This version is meant to be extended.
start(cam::ScientificCamera, n::Int = 1) =
    notimplemented(:start)

"""
    stop(cam)

stops continuous acquisition with camera `cam` after completion of the current
frame.

See also: [`start`](@ref), [`abort`](@ref).

"""
stop(cam::ScientificCamera) =
    notimplemented(:stop)

"""
    abort(cam)

aborts continuous acquisition with camera `cam` not waiting for the completion
of the current frame.

See also: [`start`](@ref), [`stop`](@ref).

"""
abort(cam::ScientificCamera) =
    notimplemented(:stop)

"""
    wait(cam [, timeout]) -> index, number, overflows

waits for the next frame (but not longer than `timeout` seconds if specified)
from camera `cam` and returns the index in the image buffers, the frame number
and the number of overflows (or acquisition errors) so far.

If properly implemented, waiting for a frame should consume no CPU.

See also: [`start`](@ref), [`release`](@ref).

"""
wait(cam::ScientificCamera, timeout) =
    wait(cam, convert(Float64, timeout))

# This version is meant to be extended.
wait(cam::ScientificCamera, timeout::Float64 = typemax(Float64)) =
    notimplemented(:wait)

"""
    release(cam)

releases the last frame received from camera `cam` to indicate that it has been
processed and can be used again for acquisition.

See also: [`start`](@ref), [`wait`](@ref).

"""
release(cam::ScientificCamera) =
    notimplemented(:wait)

"""
    setroi!(cam, xoff, yoff, width, height)

sets the region of interest (ROI) for the images acquired by the camera `cam`:
`xoff` and `yoff` are the horizontal and vertical offsets of the ROI relative
to the sensor (in pixels), `width` and `height` are the horizontal and vertical
dimensions of the ROI (also in pixels).

An alternative is:

    setroi!(cam, roi)

where the ROI is specified by an instance of the `ScientificCameras.ROI`
structure.

Note that this method throws an exception if the settings of the ROI cannot be
axactly applied.  As a consequence, it does not return the actual ROI because
it can only be identical to the requested one.

See also: [`getroi`](@ref), [`checkroi`](@ref),
          [`ScientificCameras.ROI`](@ref).

"""
function setroi!(cam::ScientificCamera, xoff::Integer, yoff::Integer,
                 width::Integer, height::Integer; kwds...)
    setroi!(cam, ROI(xoff, yoff, width, height); kwds...)
end

# This version is meant to be extended.
setroi!(cam::ScientificCamera, roi::ROI; kwds...) =
    notimplemented(:setroi!)

"""

    getroi(cam) -> (xoff, yoff, width, height)

yields the current region of interest (ROI) for the images acquired by the
camera `cam`.  The result is a tuple of 4 values: `xoff` and `yoff` are the
horizontal and vertical offsets of the ROI relative to the sensor, `width` and
`height` are the horizontal and vertical dimensions of the ROI (all values in
pixels and of type `Int`).

An alternative is:

    getroi(ROI, cam) -> ROI(xoff, yoff, width, height)

which yields the ROI as an instance of the `ScientificCameras.ROI` structure.

See also: [`setroi!`](@ref), [`ScientificCameras.ROI`](@ref).

"""
getroi(::Type{ROI}, cam::ScientificCamera; kwds...) =
    ROI(getroi(cam; kwds...)...)

# This version is meant to be extended.
getroi(cam::ScientificCamera; kwds...) =
    notimplemented(:getroi)

"""
    getfullwidth(cam)  -> fullwidth
    getfullheight(cam) -> fullheight
    getfullsize(cam)   -> (fullwidth, fullheight)

respectively yield the maximum width, height and dimensions for the images
captured by the camera `cam`.

See also: [`setroi!`](@ref).

"""
getfullwidth(cam::ScientificCamera) = notimplemented(:getfullwidth)
getfullheight(cam::ScientificCamera) = notimplemented(:getfullheight)
getfullsize(cam::ScientificCamera) = (getfullwidth(cam), getfullheight(cam))

@doc @doc(getfullwidth) getfullheight
@doc @doc(getfullwidth) getfullsize

"""

    checkroi(xoff, yoff, width, height, fullwidth, fullheight)

throws an `ArgumentError` exception if the region of interest (ROI) is not
valid for the considered sensor size.  Arguments `xoff` and `yoff` are the
horizontal and vertical offsets of the ROI relative to the sensor,
`width` and `height` are the horizontal and vertical dimensions of the ROI,
`fullwidth` and `fullheight` are the full dimensions of the sensor (all
arguments in pixels).

There are many alternatives, for instance:

    checkroi(roi, fullwidth, fullheight)
    checkroi(roi, fullsize)
    checkroi(roi, cam)
    checkroi(cam, roi)
    checkroi(cam, xoff, yoff, width, height)

where `roi` is an instance of the `ScientificCameras.ROI` structure, `cam` is a
camera instance, `fullsize = (fullwidth, fullheight)`.  Note that `cam` is used
to query the full size of the camera as:

   getfullsize(cam; kwds...)

with `kwds...` any keywords specified with `checkroi`.

It is assumed that the `checkroi` method be called by any method extending the
method `setroi!` whose signature is:

   setroi!(cam::Camera, roi::ScientificCameras.ROI)`

where `Camera` is a sub-type of `ScientificCameras.ScientificCamera`.


See also: [`setroi!`](@ref), [`ScientificCameras.ROI`](@ref),
          [`getfullsize`](@ref).

"""
function checkroi(xoff::Int, yoff::Int, width::Int, height::Int,
                  fullwidth::Int, fullheight::Int)
    if fullwidth < 1
        throw(ArgumentError("full width is too small ($fullwidth)"))
    end
    if fullheight < 1
        throw(ArgumentError("full height is too small ($fullheight)"))
    end
    if xoff < 0
        throw(ArgumentError("horizontal offset is too small ($xoff)"))
    end
    if yoff <0
        throw(ArgumentError("vertical offset is too small ($yoff)"))
    end
    if width < 1
        throw(ArgumentError("width is too small ($width)"))
    end
    if height < 1
        throw(ArgumentError("height is too small ($height)"))
    end
    if xoff + width > fullwidth
        throw(ArgumentError("horizontal offset or width are too large ($(xoff + width))"))
    end
    if yoff + height > fullheight
        throw(ArgumentError("vertical offset or height are too large ($(yoff + height))"))
    end
    nothing
end

function checkroi(xoff::Integer, yoff::Integer, width::Integer, height::Integer,
                  fullwidth::Integer, fullheight::Integer)
    checkroi(convert(Int, xoff), convert(Int, yoff),
             convert(Int, width), convert(Int, height),
             convert(Int, fullwidth), convert(Int, fullheight))
end

checkroi(roi::ROI, fullwidth::Integer, fullheight::Integer) =
    checkroi(roi.xoff, roi.yoff, roi.width, roi.height, fullwidth, fullheight)

checkroi(roi::ROI, fullsize::NTuple{2,Integer}) =
    checkroi(roi, fullsize...)

checkroi(roi::ROI, cam::ScientificCamera; kdws...) =
    checkroi(roi, getfullsize(cam; kdws...))

checkroi(cam::ScientificCamera, args...; kwds...) =
    checkroi(args..., getfullsize(cam; kdws...))

"""
    getdepth(cam) -> depth

yields the number of bits per pixel for the camera `cam`.

See also: [`setdepth!`](@ref).

"""
getdepth(cam::ScientificCamera; kwds...) =
    notimplemented(:getdepth)

"""
    setdepth!(cam, depth) -> depth

sets the number of bits per pixel for the camera `cam`.  The actual value is
returned (as an `Int`).

See also: [`getdepth`](@ref).

"""
setdepth!(cam::ScientificCamera, depth; kwds...) =
    setdepth!(cam, convert(Int, depth); kwds...)

# This version is meant to be extended.
setdepth!(cam::ScientificCamera, depth::Int; kwds...) =
    notimplemented(:setdepth!)

"""
    getspeed(cam) -> (fps, exp)

yields the number of frames per second and exposure duration (in seconds) for
the camera `cam`.

See also: [`setspeed!`](@ref).

"""
getspeed(cam::ScientificCamera; kwds...) = notimplemented(:getspeed)

"""
    setspeed!(cam, fps, exp) -> (fps, exp)

sets the number of frames per second and exposure duration (in seconds) for the
camera `cam`.  The actual values are returned (as a tuple of two `Float64`).

See also: [`getspeed`](@ref), [`checkspeed`](@ref).

"""
setspeed!(cam::ScientificCamera, fps, exp; kwds...) =
    setspeed!(cam, convert(Float64, fps), convert(Float64, exp); kwds...)

# This version is meant to be extended.
setspeed!(cam::ScientificCamera, fps::Float64, exp::Float64; kwds...) =
    notimplemented(:setspeed!)

"""
    checkspeed(cam, fps, exp)

throws an exception if the number of frames per second `fps` and/or exposure
duration `exp` (in seconds) are not valid for the camera `cam`.

See also: [`setspeed!`](@ref).

"""
checkspeed(cam::ScientificCamera, fps, exp; kwds...) =
    checkspeed(cam, convert(Float64, fps), convert(Float64, exp); kwds...)

# Default implementation.
function checkspeed(cam::ScientificCamera, fps::Float64, exp::Float64)
    if !isfinite(fps) || fps ≤ 0.0
        throw(ArgumentError("invalid frame rate ($fps Hz)"))
    end
    if !isfinite(exp) || exp ≤ 0.0
        throw(ArgumentError("invalid exposure time ($exp s)"))
    end
    if fps*exp ≥ 1.0
        throw(ArgumentError("frame rate times exposure time is too high"))
    end
end

"""
    getgain(cam) -> gain

yields the gain of the analog to digital conversion of pixel values for the
camera `cam`.  The retuned value is a `Float64`.

See also: [`setgain!`](@ref).

"""
getgain(cam::ScientificCamera; kwds...) =
    notimplemented(:getgain)

"""
    setgain!(cam, gain) -> gain

sets the gain of the analog to digital conversion of pixel values for the
camera `cam`.  The actual value is returned (as a `Float64`).

See also: [`getgain`](@ref), [`setbias!`](@ref), [`setgamma!`](@ref).

"""
setgain!(cam::ScientificCamera, gain; kwds...) =
    setgain!(cam, convert(Float64, gain); kwds...)

# This version is meant to be extended.
setgain!(cam::ScientificCamera, gain::Float64; kwds...) =
    notimplemented(:setgain!)

"""
    getbias(cam) -> bias

yields the bias of the analog to digital conversion of pixel values for the
camera `cam`.  The retuned value is a `Float64`.

See also: [`setbias!`](@ref).

"""
getbias(cam::ScientificCamera; kwds...) =
    notimplemented(:getbias)

"""
    setbias!(cam, bias) -> bias

sets the bias of the analog to digital conversion of pixel values for the
camera `cam`.  The actual value is returned (as a `Float64`).

See also: [`getbias`](@ref).

"""
setbias!(cam::ScientificCamera, bias; kwds...) =
    setbias!(cam, convert(Float64, bias); kwds...)

# This version is meant to be extended.
setbias!(cam::ScientificCamera, bias::Float64; kwds...) =
    notimplemented(:setbias!)

"""
    getgamma(cam) -> gamma

yields the gamma correction factor of the analog to digital conversion of pixel
values for the camera `cam`.  The returned value is a `Float64`.

See also: [`setgamma!`](@ref), [`getbias`](@ref), [`getgain`](@ref).

"""
getgamma(cam::ScientificCamera; kwds...) =
    notimplemented(:getgamma)

"""
    setgamma!(cam, gamma) -> gamma

sets the gamma correction factor of the analog to digital conversion of pixel
values by the camera `cam`.  The actual value is returned (as a `Float64`).

See also: [`getgamma`](@ref).

"""
setgamma!(cam::ScientificCamera, gamma; kwds...) =
    setgamma!(cam, convert(Float64, gamma); kwds...)

# This version is meant to be extended.
setgamma!(cam::ScientificCamera, gamma::Float64; kwds...) =
    notimplemented(:setgamma!)
