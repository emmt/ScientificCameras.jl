- Add `getcapturebitstype` method to determine appropriate bits type for
  captured image buffers.

- Distinguish camera and image buffers pixel formats in `getpixelformat` and
  `setpixelformat!`.

- Add `getdecimation` and `setdecimation!` to deal with pixel subsampling.

- The `wait` method has a timeout and an option to drop unprocessed frames.
