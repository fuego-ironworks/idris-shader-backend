module Shader.Source

%default total

||| An opaque numerical shader tuple. Its component count is checked by Idris
||| while the GLSL ES backend recovers it from the exported entry-point schema
||| and the primitive dataflow. This carrier alone establishes no geometric,
||| complex, colour, vector-space or dual role and no physical register layout.
public export
data ShaderFloatTuple : Nat -> Type where

||| A fixed-length shader array. This is an interface type rather than an
||| Idris heap container: the GLSL backend admits it only where it can preserve
||| the length and element type in generated shader code.
public export
data SArray : Nat -> Type -> Type where

public export %extern
array_at : SArray n a -> Double -> a

public export %extern
int_to_double : Int -> Double

public export %extern
vec2 : Double -> Double -> ShaderFloatTuple 2

public export %extern
vec3 : Double -> Double -> Double -> ShaderFloatTuple 3

public export %extern
vec4 : Double -> Double -> Double -> Double -> ShaderFloatTuple 4

public export %extern
x : ShaderFloatTuple (S n) -> Double

public export %extern
y : ShaderFloatTuple (S (S n)) -> Double

public export %extern
z : ShaderFloatTuple (S (S (S n))) -> Double

public export %extern
w : ShaderFloatTuple (S (S (S (S n)))) -> Double

public export %extern
add_components : ShaderFloatTuple n -> ShaderFloatTuple n -> ShaderFloatTuple n

public export %extern
subtract_components : ShaderFloatTuple n -> ShaderFloatTuple n -> ShaderFloatTuple n

public export %extern
scale_components : Double -> ShaderFloatTuple n -> ShaderFloatTuple n

public export %extern
component_product_sum : ShaderFloatTuple n -> ShaderFloatTuple n -> Double

public export %extern
euclidean_component_norm : ShaderFloatTuple n -> Double

public export %extern
normalize_components_unchecked : ShaderFloatTuple n -> ShaderFloatTuple n

public export %extern
absF : Double -> Double

public export %extern
sqrtF : Double -> Double

public export %extern
sinF : Double -> Double

public export %extern
cosF : Double -> Double

public export %extern
floorF : Double -> Double

public export %extern
fractF : Double -> Double

public export %extern
logF : Double -> Double

public export %extern
minF : Double -> Double -> Double

public export %extern
maxF : Double -> Double -> Double

public export %extern
atan2F : Double -> Double -> Double

public export %extern
powF : Double -> Double -> Double

public export %extern
clampF : Double -> Double -> Double -> Double

public export %extern
mixF : Double -> Double -> Double -> Double

public export %extern
smoothstepF : Double -> Double -> Double -> Double
