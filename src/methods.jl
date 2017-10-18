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
of the returned images.  If the type is not specified, it is determined
automatically by `getcapturebitstype(cam)`.  The result is a vector of images:
`imgs[1]` is the first image, `imgs[2]` is the second image and so on.  Each
image is a 2D Julia array.  For instance, the type of `imgs` is
`Array{Array{T,2},1}`.

See also: [`open`](@ref), [`start`](@ref), [`equivalentbitstype`](@ref).

"""
read(cam::ScientificCamera, ::Type{T}, n::Integer = 1; kwds...) where {T} =
    read(cam, T, convert(Int, n); kwds...)

read(cam::ScientificCamera, n::Integer = 1; kwds...) =
    read(cam, getcapturebitstype(cam), convert(Int, n); kwds...)

# This version is meant to be extended.
read(cam::ScientificCamera, ::Type{T}, n::Int; kwds...) where {T} =
    notimplemented(:read)

"""
    start(cam, [T,] n = 1) -> imgs

starts continuous acquisition with camera `cam` using `n` image buffers which
are returned.  Optional argument `T` is the element type of the returned
images.  If the type is not specified, it is determined automatically by
`getcapturebitstype(cam)`.  The result is a vector of images, each image is a
2D Julia array.

See also: [`open`](@ref), [`read`](@ref), [`wait`](@ref), [`stop`](@ref),
          [`abort`](@ref).

"""
start(cam::ScientificCamera, ::Type{T}, n::Integer = 1; kwds...) where {T} =
    start(cam, T, convert(Int, n); kwds...)

start(cam::ScientificCamera, n::Integer = 1; kwds...) =
    start(cam, getcapturebitstype(cam), convert(Int, n); kwds...)

# This version is meant to be extended.
start(cam::ScientificCamera, ::Type{T}, n::Int; kwds...) where {T} =
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
    wait(cam, timeout, drop = false) -> index

waits for the next frame from camera `cam` but not longer than `timeout`
seconds and returns the index of the next frame in the image buffers or `0` if
timeout occured.  If `drop` is `true`, unprocessed frames are discarded, *i.e.*
only the newest frame is returned.

If properly implemented, waiting for a frame should consume no CPU.

See also: [`start`](@ref), [`release`](@ref).

"""
wait(cam::ScientificCamera, timeout, drop::Bool = false) =
    wait(cam, convert(Float64, timeout), drop)

# This version is meant to be extended.
wait(cam::ScientificCamera, timeout::Float64, drop::Bool) =
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
captured by the camera `cam` and assuming no subsampling.

See also: [`setroi!`](@ref), [`getdecimation`](@ref).

"""
getfullwidth(cam::ScientificCamera) = notimplemented(:getfullwidth)
getfullheight(cam::ScientificCamera) = notimplemented(:getfullheight)
getfullsize(cam::ScientificCamera) = (getfullwidth(cam), getfullheight(cam))

@doc @doc(getfullwidth) getfullheight
@doc @doc(getfullwidth) getfullsize

"""
    getdecimation(cam) -> (xsub, ysub)

yields the actual decimation factors (in pixels along each dimension) for
camera `cam`.  Note that the maximum image size is `div(fullwidth,xsub)` by
`div(fullheight,ysub)` where `fullwidth` and `fullheight` are the dimensions
returned by `getfullsize(cam)`.

See also: [`setdecimation!`](@ref), [`getfullsize`](@ref), [`getroi`](@ref).

"""
getdecimation(cam::ScientificCamera) = notimplemented(:getdecimation)

"""
    setdecimation!(cam, xsub, ysub)

Sets the decimation factors (in pixels along each dimension) for camera `cam`.
Note that the maximum image size will be `div(fullwidth,xsub)` by
`div(fullheight,ysub)` where `fullwidth` and `fullheight` are the dimensions
returned by `getfullsize(cam)`.

See also: [`getdecimation`](@ref), [`getfullsize`](@ref), [`getroi`](@ref).

"""
setdecimation!(cam::ScientificCamera, xsub, ysub) =
    setdecimation!(cam, convert(Int, xsub), convert(Int, ysub))

# This version is meant to be extended.
setdecimation!(cam::ScientificCamera, xsub::Int, ysub::Int) =
    notimplemented(:setdecimation!)

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
    bitsperpixel(fmt)

yields the number of bits per pixel of a given pixel format.  If `fmt` does not
specify the number of bits per pixel, 0 is returned.  This method can also be
applied to a camera, say `cam`, to get the current number of bits per pixel:

    bitsperpixel(cam)

See also: [`equivalentbitstype`](@ref), [`ScientificCameras.PixelFormat`](@ref).

"""
bitsperpixel(::T) where {T <: PixelFormat} = bitsperpixel(T)
bitsperpixel(::Type{T}) where {T<:PixelFormat} = 0
bitsperpixel(::Type{T}) where {T<:PixelFormat{N}} where {N} = N
bitsperpixel(cam::ScientificCamera) = bitsperpixel(getpixelformat(cam))

