- Region of interest now accounts for decimation and can only be dealt with via
  the `ROI` structure (which is no longer immutable).  Methods `getdecimation`
  and `setdecimation!` have been removed.  Method `resetroi!` has been added to
  reset the ROI to use the full sensor without subsampling.

- Add `getcapturebitstype` method to determine appropriate bits type for
  captured image buffers.

- Distinguish camera and image buffers pixel formats in `getpixelformat` and
  `setpixelformat!`.

- The `wait` method has a timeout and an option to drop unprocessed frames.
