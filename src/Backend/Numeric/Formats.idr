module Backend.Numeric.Formats

import Data.List
import Data.Nat

%default total

||| OCP scalar payloads and AMD FNUZ payloads have different meanings.
public export
data Format = E4M3 | E5M2 | E4M3FNUZ | E5M2FNUZ | E2M1 | E2M3 | E3M2

public export
Eq Format where
  E4M3 == E4M3 = True
  E5M2 == E5M2 = True
  E4M3FNUZ == E4M3FNUZ = True
  E5M2FNUZ == E5M2FNUZ = True
  E2M1 == E2M1 = True
  E2M3 == E2M3 = True
  E3M2 == E3M2 = True
  _ == _ = False

public export
Show Format where
  show E4M3 = "e4m3"
  show E5M2 = "e5m2"
  show E4M3FNUZ = "e4m3fnuz"
  show E5M2FNUZ = "e5m2fnuz"
  show E2M1 = "e2m1"
  show E2M3 = "e2m3"
  show E3M2 = "e3m2"

||| Every finite admitted value is an integer number of 2^-17 units.
||| This exact model does not evaluate arithmetic using host Double.
public export
data Value = Finite Integer | Zero Bool | Infinity Bool | NaN

public export
Eq Value where
  -- Structural equality of decoded representations, not an IEEE floating
  -- comparison operation. In particular these NaN tags classify encodings.
  Finite a == Finite b = a == b
  Zero a == Zero b = a == b
  Infinity a == Infinity b = a == b
  NaN == NaN = True
  _ == _ = False

public export
unitsPerOne : Integer
unitsPerOne = 131072

||| Transparent binary power so the format layout remains normalizable by
||| downstream definitional proofs, independently of library export opacity.
public export
binaryPower : Nat -> Nat
binaryPower Z = 1
binaryPower (S exponent) = 2 * binaryPower exponent

public export
formatParameters : Format -> (Nat, Nat, Nat)
formatParameters E4M3 = (4, 3, 7)
formatParameters E5M2 = (5, 2, 15)
formatParameters E4M3FNUZ = (4, 3, 8)
formatParameters E5M2FNUZ = (5, 2, 16)
formatParameters E2M1 = (2, 1, 1)
formatParameters E2M3 = (2, 3, 1)
formatParameters E3M2 = (3, 2, 3)

public export
signMask : Format -> Nat
signMask format = let (exponentBits, fractionBits, _) = formatParameters format in
                 binaryPower (exponentBits + fractionBits)

public export
fnuz : Format -> Bool
fnuz E4M3FNUZ = True
fnuz E5M2FNUZ = True
fnuz _ = False

public export
decode : Format -> Nat -> Either String Value
-- These published exceptional encodings are also transparent proof laws.
decode E4M3FNUZ 128 = Right NaN
decode E5M2FNUZ 128 = Right NaN
decode E4M3 128 = Right (Zero True)
decode E5M2 128 = Right (Zero True)
decode format payload =
  let mask = signMask format
      negative = payload >= mask
      magnitude = mod payload mask
      (exponentBits, fractionBits, bias) = formatParameters format
      fractionCount = binaryPower fractionBits
      exponent = div magnitude fractionCount
      fraction = mod magnitude fractionCount
      special = exponent == minus (binaryPower exponentBits) 1
      significand = if exponent == 0 then fraction else fractionCount + fraction
      shift = minus ((if exponent == 0 then 1 else exponent) + 17) (bias + fractionBits)
      units : Integer = cast significand * cast (binaryPower shift)
   in if payload >= 2 * mask then Left "payload exceeds scalar format width"
      else if fnuz format && payload == mask then Right NaN
      else if format == E4M3 && magnitude == 127 then Right NaN
      else if format == E5M2 && special
              then Right (if fraction == 0 then Infinity negative else NaN)
      else if magnitude == 0 then Right (Zero negative)
      else Right (Finite (if negative then -units else units))

positiveUnits : Format -> Nat -> Maybe Integer
positiveUnits format code = case decode format code of
  Right (Finite units) => Just units
  Right (Zero False) => Just 0
  _ => Nothing

codes : Nat -> List Nat
codes Z = []
codes (S count) = 0 :: map S (codes count)

finiteCodes : Format -> List (Nat, Integer)
finiteCodes format = mapMaybe (\code => map (\units => (code, units)) (positiveUnits format code)) (codes (signMask format))

nearest : Integer -> Integer -> (Nat, Integer) -> List (Nat, Integer) -> Nat
nearest numerator denominator best [] = fst best
nearest numerator denominator best (candidate :: rest) =
  let bestDistance = abs (numerator - snd best * denominator)
      candidateDistance = abs (numerator - snd candidate * denominator)
      choose = candidateDistance < bestDistance ||
               (candidateDistance == bestDistance && mod (fst candidate) 2 == 0)
   in nearest numerator denominator (if choose then candidate else best) rest

public export
maxCode : Format -> Nat
maxCode E4M3 = 126
maxCode E5M2 = 123
maxCode format = minus (signMask format) 1

nanCode : Format -> Maybe Nat
nanCode E4M3 = Just 127
nanCode E5M2 = Just 127
nanCode E4M3FNUZ = Just 128
nanCode E5M2FNUZ = Just 128
nanCode _ = Nothing

