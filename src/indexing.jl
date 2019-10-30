function Base.getindex(r::Union{AbstractStepRangeLen,AbstractLinRange}, i::Integer)
    Base.@_inline_meta
    @boundscheck checkbounds(r, i)
    unsafe_getindex(r, i)
end


###
### AbstractStepRangeLen
###
function _getindex_hiprec(r::AbstractStepRangeLen, i::Integer)  # without rounding by T
    u = i - _offset(r)
    return _ref(r) + u * step(r)
end

function _getindex_hiprec(
    r::AbstractStepRangeLen{<:Any,<:TwicePrecision,<:TwicePrecision},
    i::Integer
   )
    u = i - _offset(r)
    shift_hi, shift_lo = u * step_hp(r).hi, u * step_hp(r).lo
    x_hi, x_lo = add12(_ref(r).hi, shift_hi)
    x_hi, x_lo = add12(x_hi, x_lo + (shift_lo + _ref(r).lo))
    return TwicePrecision(x_hi, x_lo)
end

for RT in (:StepMRangeLen,:StepSRangeLen)
    @eval begin
        function Base.getindex(
            r::$(RT){T,TwicePrecision{T},TwicePrecision{T}},
            s::OrdinalRange{<:Integer}
           ) where {T}
            @boundscheck checkbounds(r, s)
            soffset = 1 + round(Int, (_offset(r) - first(s))/step(s))
            soffset = clamp(soffset, 1, length(s))
            ioffset = first(s) + (soffset-1)*step(s)
            if step(s) == 1 || length(s) < 2
                newstep = step_hp(r)
            else
                newstep = Base.twiceprecision(step_hp(r)*step(s), Base.nbitslen(T, length(s), soffset))
            end
            if ioffset == _offset(r)
                return similar_type(r)(_ref(r), newstep, length(s), max(1,soffset))
            else
                return similar_type(r)(_ref(r) + (ioffset-_offset(r))*step_hp(r), newstep, length(s), max(1,soffset))
            end
        end
    end
end


# although these should technically not need to be completely typed for
# each, dispatch ignores TwicePrecision on the static version and only
# uses the first otherwise
function Base.unsafe_getindex(
    r::StepSRangeLen{T,TwicePrecision{T},TwicePrecision{T}},
    i::Integer
   ) where {T}
    # Very similar to _getindex_hiprec, but optimized to avoid a 2nd call to add12
    Base.@_inline_meta
    u = i - _offset(r)
    shift_hi, shift_lo = u * step_hp(r).hi, u * step_hp(r).lo
    x_hi, x_lo = add12(_ref(r).hi, shift_hi)
    return T(x_hi + (x_lo + (shift_lo + _ref(r).lo)))
end

function Base.unsafe_getindex(
    r::StepMRangeLen{T,TwicePrecision{T},TwicePrecision{T}},
    i::Integer
   ) where {T}
    # Very similar to _getindex_hiprec, but optimized to avoid a 2nd call to add12
    Base.@_inline_meta
    u = i - _offset(r)
    shift_hi, shift_lo = u * step_hp(r).hi, u * step_hp(r).lo
    x_hi, x_lo = add12(_ref(r).hi, shift_hi)
    return T(x_hi + (x_lo + (shift_lo + _ref(r).lo)))
end

function Base.unsafe_getindex(r::StepSRangeLen{T,R,S}, i::Integer) where {T,R,S}
    return T(_ref(r) + (i - _offset(r)) * step_hp(r))
end
function Base.unsafe_getindex(r::StepMRangeLen{T,R,S}, i::Integer) where {T,R,S}
    return T(_ref(r) + (i - _offset(r)) * step_hp(r))
end

###
### AbstractLinRange
###
function Base.unsafe_getindex(r::AbstractLinRange, i::Integer)
    return Base.lerpi(i-1, lendiv(r), first(r), last(r))
end

function Base.getindex(r::AbstractLinRange, s::OrdinalRange{<:Integer})
    Base.@_inline_meta
    @boundscheck checkbounds(r, s)
    vfirst = unsafe_getindex(r, first(s))
    vlast  = unsafe_getindex(r, last(s))
    return LinMRange(vfirst, vlast, length(s))
end

function Base.getindex(r::LinSRange, s::Union{OneToSRange{T},UnitSRange{T},StepSRange{T}}) where {T<:Integer}
    Base.@_inline_meta
    @boundscheck checkbounds(r, s)
    vfirst = unsafe_getindex(r, first(s))
    vlast  = unsafe_getindex(r, last(s))
    return LinMRange(vfirst, vlast, length(s))
end

###
### StaticUnitRange
###
_in_unit_range(v::StaticUnitRange, val, i::Integer) = i > 0 && val <= last(v) && val >= first(v)

function Base.getindex(v::StaticUnitRange{T}, i::Integer) where T
    Base.@_inline_meta
    val = convert(T, first(v) + (i - 1))
    @boundscheck _in_unit_range(v, val, i) || throw(BoundsError(v, i))
    val
end

function Base.getindex(v::StaticUnitRange{T}, i::Integer) where {T<:Base.OverflowSafe}
    Base.@_inline_meta
    val = v.start + (i - 1)
    @boundscheck _in_unit_range(v, val, i) || throw(BoundsError(v, i))
    val % T
end
