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

module ScientificCameras

import Base: open, read, close, start, wait

# Only methods are exported to avoid pollution of the namespace by types.
export
    open,
    close,
    read,
    start,
    stop,
    abort,
    wait,
    release,
    getdecimation,
    setdecimation!,
    getfullsize,
    getfullwidth,
    getfullheight,
    getroi,
    setroi!,
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
    setgamma!

include("types.jl")
include("methods.jl")

end # module
