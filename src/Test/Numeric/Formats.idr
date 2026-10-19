module Test.Numeric.Formats

import Backend.Numeric.Formats
import Test.Numeric.Proofs
import Data.List
import System

%default covering

render : Value -> String
render (Finite units) = show units
render (Zero False) = "0"
render (Zero True) = "-0"
render (Infinity False) = "+inf"
render (Infinity True) = "-inf"
render NaN = "nan"

emit : Format -> Nat -> IO ()
emit format code = case decode format code of
  Left message => do putStrLn message; exitFailure
  Right value => do
    putStrLn ("decode\t" ++ show format ++ "\t" ++ show code ++ "\t" ++ render value)
    case value of
      Finite units => do
        let converted = encode format False value
        case converted of
          Right back => if back == code then pure () else exitFailure
          Left _ => exitFailure
      _ => pure ()

boundaries : Format -> Nat -> IO ()
boundaries format code = case (decode format code, decode format (S code)) of
  (Right first, Right (Finite second)) =>
    let firstUnits = case first of
                          Finite units => units
                          _ => 0
        midpoint = firstUnits + second
     in traverse_ (\offset => case encodeRational format False False (midpoint * 4 + offset) 8 of
          Right value => putStrLn ("round\t" ++ show format ++ "\t" ++ show code ++ "\t" ++ show offset ++ "\t" ++ show value)
          Left _ => exitFailure) [-1, 0, 1]
  _ => pure ()

main : IO ()
main = do
  traverse_ (\format => do
    traverse_ (emit format) [0 .. minus (2 * signMask format) 1]
    traverse_ (boundaries format) [0 .. minus (maxCode format) 1])
    [E4M3, E5M2, E4M3FNUZ, E5M2FNUZ, E2M1, E2M3, E3M2]
  traverse_ (\format => do
    let mask = signMask format
        samples = [0, 1, 2, maxCode format, mask, mask + 1, mask + 2, mask + maxCode format]
        finiteSamples = filter (\code => decode format code /= Right NaN) samples
    traverse_ (\first => traverse_ (\second => traverse_ (\operation =>
      case referenceArithmetic format operation first second of
        Left message => do putStrLn message; exitFailure
        Right result => putStrLn ("arith\t" ++ show format ++ "\t" ++ show first ++ "\t" ++ show second ++ "\t" ++ operation ++ "\t" ++ show result))
      ["add", "sub", "mul", "div"]) finiteSamples) finiteSamples)
    [E4M3, E5M2, E4M3FNUZ, E5M2FNUZ]
  if reinterpret E4M3 E4M3FNUZ 128 == Left "incompatible scalar layouts require explicit conversion"
     then pure () else exitFailure
  if decode E4M3FNUZ 128 == Right NaN && decode E4M3 128 == Right (Zero True)
     then pure () else exitFailure
  if encodeRational E5M2 False False (61440 * unitsPerOne) 1 == Right 124
     then pure () else exitFailure
  if encodeRational E4M3 False False (464 * unitsPerOne) 1 == Right 126
     then pure () else exitFailure
  if encodeRational E4M3 False False (465 * unitsPerOne) 1 == Right 127
     then pure () else exitFailure
  if convert E4M3 E4M3FNUZ False 128 == Right 0 then pure () else exitFailure
  case decodeMX E4M3 0 (replicate 32 56) of
    Right (ScaledFinite coefficient exponent :: _) =>
      if coefficient == unitsPerOne && exponent == -144 then pure () else exitFailure
    _ => exitFailure
  case decodeMX E4M3 254 (replicate 32 56) of
    Right (ScaledFinite coefficient exponent :: _) =>
      if coefficient == unitsPerOne && exponent == 110 then pure () else exitFailure
    _ => exitFailure
  case decodeMX E4M3 255 (replicate 32 56) of
    Right (ScaledNaN :: _) => pure ()
    _ => exitFailure
  case decodeMX E4M3 127 [] of
    Left _ => pure ()
    _ => exitFailure
