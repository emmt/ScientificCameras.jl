- `read(cam [, T])` returns a single image (not a vector with a single image).
  Default implementations of `read` are provided with keywords `timeout`,
  `truncate` and `skip`.

- New method `defaulttimeout` to compute a timeout for acquiring a given number
  of images.

- `wait` throws an exception of type `ScientificCameras.TimeoutError` in case
  of timeout.

- Pixel formats and bits types can be specifically imported by `using
  ScientificCameras.PixelFormats` and `using ScientificCameras.BitsTypes`.

- New macro `ScientificCameras.@exportpublicinterface` for derived modules to
  re-export the public interface (only methods for now) of the
  `ScientificCameras` module so that the end-user does not have to explicitly
  import/use the `ScientificCameras` module.

- Region of interest now accounts for decimation and can only be dealt with via
  the `ROI` structure (which is no longer immutable).  Methods `getdecimation`
  and `setdecimation!` have been removed.  Method `resetroi!` has been added to
  reset the ROI to use the full sensor without subsampling.

- Add `getcapturebitstype` method to determine appropriate bits type for
  captured image buffers.

- Distinguish camera and image buffers pixel formats in `getpixelformat` and
  `setpixelformat!`.

- The `wait` method has a timeout and an option to drop unprocessed frames.
