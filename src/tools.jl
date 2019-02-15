#
# tools.jl --
#
# Tools and utilities for scientific cameras.
#
#------------------------------------------------------------------------------
#
# This file is part of the `ScientificCameras.jl` package which is licensed
# under the MIT "Expat" License.
#
# Copyright (C) 2017, Éric Thiébaut.
#

"""
    mean([T = Float64,] cam, num; kwds...) -> img

yields the mean image `img` from the sample averaging of `num` images acquired
with camera `cam`.  Optional argument `T` is the floating-point type of the
elements of the result.

See also: [`stat`](@ref).

"""
mean(cam::ScientificCamera, args...; kwds...) =
    mean(Float64, cam, args...; kwds...)

function mean(::Type{T},
              cam::ScientificCamera,
              num::Integer = 100;
              kwds...) where {T <: AbstractFloat}
    roi = getroi(cam)
    dims = (roi.width, roi.height)
    sum, cnt = processimages(cam, num,
                             (sum, img, ticks, count) -> (sum .+= img; sum),
                             zeros(T, dims); kwds...)

    return convert(T, 1/cnt)*sum
end

"""
    stat([T = Float64,] cam, num; kwds...) -> avg, std, cnt

yields the mean image `avg` and standard deviation `std` of images from the
sample averaging of `num` images acquired with camera `cam`.  Optional argument
`T` is the floating-point type of the elements of the result.  The returned
value `cnt` is the actual number of samples and may be less than `num` if a
timeout occured and keyword `truncate` is true.

See also: [`stat`](@ref).

"""
stat(cam::ScientificCamera, args...; kwds...) =
    stat(Float64, cam, args...; kwds...)

function stat(::Type{T},
              cam::ScientificCamera,
              num::Integer = 100;
              kwds...) where {T <: AbstractFloat}
    # Integrate information.
    @assert num ≥ 2 "number of images must be at least 2"
    roi = getroi(cam)
    dims = (roi.width, roi.height)
    tup, cnt = processimages(cam, num,
                             (stat, img, ticks, count) -> updatestatistics!(stat, img),
                             (zeros(T, dims), zeros(T, dims)); kwds...)
    @assert cnt ≥ 2 "number of images must be at least 2"

    # Post-processing.
    s1, s2 = tup
    c1 = convert(T, 1/cnt)
    c2 = convert(T, 1/(cnt - 1))
    @inbounds @simd for i in 1:length(s1)
        v1 = convert(T, s1[i])
        v2 = c1*v1
        v3 = s2[i] - v2*v1
        s1[i] = v2
        s2[i] = (v3 > zero(T) ? sqrt(c2*v3) : zero(T))
    end

    return s1, s2, convert(Int, cnt)
end

function updatestatistics!(state::DenseArray{Ts,Ns},
                           arr::DenseArray{Ti,Ni}) where {Ts <: AbstractFloat,
                                                          Ns, Ti <: Real, Ni}
    @assert Ns == Ni + 1
    @assert size(state,1) == 2
    @assert size(state)[2:end] == size(arr)
    @inbounds @simd for i in 1:length(arr)
        val = convert(Ts, arr[i])
        state[1,i] += val
        state[2,i] += val*val
    end
    return state
end

function updatestatistics!(state::NTuple{2,DenseArray{Ts,N}},
                           arr::DenseArray{Ti,N}) where {Ts <: AbstractFloat,
                                                         Ti <: Real, N}
    sum1, sum2 = state
    @assert size(sum1) == size(sum2) == size(arr)
    @inbounds @simd for i in 1:length(arr)
        val = convert(Ts, arr[i])
        sum1[i] += val
        sum2[i] += val*val
    end
    return state
end

"""
    processimages(cam, num, proc, state;
                  skip=0, timeout=sec, truncate=false) -> state, count

processes `num` images from camera `cam` by calling the function `proc` to
process each image and update `state`:

    state = proc(state, img, ticks, count)

the final state and the actual number of processed images are returned.

"""
function processimages(cam::ScientificCamera,
                       number::Integer,
                       process::Function,
                       state;
                       skip::Integer = 0,
                       timeout::Real = defaulttimeout(cam),
                       truncate::Bool = false)
    # Check arguments.
    number ≥ 1 || throw(ArgumentError("invalid number of images to process"))
    skip ≥ 0 || throw(ArgumentError("invalid number of images to skip"))
    timeout > zero(timeout) || error("invalid timeout")

    # Acquire and process a sequence of images.
    count = zero(number)
    start(cam, 4)
    while count < number
        try
            img, ticks = wait(cam, timeout)
            if skip > zero(skip)
                # Skip this image.
                skip -= one(skip)
            else
                # Process this image.
                count += one(count)
                state = process(state, img, ticks, count)
            end
            release(cam)
        catch err
            if truncate && isa(err, TimeoutError)
                quiet || warn("Acquisition timeout after $cnt image(s)")
                number = count
            else
                abort(cam)
                rethrow(err)
            end
        end
    end
    abort(cam)
    return state, count
end
