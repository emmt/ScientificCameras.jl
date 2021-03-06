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

    open(cam, ...)

reopens a camera that has been closed.


See also: [`close`](@ref), [`start`](@ref), [`read`](@ref).

"""
open(::Type{C}, args...; kwds...) where {C<:ScientificCamera} =
    notimplemented(:open)

open(::ScientificCamera, args...; kwds...) =
    notimplemented(:open)

"""
    close(cam)

disconnects camera `cam` from the hardware.

See also: [`open`](@ref).

"""
close(cam::ScientificCamera) =
    notimplemented(:close)

"""
    defaulttimeout(cam) -> sec

yields the default timeout (in seconds per image) to acquire images with camera
`cam`.  The returned value is one second plus the exposure time, plus the
time between 2 frames (the reciprocal of the frame rate).

See also: [`read`](@ref), [`getspeed`][@ref).

"""
function defaulttimeout(cam::ScientificCamera)
    fps, exp = getspeed(cam)
    return Cdouble(1 + 1/fps + exp)
end

"""
    read(cam, T=getcapturebitstype(cam)) -> img

reads an image from camera `cam`.  Optional argument `T` is the element type of
the returned image.  If the type is not specified, it is determined
automatically by `getcapturebitstype(cam)`.  The result is a 2D Julia array of
type `Array{T,2}`.

    read(cam, [T=getcapturebitstype(cam),] n) -> imgs

reads `n` images from camera `cam`.  The result is a vector of images:
`imgs[1]` is the first image, `imgs[2]` is the second image and so on.  Each
image is a 2D Julia array, hence `imgs` is of type `Array{Array{T,2},1}`.

When reading an image or a sequence of images, `read` accepts a number of
keywords:

* Use keyword `skip` to specify a number of images to skip.

* Use keyword `timeout` to specify the maximum amount of time (in seconds) to
  wait for the acquisition of each image.  If acquisition of any image takes
  longer than this time, a `ScientificCameras.TimeoutError` is thrown unless
  keyword `truncate` is `true` (see below).  The default timeout depends on the
  exposure time and acquisition frame rate (see [`defaulttimeout`](@ref)).

* When reading a sequence of images, keyword `truncate` may be set `true` to
  print a warning and return a truncated sequence instead of throwing an
  exception in case of timeout.

* Keyword `quiet` can be set `true` to suppress the printing of warning
  messages (see above).

See also: [`open`](@ref), [`start`](@ref), [`equivalentbitstype`](@ref),
          [`defaulttimeout`](@ref), .

"""
read(cam::ScientificCamera; kwds...) =
    read(cam, getcapturebitstype(cam); kwds...)

# Default version (can be extended to improve performances).
function read(cam::ScientificCamera, ::Type{T};
              skip::Integer = 0,
              timeout::Real = defaulttimeout(cam)) where {T}

    # Check arguments.
    skip ≥ 0 || throw(ArgumentError("invalid number of images to skip"))
    timeout > zero(timeout) || error("invalid timeout")

    # Acquire a single image.
    start(cam, T, (skip > zero(skip) ? 2 : 1))
    while true
        try
            img, ticks = wait(cam, timeout)
            if skip > zero(skip)
                # Skip this frame.
                skip -= one(skip)
                release(cam)
            else
                # Stop immediately and return a copy of the image.
                abort(cam)
                return copy(img)
            end
        catch e
            abort(cam)
            rethrow(e)
        end
    end
end

read(cam::ScientificCamera, ::Type{T}, n::Integer; kwds...) where {T} =
    read(cam, T, convert(Int, n); kwds...)

read(cam::ScientificCamera, n::Integer; kwds...) =
    read(cam, getcapturebitstype(cam), convert(Int, n); kwds...)

# Default version (can be extended to improve performances).
function read(cam::ScientificCamera, ::Type{T}, num::Int;
              skip::Integer = 0,
              timeout::Real = defaulttimeout(cam),
              truncate::Bool = false,
              quiet::Bool = false) where {T}

    # Check arguments.
    num ≥ 1 || throw(ArgumentError("invalid number of images"))
    skip ≥ 0 || throw(ArgumentError("invalid number of images to skip"))
    timeout > zero(timeout) || error("invalid timeout")

    # Acquire a sequence of images.
    imgs = Vector{Array{T,2}}(undef, num)
    cnt = 0
    start(cam, T, 3)
    while cnt < num
        try
            img, ticks = wait(cam, timeout)
            if skip > zero(skip)
                skip -= one(skip)
                release(cam)
            else
                cnt += 1
                imgs[cnt] = copy(img)
            end
        catch err
            if truncate && isa(err, TimeoutError)
                quiet || warn("Acquisition timeout after $cnt image(s)")
                num = cnt
                resize!(imgs, num)
            else
                abort(cam)
                rethrow(err)
            end
        end
    end
    abort(cam)
    return imgs
end


"""
    start(cam, [T=getcapturebitstype(cam),] n = 2)