||| Exact rational conversion with caller-selected overflow policy.
||| Numerator/denominator are in 2^-17 units; denominator must be positive.
||| No silent saturation, sign/width change or FNUZ reinterpretation.
public export
encodeRational : Format -> Bool -> Bool -> Integer -> Integer -> Either String Nat
encodeRational format saturate negativeZero numerator denominator = do
  if denominator > 0 then Right () else Left "conversion denominator must be positive"
  let negative = numerator < 0 || (numerator == 0 && negativeZero)
      magnitude = abs numerator
      sign = if negative then signMask format else 0
      largest = maxCode format
  Just maximum <- pure (positiveUnits format largest)
    | Nothing => Left "invalid finite-format maximum"
  Just previous <- pure (positiveUnits format (minus largest 1))
    | Nothing => Left "invalid finite-format predecessor"
  let twiceBoundary = 2 * maximum + (maximum - previous)
      exceeds = 2 * magnitude > twiceBoundary * denominator ||
                (2 * magnitude == twiceBoundary * denominator && mod largest 2 /= 0)
  if not saturate && exceeds
     then if format == E5M2 then Right (sign + 124)
          else case nanCode format of
            Just code => Right (if fnuz format then code else sign + code)
            Nothing => Left "finite-only conversion overflow requires explicit saturation"
     else do
       let code = nearest magnitude denominator (0, 0) (finiteCodes format)
       Right (if code == 0 && fnuz format then 0 else sign + code)

public export
encode : Format -> Bool -> Value -> Either String Nat
encode format saturate (Finite units) = encodeRational format saturate False units 1
encode format saturate (Zero negative) = encodeRational format saturate negative 0 1
encode format saturate NaN = maybe (Left "finite-only scalar has no NaN encoding") Right (nanCode format)
encode format saturate (Infinity negative) =
  if saturate then Right ((if negative then signMask format else 0) + maxCode format)
  else if format == E5M2 then Right ((if negative then signMask format else 0) + 124)
  else maybe (Left "finite-only scalar has no NaN encoding") Right (nanCode format)

public export
convert : Format -> Format -> Bool -> Nat -> Either String Nat
convert source destination saturate payload = decode source payload >>= encode destination saturate

finiteUnits : Value -> Either String Integer
finiteUnits (Finite units) = Right units
finiteUnits (Zero _) = Right 0
finiteUnits _ = Left "exact arithmetic reference requires finite operands"

negativeValue : Value -> Bool
negativeValue (Finite units) = units < 0
negativeValue (Zero negative) = negative
negativeValue (Infinity negative) = negative
negativeValue NaN = False

||| Mathematical reference followed by one explicitly non-saturating
||| quantization. This is not a claim of GPU FP8 ALU arithmetic or of the
||| separately specified F32-widened machine operation.
public export
referenceArithmetic : Format -> String -> Nat -> Nat -> Either String Nat
referenceArithmetic format operation first second = do
  left <- decode format first
  right <- decode format second
  a <- finiteUnits left
  b <- finiteUnits right
  let negative = negativeValue left /= negativeValue right
  case operation of
    "add" => encodeRational format False (negativeValue left && negativeValue right) (a + b) 1
    "sub" => encodeRational format False (negativeValue left && not (negativeValue right)) (a - b) 1
    "mul" => encodeRational format False negative (a * b) unitsPerOne
    "div" => if b == 0 then encode format False (if a == 0 then NaN else Infinity negative)
             else encodeRational format False negative (a * unitsPerOne * (if b < 0 then -1 else 1)) (abs b)
    _ => Left "unknown exact arithmetic reference operation"

public export
reinterpret : Format -> Format -> Nat -> Either String Nat
reinterpret source destination payload =
  if source == destination then map (const payload) (decode source payload)
  else Left "incompatible scalar layouts require explicit conversion"

public export
data StorageRole = ScalarPayload Format | MXBlock Format | ExperimentalSignedE5M3 | NVIDIAUE5M3Scale

||| Experimental signed E5M3 requires nine logical bits (1+5+3), whereas
||| NVIDIA UE5M3 is an unsigned eight-bit scaling representation. Neither is
||| one of these signed FP8 scalar operands. MX additionally needs a scale and
||| a 32-element block; its payload alone is not the represented value.
public export
scalarLayout : StorageRole -> Either String Format
scalarLayout (ScalarPayload format) = Right format
scalarLayout (MXBlock _) = Left "MX payload requires block length and E8M0 scale"
scalarLayout ExperimentalSignedE5M3 = Left "signed E5M3 is experimental nine-bit storage"
scalarLayout NVIDIAUE5M3Scale = Left "UE5M3 is an unsigned scale, not a signed scalar"

public export
data ScaledValue = ScaledFinite Integer Int | ScaledZero Bool | ScaledInfinity Bool | ScaledNaN

||| Unbounded exact dyadic value, preserving the full E8M0 scale range.
||| `ScaledFinite coefficient exponent` means coefficient * 2^exponent.
public export
decodeMX : Format -> Nat -> List Nat -> Either String (List ScaledValue)
decodeMX format scale payloads = do
  if length payloads == 32 then Right () else Left "MX block must contain 32 elements"
  if scale < 256 then Right () else Left "MX E8M0 scale exceeds eight bits"
  values <- traverse (decode format) payloads
  if scale == 255 then Right (map (const ScaledNaN) values)
     else Right (map (\value => case value of
                    Finite units => ScaledFinite units (cast scale - 144)
                    Zero negative => ScaledZero negative
                    Infinity negative => ScaledInfinity negative
                    NaN => ScaledNaN) values)
