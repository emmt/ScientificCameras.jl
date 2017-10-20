# A Julia infrastructure for scientific cameras

The `ScientificCameras` package provides an infrastructure to interface
scientific cameras with [`Julia`](http://julialang.org/).  This infrastructure
is an attempt to unify the use of interfaced cameras in Julia.


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
resetroi!(cam) # use full sensor are and no sub-sampling
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
`set*!(cam, ...)` methods shall throw a scpecific exception such as
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
roi.yoff = div(getfullheight(cam)/4)
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
time to read images.  Reading a given number of images is done by something
like:

```julia
imgs = read(cam, UInt8, 10)
```

which reads 10 images of element type `UInt8` and return them as a vector of
images.  Each image is a Julia array whose dimensions are those of the chosen
region of interest (ROI).  It is however possible that the first dimension (the
*width*) be different to that of the ROI to accommodate for different sizes for
the pixel format used by the camera and the chosen element type.


### Continuous acquisition

Another way to acquire images is to process them as they arrive.  Assuming you
have connected and configured your camera, continuous acquisition is done by a
loop like:

```julia
bufs = start(cam, UInt16, 4) # start continuous acquisition
for number in 1:100
    index = wait(cam, Inf) # wait for next frame (waiting forever)
    buf = bufs[index] # get image buffer
    ... # process the image buffer
    release(cam) # frame buffer is again available for acquisition
end
abort(cam) # abort acquisition and exit the loop
```


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


### Pixel formats

`ScientificCameras.PixelFormat{N}` is the super-type of the various pixel
formats and is parameterized by `N` the number of bits per pixel.  In order to
avoid prefixing pixel formats by ``ScientificCameras.`, you may add:

    using ScientificCameras.PixelFormats

to your code, as `using ScientificCameras` only imports public methods defined
by the package (no types).  In what follows, it is assumed that
`ScientificCameras.PixelFormats` has been imported with `using` as shown above.

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


### Choosing the pixel format

There are two pixel formats: one, say `campix`, corresponding to the data sent
by the camera and the other, say `bufpix`, corresponding to the pixels in the
captured images.  To retrieve these pixel formats, just do:

    campix, bufpix = getpixelformat(cam)

To change the pixel format(s), do:

    setpixelformat!(cam, campix)

to set the camera pixel format to `campix` and use a close approximation of
`campix` for the captured images, or:

    setpixelformat!(cam, campix, bufpix)

to set possibly different pixel formats.  Not all hardware support all
combination of pixel formats.

Because not all pixel formats are exactly representable by a Julia bits type,
the type of the elements of the Julia arrays used as image buffers has also to
be taken into account.  When capturing images, the type, say `T`, of the
elements of the Julia arrays used as image buffers may be specified as follows:

    imgs = read(cam, T, n)

for sequential acquisition of `n` images, or:

    imgs = start(cam, T, n)

for continuous acquisition using `n` image buffers.  An image buffer,
`imgs[k]`, is a regular Julia 2D array whose element type is `T`, whose first
dimension is set so as to store the binary data of a single line of the
captured image (with pixel format `bufpix`) with possible padding, and whose
second dimension is the number of lines in the captured image.

If the type `T` of the array elements is not specified, the method
`getcapturebitstype(cam)` is used to find a Julia bits type corresponding to
the image buffers pixel format `bufpix`.  If there are no equivalent bits
types, `getcapturebitstype(cam)` yields `UInt8` (*i.e.* image buffers are
stored as 2D byte arrays in Julia).

To avoid unpacking pixel values, it is advisable to choose a pixel format,
`bufpix`, for the image buffers which is close to the camera pixel format
`campix` while having an exact equivalent Julia bits type.


## Implementing a concrete interface

An example of concrete implementation of the interface is given by the
[`Phoenix.jl`](https://github.com/emmt/Phoenix.jl) package.

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
- `read` for reading a given number of images.
- `start`, `wait`, `release`, `stop` and `abort` for continuous acquisition.
- `getfullwidth`, `getfullheight` for getting the full size of the sensor.
- `getroi` and `setroi!` for the region of interest.
- `getpixelformat`, `setpixelformat!` and `supportedpixelformats` for the pixel
  format.
- `getspeed`, `setspeed!` and `checkspeed` for the frame rate and exposure
  time.
- `getgain` and `setgain!` for the gain of the analog to digital conversion.
- `getbias` and `setbias!` for the bias of the analog to digital conversion.
- `getgamma` and `setgamma!` for the gamma correction of the analog to digital
  conversion.


## Installation

`ScienticCameras.jl` is not yet an
[official Julia package](https://pkg.julialang.org/) so you have to clone the
repository to install the package:

```julia
Pkg.clone("https://github.com/emmt/ScienticCameras.jl.git")
```

There is nothing to build so no needs to call `Pkg.build("ScienticCameras")`.

Later, it is sufficient to do:

```julia
Pkg.update("ScienticCameras")
```

to pull the latest version.  If you have `ScienticCameras.jl` repository not
managed at all by Julia's package manager, updating is a matter of:

```sh
cd "$REPOSITORY/deps"
git pull
```

assuming `$REPOSITORY` is the path to the top level directory of the
`ScienticCameras.jl` repository.
