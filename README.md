# A Julia infrastructure for scientific cameras

The `ScientificCameras` module provides an infrastructure to interface
scientific cameras with [`Julia`](http://julialang.org/).

## Table of contents

* [Usage of the provided methods for the end-user.](#usage)
* [Tricks](#tricks)
* [Installation of the module.](#installation)


## Usage

To explain typical usage of the methods provided by `ScientificCameras`, it is
best to present typical examples of the different stages.


### Connection and configuration

You must first import the general module and a specific camera model, say `SomeCameraModel`,
from a specific frame grabber module, say `SomeFrameGrabber`:

```julia
using ScientificCameras
import SomeFrameGrabber: SomeCameraModel
```

Second, you create an instance of the camera and connect it to the hardware by:

```julia
cam = open(SomeCameraModel)
```

Third, you want to configure the camera:

```julia
fullwidth, fullheight = getfullsize(cam) # get the full sensor size
setroi!(cam, 0, 0, fullwidth, fullsize) # set region of interest (ROI)
setspeed!(cam, 100, 0.005) # 100 frames per second, 5ms of exposure
setgain!(cam, 1.0) # set the gain of the analog to digital conversion
setbias!(cam, 0.0) # set the bias of the analog to digital conversion
setgamma!(cam, 1.0) # set the gamma correction of the analog to digital conversion
setdepth!(cam, 8) # set the number of bits per pixels
```

Note that you may choose different settings (for instance, a smaller ROI) and
that not all these settings may be available for the considered camera.  To
figure out the current settings, you can use `get*` methods (for instance,
`getspeed(cam)` yields the current number of frames per seconds and exposure
time).  As general rules: the `set*!(cam, ...)` methods shall return the actual
settings which may ony be a proxy of what has been required and these methods
shall throw a `ScientificCameras.NotImplementedException` when a specific
setting is not impleneted (so that you can specifically catch it).


### Reading a given number of images

Assuming you have a connected and configured camera, its time to read images.
To read a given number of images, use:

```julia
imgs = read(cam, UInt8, 10)
```

which read 10 images of pixel type `UInt8` and return them as a vector of
images.  Each image is a Julia array whose element type is the pixel type and
the dimensions those of the chosen region of interest (ROI).  It is however
possible that the first dimension (the *width*) be different to that of the ROI
to accommodate for different sizes for the pixel format used by the camera and
the chosen pixel type.


### Continuous acquisition

Another way to acquire images is to process them as they arrive.  Assuming you
have connected and configured your camera, continuous acquisition is:

```julia
bufs = start(cam, UInt16, 4)
while true
    # Wait for next frame.
    index, number, overflows = wait(cam)
    buf = bufs[index] # get image buffer
    ... # process the image buffer
    release(cam)
    if number > 100
        abort(cam) # abort acquisition and exit the loop
        break
    end
end
```


### Closing the camera

When the camera is no longer needed, you may close it to release related
ressources.  This is as simple as:

```julia
close(cam)
```

In practice, this is even more simpler as you can avoid calling the `close`
method.  Indeed any serious concrete implementations should take care of
releasing resources when the camera instance is no longer referenced and
eventually finalized by Julia's garbage collector.  It may be necessary to
close the camera to release resources immediately so that they are immediately
available for some other purposes.


## Concrete types

The `ScientificCameras` module mostly provides an infrastructure for concrete
interfaces to cameras.  To be callable (without throwing a
`ScientificCameras.NotImplementedException`), most methods must be extended for
types of camera derived from the abstract `ScientificCameras.ScientificCamera`
type.  The `ScientificCameras` module however handles the many different
possible signatures of these methods and takes care of properly converting the
arguments, so that it is generally sufficient to extend a single version of
each method.

A complete interface would extend the following methods:

- `open` for creating an instance of the camera connected to the hardware.
- `close` for disconnecting a camera from the hardware.
- `read` for reading a given number of images.
- `start`, `wait`, `release`, `stop` and `abort` for continuous acquisition.
- `getfullwidth`, `getfullheight` for getting the full size of the sensor.
- `getroi` and `setroi!` for the region of interest.
- `getspeed`, `setspeed!` and `checkspeed` for the frame rate and exposure
  time.
- `getgain` and `setgain!` for the gain of the analog to digital conversion.
- `getbias` and `setbias!` for the bias of the analog to digital conversion.
- `getgamma` and `setgamma!` for the gamma correction of the analog to digital
  conversion.
- `getdepth` and `setdepth!` for the number of bits per pixels.

Assuming `Camera` is such a type (*i.e.*, `Camera <: ScientificCamera`),
typically:

    # Import all methods such that they can be extended and some types
    # (only methods are exported by ScientificCameras).
    importall ScientificCameras
    import ScientificCameras: ScientificCamera, ROI
    import Base: open, close, read.

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


## Installation

To be able to use this module, you must have installed ActiveSilicon Phoenix
libraries and the module [`IPC.jl`](https://github.com/emmt/IPC.jl).

`ScienticCameras.jl` is not yet an [official Julia package](https://pkg.julialang.org/)
so you have to clone the repository to install the module:

    Pkg.clone("https://github.com/emmt/ScienticCameras.jl.git")

There is nothing to build so no needs to call `Pkg.build("ScienticCameras")`.

Later, it is sufficient to do:

    Pkg.update("ScienticCameras")

to pull the latest version.  If you have `ScienticCameras.jl` repository not
managed at all by Julia's package manager, updating is a matter of:

    cd "$REPOSITORY/deps"
    git pull

assuming `$REPOSITORY` is the path to the top level directory of the
`ScienticCameras.jl` repository.