starts continuous acquisition with camera `cam` using `n` image buffers.
Optional argument `T` is the element type of the returned images.  If the type
is not specified, it is determined automatically by `getcapturebitstype(cam)`.
The result is a vector of images, each image is a 2D Julia array.

See also: [`open`](@ref), [`read`](@ref), [`wait`](@ref), [`stop`](@ref),
          [`abort`](@ref).

"""
start(cam::ScientificCamera, ::Type{T}, n::Integer = 2; kwds...) where {T} =
    start(cam, T, convert(Int, n); kwds...)

start(cam::ScientificCamera, n::Integer = 2; kwds...) =
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
    wait(cam, timeout, drop = false) -> img, ticks

waits for the next frame from camera `cam` but not longer than `timeout`
seconds and returns the next image `img` and its timestamp `ticks` (that is the
date of arrival of the captured image in seconds).  If `drop` is `true`,
unprocessed frames are discarded, *i.e.* only the newest frame is returned.  If
the allowed time expires before a new image is available, a
`ScientificCameras.TimeoutError` is thrown.

If properly implemented, waiting for a frame should consume no CPU.

This method is intended for continuous acquisition and real time processing, it
should therefore avoid allocating ressources.  As a result, the images returned
by `wait` are usually part of ressources associated with the camera and
cyclically reused when `release(cam)` is called after processing each image.
This means that the contents of the captured image is overwritten by the next
cycle of even by the next captured image.


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
    getfullwidth(cam)  -> fullwidth
    getfullheight(cam) -> fullheight
    getfullsize(cam)   -> (fullwidth, fullheight)

respectively yield the width, height and dimensions in pixels of the sensor of
the camera `cam`.

See also: [`setroi!`](@ref), [`getroi`](@ref).

"""
getfullwidth(cam::ScientificCamera) = notimplemented(:getfullwidth)
getfullheight(cam::ScientificCamera) = notimplemented(:getfullheight)
getfullsize(cam::ScientificCamera) = (getfullwidth(cam), getfullheight(cam))

@doc @doc(getfullwidth) getfullheight
@doc @doc(getfullwidth) getfullsize

"""

    getroi(cam) -> roi

yields the current region of interest (ROI) for the images acquired by the
camera `cam`.  The result is a structure which has the following fields:

- `xsub`:   Horizontal size of macro-pixels (in pixels).
- `ysub`:   Vertical size of macro-pixels (in pixels).
- `xoff`:   Horizontal offset in pixels of the ROI relative to the sensor.
- `yoff`:   Vertical offset in pixels of the ROI relative to the sensor.
- `width`:  Width in macro-pixels of the ROI.
- `height`: Height in macro-pixels of the ROI.

Depending on the camera model, *macro-pixels* can be larger pixels made of
`xsub` by `yxsub` sensor pixels (binning) or single sensor pixels taken every
`xsub` by `yxsub` sensor pixels (subsampling).

See also: [`setroi!`](@ref), [`resetroi!`](@ref),
          [`ScientificCameras.ROI`](@ref).

"""
getroi(cam::ScientificCamera) = # This version is meant to be extended.
    ROI(1, 1, 0, 0, getfullsize(cam)...)

"""
    setroi!(cam, roi)

sets the region of interest (ROI) to be `roi` for the images acquired by the
camera `cam`: `roi.xsub` and `roi.ysub` are the horizontal and vertical
dimensions of the macro-pixels (in pixels), `roi.xoff` and `roi.yoff` are the
horizontal and vertical offsets of the ROI relative to the sensor (in pixels),
`width` and `height` are the horizontal and vertical dimensions of the ROI (in
macro-pixels).

The region of interest can be specified by 2, 4 or 6 integers:

    setroi!(cam, width, height)
    setroi!(cam, xoff, yoff, width, height)
    setroi!(cam, xsub, ysub, xoff, yoff, width, height)

where unspecified offsets are assumed to be `0` while unspecified binning or
subsampling parameters are assumed to be `1`.

Note that this method throws an exception if the settings of the ROI cannot be
exactly applied.  As a consequence, it does not return the actual ROI because
it can only be identical to the requested one.  Methods `getroi` and
`resetroi!` can be used to query the current ROI or to reset the ROI to use the
full sensor at full resolution.

See also: [`getroi`](@ref), [`checkroi`](@ref), [`resetroi!`](@ref),
          [`ScientificCameras.ROI`](@ref).

"""
setroi!(cam::ScientificCamera, args::Integer...) =
    setroi!(cam, ROI(args...))

# This version is meant to be extended.
setroi!(cam::ScientificCamera, roi::ROI) =
    notimplemented(:setroi!)


"""
    resetroi!(cam)

resets the region of interest (ROI) for the images acquired by the camera `cam`
to use the full sensor at full resolution.

See also: [`getroi`](@ref), [`checkroi`](@ref), [`setroi`](@ref),
          [`ScientificCameras.ROI`](@ref).

"""
resetroi!(cam::ScientificCamera) =
    setroi!(cam, ROI(1, 1, 0, 0, getfullsize(cam)...))

