module Backend.GLSLES.IR

import Data.Fin
import Decidable.Equality

%default total

public export
data ArrayElementTy = AFloat | ABool | AInt | AFloatTuple Nat

public export
Eq ArrayElementTy where
  AFloat == AFloat = True
  ABool == ABool = True
  AInt == AInt = True
  AFloatTuple n == AFloatTuple m = n == m
  _ == _ = False

public export
DecEq ArrayElementTy where
  decEq AFloat AFloat = Yes Refl
  decEq AFloat ABool = No (\Refl impossible)
  decEq AFloat AInt = No (\Refl impossible)
  decEq AFloat (AFloatTuple _) = No (\Refl impossible)
  decEq ABool AFloat = No (\Refl impossible)
  decEq ABool ABool = Yes Refl
  decEq ABool AInt = No (\Refl impossible)
  decEq ABool (AFloatTuple _) = No (\Refl impossible)
  decEq AInt AFloat = No (\Refl impossible)
  decEq AInt ABool = No (\Refl impossible)
  decEq AInt AInt = Yes Refl
  decEq AInt (AFloatTuple _) = No (\Refl impossible)
  decEq (AFloatTuple _) AFloat = No (\Refl impossible)
  decEq (AFloatTuple _) ABool = No (\Refl impossible)
  decEq (AFloatTuple _) AInt = No (\Refl impossible)
  decEq (AFloatTuple n) (AFloatTuple m) with (decEq n m)
    decEq (AFloatTuple n) (AFloatTuple n) | Yes Refl = Yes Refl
    decEq (AFloatTuple n) (AFloatTuple m) | No contra = No (\Refl => contra Refl)

public export
Show ArrayElementTy where
  show AFloat = "float"
  show ABool = "bool"
  show AInt = "int"
  show (AFloatTuple n) = "float-tuple" ++ show n

||| Runtime value types admitted by the restricted shader compiler. Component
||| count and fixed array length remain explicit in the checked shader IR.
public export
data ValueTy = TFloat | TBool | TInt | TFloatTuple Nat | TArray Nat ArrayElementTy

public export
arrayElementValueTy : ArrayElementTy -> ValueTy
arrayElementValueTy AFloat = TFloat
arrayElementValueTy ABool = TBool
arrayElementValueTy AInt = TInt
arrayElementValueTy (AFloatTuple n) = TFloatTuple n

public export
Eq ValueTy where
  TFloat == TFloat = True
  TBool == TBool = True
  TInt == TInt = True
  TFloatTuple n == TFloatTuple m = n == m
  TArray n a == TArray m b = n == m && a == b
  _ == _ = False

public export
DecEq ValueTy where
  decEq TFloat TFloat = Yes Refl
  decEq TFloat TBool = No (\Refl impossible)
  decEq TFloat TInt = No (\Refl impossible)
  decEq TFloat (TFloatTuple _) = No (\Refl impossible)
  decEq TFloat (TArray _ _) = No (\Refl impossible)
  decEq TBool TFloat = No (\Refl impossible)
  decEq TBool TBool = Yes Refl
  decEq TBool TInt = No (\Refl impossible)
  decEq TBool (TFloatTuple _) = No (\Refl impossible)
  decEq TBool (TArray _ _) = No (\Refl impossible)
  decEq TInt TFloat = No (\Refl impossible)
  decEq TInt TBool = No (\Refl impossible)
  decEq TInt TInt = Yes Refl
  decEq TInt (TFloatTuple _) = No (\Refl impossible)
  decEq TInt (TArray _ _) = No (\Refl impossible)
  decEq (TFloatTuple _) TFloat = No (\Refl impossible)
  decEq (TFloatTuple _) TBool = No (\Refl impossible)
  decEq (TFloatTuple _) TInt = No (\Refl impossible)
  decEq (TFloatTuple n) (TFloatTuple m) with (decEq n m)
    decEq (TFloatTuple n) (TFloatTuple n) | Yes Refl = Yes Refl
    decEq (TFloatTuple n) (TFloatTuple m) | No contra = No (\Refl => contra Refl)
  decEq (TFloatTuple _) (TArray _ _) = No (\Refl impossible)
  decEq (TArray _ _) TFloat = No (\Refl impossible)
  decEq (TArray _ _) TBool = No (\Refl impossible)
  decEq (TArray _ _) TInt = No (\Refl impossible)
  decEq (TArray _ _) (TFloatTuple _) = No (\Refl impossible)
  decEq (TArray n a) (TArray m b) with (decEq n m)
    decEq (TArray n a) (TArray n b) | Yes Refl with (decEq a b)
      decEq (TArray n a) (TArray n a) | Yes Refl | Yes Refl = Yes Refl
      decEq (TArray n a) (TArray n b) | Yes Refl | No contra =
        No (\Refl => contra Refl)
    decEq (TArray n a) (TArray m b) | No contra = No (\Refl => contra Refl)

public export
Show ValueTy where
  show TFloat = "float"
  show TBool = "bool"
  show TInt = "int"
  show (TFloatTuple n) = "vec" ++ show n
  show (TArray n elementTy) = show elementTy ++ "[" ++ show n ++ "]"

public export
data Storage = FragmentInput | Uniform

public export
Eq Storage where
  FragmentInput == FragmentInput = True
  Uniform == Uniform = True
  _ == _ = False

public export
record InterfaceVar where
  constructor MkInterfaceVar
  name : String
  storage : Storage
  valueTy : ValueTy

