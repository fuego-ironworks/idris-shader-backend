module Test.Numeric.Proofs

import Backend.Numeric.Formats

%default total
%unbound_implicits off

fnuzNegativeZeroIsNaN : decode E4M3FNUZ 128 = Right NaN
fnuzNegativeZeroIsNaN = Refl

ocpNegativeZeroIsZero : decode E4M3 128 = Right (Zero True)
ocpNegativeZeroIsZero = Refl

fnuzReinterpretationRefused : reinterpret E4M3 E4M3FNUZ 128 =
  Left "incompatible scalar layouts require explicit conversion"
fnuzReinterpretationRefused = Refl

mxNeedsScale : scalarLayout (MXBlock E4M3) =
  Left "MX payload requires block length and E8M0 scale"
mxNeedsScale = Refl

signedE5M3IsNotFP8 : scalarLayout ExperimentalSignedE5M3 =
  Left "signed E5M3 is experimental nine-bit storage"
signedE5M3IsNotFP8 = Refl

unsignedScaleIsNotScalar : scalarLayout NVIDIAUE5M3Scale =
  Left "UE5M3 is an unsigned scale, not a signed scalar"
unsignedScaleIsNotScalar = Refl
