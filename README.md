# A Julia infrastructure for scientific cameras

The `ScientificCameras` package provides an infrastructure to interface
scientific cameras with [`Julia`](http://julialang.org/).  This infrastructure
is an attempt to unify the use of interfaced cameras in Julia and is used by
[`Phoenix.jl`](https://github.com/emmt/Phoenix.jl) and
[`AndorCameras.jl`](https://github.com/emmt/AndorCameras.jl) packages.


## Table of contents

* [Typical usage (for end-users).](#typical-usage)
* [Implementing a concrete interface (for developers).](#implementing-a-concrete-interface)
* [Installation of the package.](#installation)


## Typical usage

To explain the usage of the methods provided by `ScientificCameras`, it is best
to present typical examples of the different stages involved in acquisition of
images with a camera.


### Connection and configuration

You must first import the methods from the general module (with pixel formats)
and a specific camera model, say `SomeCameraModel`, from a specific frame
grabber module, say `SomeFrameGrabber`:

```julia
using ScientificCameras                  # import all methods of main module
using ScientificCameras.PixelFormats     # import all pixel formats
import SomeFrameGrabber: SomeCameraModel # import a specific camera model
```

Second, you create an instance of the camera and connect it to the hardware by:

```julia
cam = open(SomeCameraModel)
```

Third, you configure the camera:

```julia
resetroi!(cam) # use full sensor area and no sub-sampling
fullwidth, fullheight = getfullsize(cam) # get the full sensor size
setspeed!(cam, 100, 0.005) # 100 frames per second, 5ms of exposure
setgain!(cam, 1.0) # set the gain of the analog to digital conversion
setbias!(cam, 0.0) # set the bias of the analog to digital conversion
setgamma!(cam, 1.0) # set the gamma correction of the analog to digital conversion
setpixelformat!(cam, Monochrome{8}) # set the pixel format to monochrome 8 bits
```

Note that you may choose different settings (for instance, a smaller ROI) and
that not all these settings may be available for the considered camera.  To
figure out the current settings, you can use `get*` methods.  For instance,
`getspeed(cam)` yields the current number of frames per second and exposure
time.  In general, the `set*!(cam, ...)` methods may be only able to
approximately set the requested value(s) (*e.g.* because of rounding, of
hardware limitations, *etc.*), it is therefore a good practice to check actual
values by calling the corresponding `get*(cam)` methods.  However, when a given
setting is not implemented or when the settings are grossly wrong, the
`set*!(cam, ...)` methods shall throw a specific exception such as
`ScientificCameras.NotImplementedException` for unimplemented features (so that
you can specifically catch it).


### Region of interest

The region of interest (ROI) is defined by 6 values:

- `xsub`, `ysub` the horizontal and vertical dimensions of the macro-pixels
  in pixels;

- `xoff`, `yoff` the horizontal and vertical offsets of the ROI in pixels
  relative to the sensor area;

- `width` and `height` the horizontal and vertical dimensions of the ROI in
  macro-pixels.

Depending on the camera model, *macro-pixels* can be larger pixels made of
`xsub` by `yxsub` sensor pixels (known as *binning*) or single sensor pixels
taken every `xsub` by `yxsub` sensor pixels (known as *subsampling*).  Some
hardware may impose restrictions such as `xoff` and `yoff` being multiple of
`xsub` and `yxsub` respectively.  These kind of restrictions cannot be
compensated by the software.

In the following example, we first get the current ROI settings, then modify it
to have no subsampling/rebinning and a centered ROI of half the sensor
dimensions and finally apply it:

```julia
roi = getroi(cam) # retrieve current ROI
roi.xsub = 1
roi.ysub = 1
roi.xoff = div(getfullwidth(cam),4)
roi.yoff = div(getfullheight(cam),4)
roi.width = div(getfullwidth(cam),2)
roi.height = div(getfullheight(cam),2)
setroi!(cam, roi) # apply the new settings
```

The same result is obtained with:

```julia
fullwidth, fullheight = getfullsize(cam)
setroi!(cam, 1, 1, div(fullwidth(cam),4), div(fullheight,4),
        div(fullwidth(cam),4), div(fullheight,4))
```


### Reading a given number of images

Assuming you have a connected and configured camera instance, say `cam`, it is
time to read images.  Reading a given number of images amounts to calling
`read`.  For instance, to read a single image:

```julia
img = read(cam, UInt8)
```

yields a 2D Julia array whose element type is `UInt8` (see below for more
details).  Reading a given number of images is done by something like:

```julia
imgs = read(cam, UInt8, 10)
```

which reads 10 images of element type `UInt8` and return them as a vector of
images.  Each image is a Julia array whose dimensions are those of the chosen
region of interest (ROI).  It is however possible that the first dimension (the
*width*) be different to that of the ROI to accommodate for different sizes for
the pixel format used by the camera and the chosen element type.

In the `read` call, the element type of the result is optional.  If omitted, it
is given by `getcapturebitstype(cam)`.


### Continuous acquisition

Another way to acquire images is to process them as they arrive.  Assuming you
have connected and configured your camera, continuous acquisition is done by a
loop like:

```julia
start(cam, UInt16, 4) # start continuous acquisition with 4 cyclic buffers
for num in 1:100
    img, ticks = wait(cam, Inf) # wait for next frame (waiting forever)
    ... # process the captured image `img`
    release(cam) # image buffer is again available for acquisition
end
abort(cam) # abort acquisition and exit the loop
```

The `start` method iniates continuous acquisition, its arguments are the
element type of the captured images (optional as for the `read` method) and the
number of capture buffers to use.  The `wait` method waits for the next frame
from the specified camera but not longer than a given number of seconds, it
returns the next image and its timestamp (in seconds).  After processing of the
captured image, the `release` method should be called to reuse the associated
ressources for subsequant acquisitions.  The `stop` (or `abort`) method must be
called to terminate continuous acquisition (the former stops acquisition after
completion of the current image while the latter stops acquisition
immediately).

For real-time applications, it is important to avoid that new ressources be
allocated in the acquisition loop.  This explains the structure of the
continuous acquisition and processing loop above: ressources are allocated
before entering the loop (in particular by the `start` method), they are
recycled by the `release` method inside the loop and are eventually freed at
the end of the loop.  For the same reasons, it must not be assumed (unless
explicitly stated by the documentation related to a given camera / frame
grabber) that the captured image returned by the `wait` method is a new array:
to avoid resources allocation, the same image (or a limited number of images)
may be recycled by the acquisition loop.


### Closing the camera

When the camera is no longer needed, you may close it to disconnect it from the
hardware and release related resources.  This is as simple as:

```julia
close(cam)
```

In practice, this is even more simpler as you can avoid calling the `close`
method.  Indeed any serious concrete implementations should take care of
releasing resources when the camera instance is no longer referenced and
eventually finalized by Julia's garbage collector.  It may be necessary to
close the camera to disconnect it from the hardware so that it is immediately
available for some other purposes.


### Simple processing of a sequence of images

The `ScientificCameras` package provides a simple method to process a sequence
of images:

```julia
processimages(cam, num, proc, state;
              skip=0, timeout=sec, truncate=false) -> state, cnt
```

processes `num` images from camera `cam` by calling the function `proc` as
follows:

```julia
state = proc(state, img, ticks, cnt)
```

to process each image, here `img`, and update `state` (`ticks` is the timestamp
in seconds of the captured image `img` and `cnt` is the current image number,
starting at 1 for the first one).

The final state and the actual number of processed images are returned (the
latter can be smaller than `num` if a timeout occured and keyword `truncate` is
`true`.

The keywords `skip` (default 0), `timeout` and `truncate` (default `false`) may
be used and have the same meaning as for the `read` method.

For instance:

```julia
roi = getroi(cam)
dims = (roi.width, roi.height)
sum, cnt = processimages(cam, num, (sum, img, args...) -> (sum .+= img; sum),
                         zeros(dims))
```

yields `sum` the sum of a number of images and `cnt` the actual number of
images (which can onky be `num` in this example).

The methods `mean` and `stat` are extended to compute the sample mean of sample
meand and standard deviation of a sequence of images:

```julia
avg = mean(cam, num)
avg, rms, cnt = stat(cam, num)
```


### Pixel formats

`ScientificCameras.PixelFormat{N}` is the super-type of the various pixel
formats and is parameterized by `N` the number of bits per pixel.  In order to
avoid prefixing pixel formats by ``ScientificCameras.`, you may add:

```julia
using ScientificCameras.PixelFormats
```

to your code, as `using ScientificCameras` only imports public methods defined
by the package (no types).  In what follows, it is assumed that
`ScientificCameras.PixelFormats` has been imported with `using` as shown above.

Actual pixel formats are concrete sub-types of `PixelFormat{N}`.  The type
hierarchy is:

```
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
```

Note that *concrete* types (the leaves of the above tree) are all singletons.
This system forbids to have concrete definitions which provide an equivalent
Julia *bits*, that is *plain data*, type.  This is not really an isssue since
pixel formats are just meant to describe the pixel format used by a camera, not
to provide Julia equivalent bits types.  To get the equivalent bits type (when
it exists), call:

```julia
equivalentbitstype(format)
```

which returns `Void` when there is no possible exact equivalence.


### Choosing the pixel format

There are two pixel formats: one corresponding to the data sent by the camera
and the other corresponding to the pixels in the captured images.  To retrieve
the pixel format of the camera, just do:

```julia
fmt = getpixelformat(cam)
```

To change the pixel format of the camera `cam` to `fmt`, do:

```julia
setpixelformat!(cam, fmt)
```

For instance:

```julia
using ScientificCameras.PixelFormats
setpixelformat!(cam, Monochrome{10})
```

to select monochrome pixels encoded on 10 bits.  Not all hardware support
different pixel formats.

Because not all pixel formats are exactly representable by a Julia bits type,
the type of the elements of the Julia arrays used as image buffers has also to
be taken into account.  When capturing images, the type, say `T`, of the
elements of the Julia arrays used as image buffers may be specified as follows:

```julia
imgs = read(cam, T, n)
```

for sequential acquisition of `n` images, or:

```julia
start(cam, T, n)
```

for continuous acquisition using `n` image buffers and capturing images as
regular Julia 2D array whose element type is `T`.

If the type `T` of the array elements is not specified, the method
`getcapturebitstype(cam)` is used to find an equivalence Julia bits type.  If
there are no equivalent bits types, `getcapturebitstype(cam)` yields `UInt8`
(*i.e.* image buffers are stored as 2D byte arrays in Julia whose first
dimension is set so as to store the binary data of a single line of the
captured image with possible padding, and whose second dimension is the number
of lines in the captured image).

To avoid unpacking pixel values, it is advisable to choose a Julia bits type
for the captured images which is close or, better, exactly equivalent to the
camera pixel format.

When reading an image or a sequence of images, `read` accepts a number of
keywords:

* Use keyword `skip` to specify a number of images to skip.

* Use keyword `timeout` to specify the maximum amount of time (in seconds) to
  wait for the acquisition of each image.  If acquisition of any image takes
  longer than this time, a `ScientificCameras.TimeoutError` is thrown unless
  keyword `truncate` is `true` (see below).   The default timeout depends on the
  exposure time and acquisition frame rate (see [`defaulttimeout`](@ref)).

* When reading a sequence of images, keyword `truncate` may be set `true` to
  print a warning and return a truncated sequence instead of throwing an
  exception in case of timeout.

* Keyword `quiet` can be set `true` to suppress the printing of warning
  messages (see above).



## Implementing a concrete interface

Examples of concrete implementations of the interface are given by the
[`Phoenix.jl`](https://github.com/emmt/Phoenix.jl) and
[`AndorCameras.jl`](https://github.com/emmt/AndorCameras.jl) packages.

The `ScientificCameras` package mostly provides an infrastructure for concrete
interfaces to cameras.  To be callable (without throwing a
`ScientificCameras.NotImplementedException`), most methods must be extended for
types of camera derived from the abstract `ScientificCameras.ScientificCamera`
type.  The `ScientificCameras` package however handles the many different
possible signatures of these methods and takes care of properly converting the
arguments, so that it is generally sufficient to extend a single version of
each method.

Assuming `Camera` is such a type (*i.e.*, `Camera <: ScientificCamera`),
typically:

```julia
# Import all methods such that they can be extended and some types
# (only methods are exported by ScientificCameras).
importall ScientificCameras
import ScientificCameras: ScientificCamera, ROI
using ScientificCameras.PixelFormats

# Re-export the public interface of the ScientificCameras module.
ScientificCameras.@exportpublicinterface

function open(::Type{Camera}, args...; kwds...)
    cam = ... # create camera instance
    ...       # setup camera and open connection
    return cam
end

function close(::Type{Camera}; kwds...)
    ... # release resources
end

getfullwidth(cam::Camera) = cam.fullwidth
getfullheight(cam::Camera) = cam.fullheight

getroi(cam::Camera) =
    (cam.xoff, cam.yoff, cam.width, cam.height)

function setroi!(cam::Camera, roi::ROI)
    checkroi(cam, roi)
    ...
    return getroi(cam)
end
```

A complete interface would extend the following methods:

- `open` for creating an instance of the camera connected to the hardware.
- `close` for disconnecting a camera from the hardware.
- `start`, `wait`, `release`, `stop` and `abort` for continuous acquisition.
- `getfullwidth`, `getfullheight` for getting the full size of the sensor.
- `getroi` and `setroi!` for the region of interest.
- `getpixelformat`, `setpixelformat!`, `supportedpixelformats` and
  `getcapturebitstype` for the pixel format.
- `getspeed`, `setspeed!` and `checkspeed` for the frame rate and exposure
  time.
- `getgain` and `setgain!` for the gain of the analog to digital conversion.
- `getbias` and `setbias!` for the bias of the analog to digital conversion.
- `getgamma` and `setgamma!` for the gamma correction of the analog to digital
  conversion.

Default implementations are provided by `ScientificCameras` for the following
methods:
- `read` for reading a given number of images.

## Installation

The easiest way to install `ScientificCameras` is via the Julia registry
[`EmmtRegistry`](https://github.com/emmt/EmmtRegistry):

```julia
using Pkg
pkg"registry add https://github.com/emmt/EmmtRegistry"
pkg"add ScientificCameras"
```