"""
    checkroi(roi, fullwidth, fullheight)

or

    checkroi(roi, (fullwidth, fullheight))

throw an `ArgumentError` exception if the region of interest (ROI) is not valid
for the considered sensor size.  Argument `roi` is an instance of the
`ScientificCameras.ROI` structure, `fullwidth` and `fullheight` are the full
dimensions of the sensor (in pixels).

Instead of provided the full dimensions of the sensor, the camera instance can
be given:

    checkroi(roi, cam)

or

    checkroi(cam, roi)

It is assumed that the `checkroi` method be called by any method extending the
method `setroi!` whose signature is:

   setroi!(cam::Camera, roi::ScientificCameras.ROI)`

where `Camera` is a sub-type of `ScientificCameras.ScientificCamera`.


See also: [`setroi!`](@ref), [`resetroi!`](@ref),
          [`ScientificCameras.ROI`](@ref), [`getfullsize`](@ref).

"""
function checkroi(roi::ROI, fullwidth::Int, fullheight::Int)
    if fullwidth < 1
        throw(ArgumentError("full width is too small ($fullwidth)"))
    end
    if fullheight < 1
        throw(ArgumentError("full height is too small ($fullheight)"))
    end
    if roi.xsub < 1
        throw(ArgumentError("horizontal decimation is too small ($(roi.xsub))"))
    end
    if roi.xsub > fullwidth
        throw(ArgumentError("horizontal decimation is too large ($(roi.xsub))"))
    end
    if roi.ysub < 1
        throw(ArgumentError("vertical decimation is too small ($(roi.ysub))"))
    end
    if roi.ysub > fullheight
        throw(ArgumentError("vertical decimation is too large ($(roi.ysub))"))
    end
    if roi.xoff < 0
        throw(ArgumentError("horizontal offset is too small ($(roi.xoff))"))
    end
    if roi.yoff <0
        throw(ArgumentError("vertical offset is too small ($(roi.yoff))"))
    end
    if roi.width < 1
        throw(ArgumentError("width of $(roi.width) macro-pixels is too small"))
    end
    width = roi.width*roi.xsub # width in pixels
    if width > fullwidth
        throw(ArgumentError("width of $(width) pixels is too large"))
    end
    if roi.height < 1
        throw(ArgumentError("height of $(roi.height) macro-pixels is too small"))
    end
    height = roi.height*roi.xsub # height in pixels
    if height > fullheight
        throw(ArgumentError("height of $(height) pixels is too large"))
    end
    xmax = roi.xoff + width
    if xmax > fullwidth
        throw(ArgumentError("right bound at $(xmax) pixels is too large"))
    end
    ymax = roi.yoff + roi.height*roi.ysub
    if ymax > fullheight
        throw(ArgumentError("top boundary at $(ymax) is too large"))
    end
    nothing
end

checkroi(roi::ROI, fullwidth::Integer, fullheight::Integer) =
    checkroi(roi, convert(Int, fullwidth), convert(Int, fullheight))

checkroi(roi::ROI, fullsize::NTuple{2,Integer}) =
    checkroi(roi, fullsize...)

checkroi(roi::ROI, cam::ScientificCamera; kdws...) =
    checkroi(roi, getfullsize(cam; kdws...))

checkroi(cam::ScientificCamera, roi::ROI; kwds...) =
    checkroi(roi, getfullsize(cam; kdws...))

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
format.  `Nothing` is returned when there is no known exact equivalence.

See also: [`bitsperpixel`](@ref), [`ScientificCameras.PixelFormat`](@ref).

"""
equivalentbitstype(::Type{T}) where {T <: PixelFormat} = Nothing
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
or by the captured image buffers if second argument is true.

See also: [`setpixelformat!`](@ref), [`ScientificCameras.PixelFormat`](@ref).

"""
supportedpixelformats(cam::ScientificCamera, buf::Bool) = Union{}

supportedpixelformats(cam::ScientificCamera) =
    supportedpixelformats(cam, false)


"""
    getpixelformat(cam) -> fmt

yields the current pixel format of the camera `cam`.

See also: [`setpixelformat!`](@ref), [`supportedpixelformats`](@ref),
          [`ScientificCameras.PixelFormat`](@ref).

"""
getpixelformat(cam::ScientificCamera) =
    notimplemented(:getpixelformat)

"""
    setpixelformat!(cam, fmt)

sets the pixel format for the camera `cam`.  The requested pixel format can be
*vague* in the sense that it may only a super-class like
`ScientificCameras.Color{N}` to request a colored pixel format encoded on `N`
bits per pixel, the number of bits may even be not specified.  Use
`getpixelformat(cam)` to figure out actual concrete format.

See also: [`getpixelformat`](@ref), [`supportedpixelformats`](@ref),
          [`getcapturebitstype`](@ref),
          [`ScientificCameras.PixelFormat`](@ref).

"""
setpixelformat!(cam::ScientificCamera, ::Type{C}) where {C <: PixelFormat} =
    notimplemented(:setpixelformat!)

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
    return (T == Nothing ? UInt8 : T)
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