public export
record EntrySpec where
  constructor MkEntrySpec
  entryName : String
  entryInterface : List InterfaceVar
  resultTy : ValueTy

||| A typed operand in the backend's shader IR.
public export
data Operand : ValueTy -> Type where
  OLocal : String -> Operand ty
  OFloat : Double -> Operand TFloat
  OBool : Bool -> Operand TBool

public export
record SomeOperand where
  constructor PackOperand
  operandTy : ValueTy
  operand : Operand operandTy

public export
record SomeFloatTuple where
  constructor PackFloatTuple
  width : Nat
  components : Operand (TFloatTuple width)

public export
record SomeArray where
  constructor PackArray
  length : Nat
  elementTy : ArrayElementTy
  array : Operand (TArray length elementTy)

public export
data FloatUnary =
    FNeg
  | FAbs
  | FSqrt
  | FSin
  | FCos
  | FFloor
  | FFract
  | FLog

public export
data FloatBinary =
    FAdd
  | FSub
  | FMul
  | FDiv
  | FMin
  | FMax
  | FAtan2
  | FPow

public export
data FloatTernary = FClamp | FMix | FSmoothstep

public export
data Comparison = FLt | FLe | FEq | FGe | FGt

public export
data BoolUnary = BNot

public export
data BoolBinary = BAnd | BOr

public export
data ComponentBinaryOperation = AddComponents | SubtractComponents

||| A right-hand side whose Idris index is its GLSL result type.
public export
data Rhs : ValueTy -> Type where
  RFloatUnary : FloatUnary -> Operand TFloat -> Rhs TFloat
  RFloatBinary : FloatBinary -> Operand TFloat -> Operand TFloat -> Rhs TFloat
  RFloatTernary : FloatTernary -> Operand TFloat -> Operand TFloat ->
                  Operand TFloat -> Rhs TFloat
  RComparison : Comparison -> Operand TFloat -> Operand TFloat -> Rhs TBool
  RBoolUnary : BoolUnary -> Operand TBool -> Rhs TBool
  RBoolBinary : BoolBinary -> Operand TBool -> Operand TBool -> Rhs TBool
  RIntToFloat : Operand TInt -> Rhs TFloat
  RArrayIndex : (capacity : Nat) -> Operand (TArray capacity elementTy) ->
                Operand TFloat -> Rhs (arrayElementValueTy elementTy)
  RFloatTuple2 : Operand TFloat -> Operand TFloat -> Rhs (TFloatTuple 2)
  RFloatTuple3 : Operand TFloat -> Operand TFloat -> Operand TFloat -> Rhs (TFloatTuple 3)
  RFloatTuple4 : Operand TFloat -> Operand TFloat -> Operand TFloat ->
          Operand TFloat -> Rhs (TFloatTuple 4)
  RComponentBinary : ComponentBinaryOperation -> Operand (TFloatTuple n) -> Operand (TFloatTuple n) ->
                  Rhs (TFloatTuple n)
  RScaleComponents : Operand TFloat -> Operand (TFloatTuple n) -> Rhs (TFloatTuple n)
  RComponentProductSum : Operand (TFloatTuple n) -> Operand (TFloatTuple n) -> Rhs TFloat
  REuclideanComponentNorm : Operand (TFloatTuple n) -> Rhs TFloat
  RNormalizeComponentsUnchecked : Operand (TFloatTuple n) -> Rhs (TFloatTuple n)
  RComponent : Fin n -> Operand (TFloatTuple n) -> Rhs TFloat
  RSelect : Operand TBool -> Operand ty -> Operand ty -> Rhs ty

public export
record Binding where
  constructor MkBinding
  bindingTy : ValueTy
  bindingName : String
  bindingRhs : Rhs bindingTy

||| Structured statements are part of the checked shader IR. Source control
||| flow is preserved before target code generation instead of being flattened
||| into eagerly computed values and rediscovered later.
public export
data Statement : Type where
  SBinding : Binding -> Statement
  SIf : (resultTy : ValueTy) ->
        (resultName : String) ->
        Operand TBool ->
        List Statement -> Operand resultTy ->
        List Statement -> Operand resultTy ->
        Statement
  SBoundedLoop : (stateTy : ValueTy) ->
                 (resultName : String) ->
                 (indexName : String) ->
                 (stateName : String) ->
                 (maximumIterations : Nat) ->
                 Maybe (Operand TFloat) ->
                 Operand stateTy ->
                 List Statement -> Operand stateTy ->
                 Statement

public export
record FragmentProgram where
  constructor MkFragmentProgram
  spec : EntrySpec
  statements : List Statement
  result : Operand (TFloatTuple 4)

public export
expect : (wanted : ValueTy) -> SomeOperand -> Either String (Operand wanted)
expect wanted (PackOperand actual value) with (decEq wanted actual)
  expect wanted (PackOperand wanted value) | Yes Refl = Right value
  expect wanted (PackOperand actual value) | No _ =
    Left ("expected " ++ show wanted ++ ", received " ++ show actual)

public export
expectFloatTuple : SomeOperand -> Either String SomeFloatTuple
expectFloatTuple (PackOperand (TFloatTuple n) value) = Right (PackFloatTuple n value)
expectFloatTuple (PackOperand actual _) =
  Left ("expected a floating component tuple, received " ++ show actual)

public export
expectArray : SomeOperand -> Either String SomeArray
expectArray (PackOperand (TArray n elementTy) value) =
  Right (PackArray n elementTy value)
expectArray (PackOperand actual _) =
  Left ("expected a fixed array, received " ++ show actual)