"""
    equivalentbitstype(format) -> T

yields the closest equivalent bits type `T` corresponding to a given pixel
format.  `Void` is returned when there is no known exact equivalence.

See also: [`bitsperpixel`](@ref), [`ScientificCameras.PixelFormat`](@ref).

"""
equivalentbitstype(::Type{T}) where {T <: PixelFormat} = Void
equivalentbitstype(::T) where {T <: PixelFormat} = equivalentbitstype(T)
equivalentbitstype(::Type{Monochrome{8}}) = UInt8
equivalentbitstype(::Type{Monochrome{16}}) = UInt16
equivalentbitstype(::Type{Monochrome{32}}) = UInt32
equivalentbitstype(::Type{BayerFormat{8}}) = UInt8
equivalentbitstype(::Type{BayerFormat{16}}) = UInt16
equivalentbitstype(::Type{BayerFormat{32}}) = UInt32
equivalentbitstype(::Type{YUV422}) = YUV422BitsType
equivalentbitstype(::Type{RGB{24}}) = RGB24BitsType
equivalentbitstype(::Type{BGR{24}}) = BGR24BitsType
equivalentbitstype(::Type{XRGB{32}}) = XRGB32BitsType
equivalentbitstype(::Type{XBGR{32}}) = XBGR32BitsType
equivalentbitstype(::Type{RGBX{32}}) = RGBX32BitsType
equivalentbitstype(::Type{BGRX{32}}) = BGRX32BitsType

"""
    supportedpixelformats(cam, buf = false) -> formats

yields an `Union` of the *concrete* pixel formats supported by the camera `cam`
or by the capture image buffers if second argument is true.

See also: [`setpixelformat!`](@ref), [`ScientificCameras.PixelFormat`](@ref).

"""
supportedpixelformats(cam::ScientificCamera, buf::Bool) = Union{}

supportedpixelformats(cam::ScientificCamera) =
    supportedpixelformats(cam, false)


"""
    getpixelformat(cam) -> (campix, bufpix)

yields the current pixel formats for the camera `cam` and for the image
buffers.

See also: [`setpixelformat!`](@ref), [`supportedpixelformats`](@ref),
          [`ScientificCameras.PixelFormat`](@ref).

"""
getpixelformat(cam::ScientificCamera) =
    notimplemented(:getpixelformat)

"""
    setpixelformat!(cam, campix [, bufpix])

sets the pixel formats for the camera `cam` and, possibly, for captured image
buffers.  The requested pixel formats can be *vague* in the sense that it is
only a super-class like `ScientificCameras.Color{N}` to request a colored pixel
format encoded on `N` bits per pixel, the number of bits may even be not
specified.  If not specified, the pixel format of captured image buffers is
derived from the camera pixel format.  Use `getpixelformat(cam)` to figure out
actual concrete formats.

See also: [`getpixelformat`](@ref), [`supportedpixelformats`](@ref),
          [`getcapturebitstype`](@ref),
          [`ScientificCameras.PixelFormat`](@ref).

"""
setpixelformat!(cam::ScientificCamera, ::Type{C}) where {C <: PixelFormat} =
    notimplemented(:setpixelformat!)

function setpixelformat!(cam::ScientificCamera,
                         ::Type{C}, ::Type{B}) where {C <: PixelFormat,
                                                      B <: PixelFormat}
    notimplemented(:setpixelformat!)
end

"""
    getcapturebitstype(cam) -> T

yields the bits type which is used by default to capture images with camera
`cam`.

See also: [`getpixelformat`](@ref), [`setpixelformat!`](@ref),
          [`equivalentbitstype`](@ref).


"""
function getcapturebitstype(cam::ScientificCamera)
    # Default implementation.
    bufpix = getpixelformat(cam)[2]
    T = equivalentbitstype(bufpix)
    return (T == Void ? UInt8 : T)
end

"""
    getspeed(cam) -> (fps, exp)

yields the number of frames per second and exposure duration (in seconds) for
the camera `cam`.

See also: [`setspeed!`](@ref).

"""
getspeed(cam::ScientificCamera; kwds...) = notimplemented(:getspeed)

"""
    setspeed!(cam, fps, exp)

sets the number of frames per second and exposure duration (in seconds) for the
camera `cam`.

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
    setgain!(cam, gain)

sets the gain of the analog to digital conversion of pixel values for the
camera `cam`.

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
    setbias!(cam, bias)

sets the bias of the analog to digital conversion of pixel values for the
camera `cam`.

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
    setgamma!(cam, gamma)

sets the gamma correction factor of the analog to digital conversion of pixel
values by the camera `cam`.

See also: [`getgamma`](@ref).

"""
setgamma!(cam::ScientificCamera, gamma; kwds...) =
    setgamma!(cam, convert(Float64, gamma); kwds...)

# This version is meant to be extended.
setgamma!(cam::ScientificCamera, gamma::Float64; kwds...) =
    notimplemented(:setgamma!)
