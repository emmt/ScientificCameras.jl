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
# Copyright (C) 2017-2019, Éric Thiébaut.
#

isdefined(Base, :__precompile__) && __precompile__(true)

module ScientificCameras

# Macro for derived modules to re-export the public interface of the
# `ScientificCameras` module so that the end-user does not have to explicitly
# import/use the `ScientificCameras` module.
_publicsymbols = (
    :open,
    :close,
    :defaulttimeout,
    :read,
    :start,
    :stop,
    :abort,
    :wait,
    :release,
    :getfullsize,
    :getfullwidth,
    :getfullheight,
    :getroi,
    :setroi!,
    :resetroi!,
    :checkroi,
    :bitsperpixel,
    :equivalentbitstype,
    :supportedpixelformats,
    :getpixelformat,
    :setpixelformat!,
    :getcapturebitstype,
    :getspeed,
    :setspeed!,
    :checkspeed,
    :getgain,
    :setgain!,
    :getbias,
    :setbias!,
    :getgamma,
    :setgamma!,
    :processimages)

macro exportpublicinterface()
    Expr(:export, _publicsymbols...)
end
@exportpublicinterface

import Base: open, read, close, wait
@static if isdefined(Base,:start)
    import Base: start
end
import Statistics: mean, stat

include("types.jl")
include("methods.jl")
include("tools.jl")
include("calibration.jl")
import .Calibration: CalibrationData, fit

end # module
