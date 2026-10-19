module Backend.GLSLES.Bounded

import Compiler.ANF
import Core.Name
import Core.TT
import Data.List
import Data.String
import Data.Vect

%default covering

Bindings : Type
Bindings = List (Int, Administrative_Normal_Form)

public export
record BoundedLoopShape where
  constructor MkBoundedLoopShape
  loopParameters : List Int
  loopIndexParameter : Int
  loopStateParameter : Int
  loopActiveParameter : Int
  loopMaximum : Nat
  loopBody : Administrative_Normal_Form

peelLets : Administrative_Normal_Form -> (Bindings, Administrative_Normal_Form)
peelLets (Administrative_Normal_Form_Binding _ variable value scope) =
  let (rest, terminal) = peelLets scope
   in ((variable, value) :: rest, terminal)
peelLets expression = ([], expression)

lookupBinding : Int -> Bindings -> Maybe Administrative_Normal_Form
lookupBinding _ [] = Nothing
lookupBinding wanted ((variable, value) :: rest) =
  if wanted == variable then Just value else lookupBinding wanted rest

localNumber : Administrative_Normal_Form_Variable -> Maybe Int
localNumber (Administrative_Normal_Form_Local_Variable variable) = Just variable
localNumber Administrative_Normal_Form_Erased_Variable = Nothing

floatConstant : Bindings -> Administrative_Normal_Form_Variable -> Maybe Double
floatConstant bindings (Administrative_Normal_Form_Local_Variable variable) = do
  expression <- lookupBinding variable bindings
  case expression of
    Administrative_Normal_Form_Primitive_Value _ (Db value) => Just value
    Administrative_Normal_Form_Variable_Expression _ alias => floatConstant bindings alias
    _ => Nothing
floatConstant _ Administrative_Normal_Form_Erased_Variable = Nothing

naturalBound : Double -> Maybe Nat
naturalBound value =
  if value <= 0.0
     then Nothing
     else
       let candidate : Nat = cast value
        in if the Double (cast candidate) == value
              then Just candidate
              else Nothing

matchMinBound : Administrative_Normal_Form -> Maybe (Int, Nat)
matchMinBound expression =
  let (bindings, terminal) = peelLets expression in
  case terminal of
    Administrative_Normal_Form_External_Primitive _ _ primitive [left, right] =>
      if nameRoot primitive == "minF"
         then case (floatConstant bindings left, floatConstant bindings right) of
                (Nothing, Just maximum) => do
                  active <- localNumber left
                  bound <- naturalBound maximum
                  Just (active, bound)
                (Just maximum, Nothing) => do
                  active <- localNumber right
                  bound <- naturalBound maximum
                  Just (active, bound)
                _ => Nothing
         else Nothing
    _ => Nothing

boundExpression : Bindings -> Administrative_Normal_Form_Variable -> Maybe Administrative_Normal_Form
boundExpression bindings (Administrative_Normal_Form_Local_Variable variable) = lookupBinding variable bindings
boundExpression _ Administrative_Normal_Form_Erased_Variable = Nothing

||| Interface-method names may reach Administrative_Normal_Form wrapped in a display-name constructor.
||| `nameRoot` intentionally ignores that display spelling, so accept the
||| canonical qualified spelling as well as an ordinary root name.
isLessThanName : Name -> Bool
isLessThanName name =
  nameRoot name == "<" || show name == "<" || isSuffixOf ".<" (show name)

matchLessThan : Administrative_Normal_Form -> Maybe (Int, Int, Nat)
matchLessThan expression =
  let (bindings, terminal) = peelLets expression in
  case terminal of
    Administrative_Normal_Form_Named_Function_Application _ _ comparison [index, bound] =>
      if isLessThanName comparison
         then do
           indexParameter <- localNumber index
           boundValue <- boundExpression bindings bound
           (activeParameter, maximum) <- matchMinBound boundValue
           Just (indexParameter, activeParameter, maximum)
         else Nothing
    Administrative_Normal_Form_Primitive_Operation _ _ (LT DoubleType) arguments =>
      case toList arguments of
        [index, bound] => do
          indexParameter <- localNumber index
          boundValue <- boundExpression bindings bound
          (activeParameter, maximum) <- matchMinBound boundValue
          Just (indexParameter, activeParameter, maximum)
        _ => Nothing
    _ => Nothing

boolConstant : Constant -> Maybe Bool
boolConstant (I 0) = Just False
boolConstant (I 1) = Just True
boolConstant (I8 0) = Just False
boolConstant (I8 1) = Just True
boolConstant (I16 0) = Just False
boolConstant (I16 1) = Just True
boolConstant (I32 0) = Just False
boolConstant (I32 1) = Just True
boolConstant (I64 0) = Just False
boolConstant (I64 1) = Just True
boolConstant (BI 0) = Just False
boolConstant (BI 1) = Just True
boolConstant (B8 0) = Just False
boolConstant (B8 1) = Just True
boolConstant (B16 0) = Just False
boolConstant (B16 1) = Just True
boolConstant (B32 0) = Just False
boolConstant (B32 1) = Just True
boolConstant (B64 0) = Just False
boolConstant (B64 1) = Just True
boolConstant _ = Nothing

