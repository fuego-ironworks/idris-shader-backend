module Shader.Coordinates

%default total

||| Named standard Cartesian frames in finite-dimensional real spaces.
||| OtherCartesianReal32 belongs to a different named space of equal dimension.
||| These descriptors are semantic identities, not GPU widths or memory layouts.
public export
data RealCoordinateFrame : Nat -> Type where
  CartesianReal4 : RealCoordinateFrame 4
  CartesianReal32 : RealCoordinateFrame 32
  OtherCartesianReal32 : RealCoordinateFrame 32

public export
data AmbientScalarField = RealScalars

public export
ambient_scalar_field : RealCoordinateFrame dimension -> AmbientScalarField
ambient_scalar_field _ = RealScalars

||| Numerical coordinates representing a vector in the named real space/frame.
||| Values approximate real coordinates under the backend's floating contract.
||| This opaque interface is not a list, GLSL vecN, or mathematical scalar field.
public export
data VectorCoordinates : (dimension : Nat) -> RealCoordinateFrame dimension -> Type where

||| Coordinates in the dual basis of the same named real space/frame.
||| There is no implicit vector-to-dual conversion in this interface.
public export
data CovectorCoordinates : (dimension : Nat) -> RealCoordinateFrame dimension -> Type where

||| Numerical approximation to evaluation of a linear functional on a vector.
||| In a basis and its dual basis this is the sum of paired coordinate products;
||| no inner product or vector-to-covector conversion is inferred.
public export %extern
coordinate_pairing :
  CovectorCoordinates dimension frame ->
  VectorCoordinates dimension frame -> Double
