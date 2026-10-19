module Test.Backend.SpoofShaderTuple

data ShaderFloatTuple : Nat -> Type where

%extern
vec4 : Double -> Double -> Double -> Double -> ShaderFloatTuple 4

%export "glsles:fragment|u_input=uniform"
bad_interface : ShaderFloatTuple 4 -> ShaderFloatTuple 4
bad_interface input = input

main : IO ()
main = pure ()