findConstBranch : Bool -> List Administrative_Normal_Form_Constant_Alternative -> Maybe Administrative_Normal_Form
findConstBranch _ [] = Nothing
findConstBranch wanted (Make_Administrative_Normal_Form_Constant_Alternative constant body :: rest) =
  case boolConstant constant of
    Just actual => if wanted == actual then Just body else findConstBranch wanted rest
    Nothing => findConstBranch wanted rest

findConBranch : Bool -> List Administrative_Normal_Form_Constructor_Alternative -> Maybe Administrative_Normal_Form
findConBranch _ [] = Nothing
findConBranch wanted (Make_Administrative_Normal_Form_Constructor_Alternative name _ _ _ body :: rest) =
  case nameRoot name of
    "False" => if not wanted then Just body else findConBranch wanted rest
    "True" => if wanted then Just body else findConBranch wanted rest
    _ => findConBranch wanted rest

matchCase : Administrative_Normal_Form -> Maybe (Administrative_Normal_Form, Administrative_Normal_Form, Administrative_Normal_Form)
matchCase expression =
  let (bindings, terminal) = peelLets expression in
  case terminal of
    Administrative_Normal_Form_Constant_Case _ scrutinee alternatives defaultBranch => do
      condition <- boundExpression bindings scrutinee
      let falseBranch = case findConstBranch False alternatives of
                             Just body => Just body
                             Nothing => defaultBranch
      let trueBranch = case findConstBranch True alternatives of
                            Just body => Just body
                            Nothing => defaultBranch
      falseBody <- falseBranch
      trueBody <- trueBranch
      Just (condition, trueBody, falseBody)
    Administrative_Normal_Form_Constructor_Case _ scrutinee alternatives defaultBranch => do
      condition <- boundExpression bindings scrutinee
      let falseBranch = case findConBranch False alternatives of
                             Just body => Just body
                             Nothing => defaultBranch
      let trueBranch = case findConBranch True alternatives of
                            Just body => Just body
                            Nothing => defaultBranch
      falseBody <- falseBranch
      trueBody <- trueBranch
      Just (condition, trueBody, falseBody)
    _ => Nothing

stateReturn : Administrative_Normal_Form -> Maybe Int
stateReturn (Administrative_Normal_Form_Variable_Expression _ (Administrative_Normal_Form_Local_Variable variable)) = Just variable
stateReturn _ = Nothing

argumentFor : Int -> List Int -> List Administrative_Normal_Form_Variable -> Maybe Administrative_Normal_Form_Variable
argumentFor _ [] [] = Nothing
argumentFor wanted (parameter :: params) (argument :: arguments) =
  if wanted == parameter
     then Just argument
     else argumentFor wanted params arguments
argumentFor _ _ _ = Nothing

sameInvariantArguments : Int -> Int -> List Int -> List Administrative_Normal_Form_Variable -> Bool
sameInvariantArguments _ _ [] [] = True
sameInvariantArguments indexParameter stateParameter
                       (parameter :: params) (argument :: arguments) =
  let current =
        if parameter == indexParameter || parameter == stateParameter
           then True
           else argument == Administrative_Normal_Form_Local_Variable parameter
   in current &&
      sameInvariantArguments indexParameter stateParameter params arguments
sameInvariantArguments _ _ _ _ = False

isOne : Bindings -> Administrative_Normal_Form_Variable -> Bool
isOne bindings variable = case floatConstant bindings variable of
  Just value => value == 1.0
  Nothing => False

matchIncrement : Int -> Bindings -> Administrative_Normal_Form_Variable -> Bool
matchIncrement indexParameter bindings (Administrative_Normal_Form_Local_Variable variable) =
  case lookupBinding variable bindings of
    Nothing => False
    Just expression =>
      let (innerBindings, terminal) = peelLets expression in
      case terminal of
        Administrative_Normal_Form_Primitive_Operation _ _ (Add DoubleType) arguments =>
          case toList arguments of
            [left, right] =>
              (left == Administrative_Normal_Form_Local_Variable indexParameter && isOne innerBindings right) ||
              (right == Administrative_Normal_Form_Local_Variable indexParameter && isOne innerBindings left)
            _ => False
        _ => False
matchIncrement _ _ Administrative_Normal_Form_Erased_Variable = False

public export
matchBoundedLoop : Name -> Administrative_Normal_Form_Definition -> Maybe BoundedLoopShape
matchBoundedLoop self (Make_Administrative_Normal_Form_Function params body) = do
  (condition, trueBody, falseBody) <- matchCase body
  (indexParameter, activeParameter, maximum) <- matchLessThan condition
  stateParameter <- stateReturn falseBody
  if indexParameter == stateParameter ||
     indexParameter == activeParameter ||
     stateParameter == activeParameter ||
     not (elem indexParameter params) ||
     not (elem stateParameter params) ||
     not (elem activeParameter params)
     then Nothing
     else pure ()
  let (bodyBindings, terminal) = peelLets trueBody
  recursiveArguments <- case terminal of
    Administrative_Normal_Form_Named_Function_Application _ _ called arguments =>
      if called == self then Just arguments else Nothing
    _ => Nothing
  if sameInvariantArguments indexParameter stateParameter params recursiveArguments
     then pure ()
     else Nothing
  nextIndex <- argumentFor indexParameter params recursiveArguments
  if matchIncrement indexParameter bodyBindings nextIndex
     then pure ()
     else Nothing
  Just (MkBoundedLoopShape params indexParameter stateParameter
                           activeParameter maximum trueBody)
matchBoundedLoop _ _ = Nothing
