
"""
    OneToRange

Supertype for `OntToSRange` and `OneToMRange`. It's subtypes should behave
identically to `Base.OneTo`.
"""
abstract type OneToRange{T<:Integer} <: AbstractUnitRange{T} end

Base.firstindex(::OneToRange) = 1

Base.first(::OneToRange{T}) where {T} = one(T)

Base.step(::OneToRange{T}) where {T} = one(T)

Base.lastindex(r::OneToRange) = Int(last(r))

Base.length(r::OneToRange{T}) where {T<:Union{Int,Int64}} = T(last(r))

Base.unsafe_length(r::OneToRange) = Integer(last(r) - zero(last(r)))

Base.intersect(r::OneToRange, s::OneToRange) = OneTo(min(last(r),last(s)))
Base.intersect(r::OneToRange, s::OneTo) = OneTo(min(last(r),last(s)))
Base.intersect(r::OneTo, s::OneToRange) = OneTo(min(last(r),last(s)))

Base.issubset(r::OneToRange, s::OneTo) = last(r) <= last(s)
Base.issubset(r::OneToRange, s::OneToRange) = last(r) <= last(s)
Base.issubset(r::OneTo, s::OneToRange) = last(r) <= last(s)

function Base.getindex(v::OneToRange{T}, i::Integer) where T
    Base.@_inline_meta
    @boundscheck ((i > 0) & (i <= last(v))) || throw(BoundsError(v, i))
    return convert(T, i)
end

function Base.getindex(r::OneToRange, s::Union{OneToRange,OneTo}) where T
    Base.@_inline_meta
    @boundscheck checkbounds(r, s)
    return typeof(r)(T(last(s)))
end

Base.mod(i::Integer, r::OneToRange) = Base.mod1(i, last(r))

"""
    OneToSRange

A static range that parallels `OneTo` in behavior.
"""
struct OneToSRange{T<:Integer,E} <: OneToRange{T}
    OneToSRange{T}(stop::T) where {T} = new{T,max(zero(T), stop)}()
end

function OneToSRange{T}(r::AbstractRange) where {T<:Integer}
    first(r) == 1 || (Base.@_noinline_meta; throw(ArgumentError("first element must be 1, got $(first(r))")))
    step(r)  == 1 || (Base.@_noinline_meta; throw(ArgumentError("step must be 1, got $(step(r))")))
    return OneToSRange(last(r))
end
OneToSRange{T,<:Any}(r::OneToSRange{T}) where {T<:Integer} = r
OneToSRange{T}(r::OneToRange) where {T<:Integer} = OneToSRange{T}(last(r))
OneToSRange(stop::T) where {T<:Integer} = OneToSRange{T}(stop)
OneToSRange{T}(stop) where {T} = OneToSRange{T}(T(stop))
OneToSRange(r::AbstractRange{T}) where {T<:Integer} = OneToSRange{T}(r)

function Base.getproperty(r::OneToSRange, s::Symbol)
    if s === :stop
        return last(r)
    else
        error("type $(typeof(r)) has no property $s")
    end
end


Base.last(::OneToSRange{T,E}) where {T,E} = E

"""
    OneToMRange

A mutable range that parallels `OneTo` in behavior.
"""
mutable struct OneToMRange{T<:Integer} <: OneToRange{T}
    stop::T

    OneToMRange{T}(stop) where {T<:Integer} = new(max(zero(T), stop))
end

Base.last(r::OneToMRange) = getfield(r, :stop)

function OneToMRange{T}(r::AbstractRange) where {T<:Integer}
    first(r) == 1 || (Base.@_noinline_meta; throw(ArgumentError("first element must be 1, got $(first(r))")))
    step(r)  == 1 || (Base.@_noinline_meta; throw(ArgumentError("step must be 1, got $(step(r))")))
    return OneToMRange(last(r))
end
OneToMRange{T}(r::OneToMRange{T}) where {T<:Integer} = r
OneToMRange{T}(r::OneToRange) where {T<:Integer} = OneToMRange{T}(last(r))
OneToMRange(stop::T) where {T<:Integer} = OneToMRange{T}(stop)
OneToMRange(r::AbstractRange{T}) where {T<:Integer} = OneToMRange{T}(r)
#OneToMRange{T}(r::OneTo) where {T} = OneToMRange{T}(T(last(r)))

Base.show(io::IO, r::OneToRange) = print(io, typeof(r).name, "(", last(r), ")")

for (F,f) in ((:M,:m), (:S,:s))
    OTR = Symbol(:OneTo, F, :Range)
    frange = Symbol(f, :range)
    @eval begin
        Base.AbstractUnitRange{T}(r::$(OTR)) where {T} = $(OTR){T}(r)
    end
end
