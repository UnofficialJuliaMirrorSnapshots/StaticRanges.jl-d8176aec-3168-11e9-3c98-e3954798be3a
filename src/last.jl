Base.last(::OneToSRange{T,E}) where {T,E} = E

Base.last(r::OneToMRange) = getfield(r, :stop)

Base.last(::UnitSRange{T,F,L}) where {T,F,L} = L

Base.last(r::UnitMRange) = getfield(r, :stop)

Base.last(r::AbstractStepRangeLen) = unsafe_getindex(r, length(r))

Base.last(::LinSRange{T,B,E,L,D}) where {T,B,E,L,D} = E

Base.last(r::LinMRange) = getfield(r, :stop)

"""
    can_set_last(x) -> Bool

Returns `true` if the last element of `x` can be set. If `x` is a range then
changing the first element will also change the length of `x`.
"""
can_set_last(::T) where {T} = can_set_last(T)
can_set_last(::Type{T}) where {T} = can_setindex(T)
can_set_last(::Type{T}) where {T<:LinMRange} = true
can_set_last(::Type{T}) where {T<:StepMRange} = true
can_set_last(::Type{T}) where {T<:StepMRangeLen} = true
can_set_last(::Type{T}) where {T<:UnitMRange} = true
can_set_last(::Type{T}) where {T<:OneToMRange} = true

"""
    set_last!(x, val)

Set the last element of `x` to `val`.
"""
function set_last!(x::AbstractVector{T}, val::T) where {T}
    can_set_last(x) || throw(MethodError(set_last!, (x, val)))
    setindex!(x, val, lastindex(x))
    return x
end
set_last!(x::AbstractVector{T}, val) where {T} = set_last!(x, convert(T, val))
set_last!(r::LinMRange{T}, val::T) where {T} = (setfield!(r, :stop, val); r)
function set_last!(r::StepMRange{T,S}, val::T) where {T,S}
    setfield!(r, :stop, Base.steprange_last(first(r), step(r), val))
    return r
end
set_last!(r::UnitMRange{T}, val::T) where {T} = (setfield!(r, :stop, val); r)
function set_last!(r::OneToMRange{T}, val::T) where {T}
    setfield!(r, :stop, max(zero(T), T(val)))
    return r
end
function set_last!(r::StepMRangeLen{T}, val::T) where {T}
    len = unsafe_findvalue(val, r)
    len >= 0 || throw(ArgumentError("length cannot be negative, got $len"))
    1 <= r.offset <= max(1, len) || throw(ArgumentError("StepSRangeLen: offset must be in [1,$len], got $(r.offset)"))
    setfield!(r, :len, len)
    return r
end

