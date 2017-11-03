#
# ScientificCameras.jl --
#
# Julia abstract layer for scientific cameras.
#
#------------------------------------------------------------------------------
#
# This file is part of the `ScientificCameras.jl` package which is licensed
# under the MIT "Expat" License.
#
# Copyright (C) 2017, Éric Thiébaut.
#

isdefined(Base, :__precompile__) && __precompile__(true)

module ScientificCameras

import Base: open, read, close, start, wait

# Macro for derived modules to re-export the public interface (only methods for
# now) of the `ScientificCameras` module so that the end-user does not have to
# explicitly import/use the `ScientificCameras` module.
macro exportpublicinterface()
    :(export
      open,
      close,
      defaulttimeout,
      read,
      start,
      stop,
      abort,
      wait,
      release,
      getfullsize,
      getfullwidth,
      getfullheight,
      getroi,
      setroi!,
      resetroi!,
      checkroi,
      bitsperpixel,
      equivalentbitstype,
      supportedpixelformats,
      getpixelformat,
      setpixelformat!,
      getcapturebitstype,
      getspeed,
      setspeed!,
      checkspeed,
      getgain,
      setgain!,
      getbias,
      setbias!,
      getgamma,
      setgamma!)
end

@exportpublicinterface

include("types.jl")
include("methods.jl")

end # module
