module Backend.GLSLES.Lower

import Backend.GLSLES.Bounded
import Backend.GLSLES.IR
import Compiler.ANF
import Core.Name
import Core.TT
import Data.Fin
import Data.List
import Data.Vect
import Decidable.Equality

%default covering

Env : Type
Env = List (Int, SomeOperand)

public export
ShaderDefs : Type
ShaderDefs = List (Name, Administrative_Normal_Form_Definition)

record LowerState where
  constructor MkLowerState
  nextTemp : Nat
  reversedStatements : List Statement

record Lower a where
  constructor MkLower
  runLower : LowerState -> Either String (LowerState, a)

Functor Lower where
  map function (MkLower action) = MkLower $ \state => do
    (state', value) <- action state
    Right (state', function value)

Applicative Lower where
  pure value = MkLower $ \state => Right (state, value)
  (MkLower function) <*> (MkLower argument) = MkLower $ \state => do
    (state', f) <- function state
    (state'', value) <- argument state'
    Right (state'', f value)

Monad Lower where
  (MkLower action) >>= continuation = MkLower $ \state => do
    (state', value) <- action state
    runLower (continuation value) state'

failLower : String -> Lower a
failLower message = MkLower $ \_ => Left message

liftEither : Either String a -> Lower a
liftEither (Left message) = failLower message
liftEither (Right value) = pure value

emit : {ty : ValueTy} -> Rhs ty -> Lower (Operand ty)
emit {ty} rhs = MkLower $ \state =>
  let name = "_idris_t" ++ show (nextTemp state)
      binding = MkBinding ty name rhs
      state' = MkLowerState (S (nextTemp state))
                            (SBinding binding :: reversedStatements state)
   in Right (state', OLocal name)

lookupLocal : Int -> Env -> Either String SomeOperand
lookupLocal variable [] = Left ("unbound Administrative_Normal_Form local v" ++ show variable)
lookupLocal variable ((candidate, value) :: rest) =
  if variable == candidate then Right value else lookupLocal variable rest

resolveVar : Env -> Administrative_Normal_Form_Variable -> Either String SomeOperand
resolveVar _ Administrative_Normal_Form_Erased_Variable = Left "erased value used at runtime in shader code"
resolveVar env (Administrative_Normal_Form_Local_Variable variable) = lookupLocal variable env

resolveRuntimeArgs : Env -> List Administrative_Normal_Form_Variable -> Either String (List SomeOperand)
resolveRuntimeArgs _ [] = Right []
resolveRuntimeArgs env (Administrative_Normal_Form_Erased_Variable :: rest) = resolveRuntimeArgs env rest
resolveRuntimeArgs env (variable :: rest) = do
  value <- resolveVar env variable
  values <- resolveRuntimeArgs env rest
  Right (value :: values)

expectFloat : SomeOperand -> Either String (Operand TFloat)
expectFloat = expect TFloat

expectBool : SomeOperand -> Either String (Operand TBool)
expectBool = expect TBool

expectInt : SomeOperand -> Either String (Operand TInt)
expectInt = expect TInt

record FloatTuplePair where
  constructor PackFloatTuplePair
  pairWidth : Nat
  leftComponents : Operand (TFloatTuple pairWidth)
  rightComponents : Operand (TFloatTuple pairWidth)

matchingFloatTuples : SomeOperand -> SomeOperand -> Either String FloatTuplePair
matchingFloatTuples left right = do
  PackFloatTuple n left' <- expectFloatTuple left
  PackFloatTuple m right' <- expectFloatTuple right
  case decEq n m of
    Yes Refl => Right (PackFloatTuplePair n left' right')
    No _ => Left ("component count mismatch: tuple" ++ show n ++ " and tuple" ++ show m)

one : String -> List SomeOperand -> Either String SomeOperand
one _ [value] = Right value
one operation values =
  Left (operation ++ " expects one runtime argument, received " ++ show (length values))

two : String -> List SomeOperand -> Either String (SomeOperand, SomeOperand)
two _ [left, right] = Right (left, right)
two operation values =
  Left (operation ++ " expects two runtime arguments, received " ++ show (length values))

three : String -> List SomeOperand ->
        Either String (SomeOperand, SomeOperand, SomeOperand)
three _ [first, second, third] = Right (first, second, third)
three operation values =
  Left (operation ++ " expects three runtime arguments, received " ++ show (length values))

four : String -> List SomeOperand ->
       Either String (SomeOperand, SomeOperand, SomeOperand, SomeOperand)
four _ [first, second, third, fourth] = Right (first, second, third, fourth)
four operation values =
  Left (operation ++ " expects four runtime arguments, received " ++ show (length values))

floatUnary : String -> FloatUnary -> List SomeOperand -> Lower SomeOperand
floatUnary operation constructor values = do
  value <- liftEither (one operation values >>= expectFloat)
  result <- emit (RFloatUnary constructor value)
  pure (PackOperand TFloat result)

floatBinary : String -> FloatBinary -> List SomeOperand -> Lower SomeOperand
floatBinary operation constructor values = do
  (left, right) <- liftEither (two operation values)
  left' <- liftEither (expectFloat left)
  right' <- liftEither (expectFloat right)
  result <- emit (RFloatBinary constructor left' right')
  pure (PackOperand TFloat result)

floatTernary : String -> FloatTernary -> List SomeOperand -> Lower SomeOperand
floatTernary operation constructor values = do
  (first, second, third) <- liftEither (three operation values)
  first' <- liftEither (expectFloat first)
  second' <- liftEither (expectFloat second)
  third' <- liftEither (expectFloat third)
  result <- emit (RFloatTernary constructor first' second' third')
  pure (PackOperand TFloat result)

comparison : String -> Comparison -> List SomeOperand -> Lower SomeOperand
comparison operation constructor values = do
  (left, right) <- liftEither (two operation values)
  left' <- liftEither (expectFloat left)
  right' <- liftEither (expectFloat right)
  result <- emit (RComparison constructor left' right')
  pure (PackOperand TBool result)

intToFloat : List SomeOperand -> Lower SomeOperand
intToFloat values = do
  value <- liftEither (one "int_to_double" values >>= expectInt)
  result <- emit (RIntToFloat value)
  pure (PackOperand TFloat result)

arrayIndex : List SomeOperand -> Lower SomeOperand
arrayIndex values = do
  (arrayValue, indexValue) <- liftEither (two "array_at" values)
  PackArray n elementTy array <- liftEither (expectArray arrayValue)
  index <- liftEither (expectFloat indexValue)
  result <- emit (RArrayIndex n array index)
  pure (PackOperand (arrayElementValueTy elementTy) result)

lowerPrim : Env -> PrimFn arity -> List Administrative_Normal_Form_Variable -> Lower SomeOperand
lowerPrim env primitive arguments = do
  values <- liftEither (resolveRuntimeArgs env arguments)
  case primitive of
    Add DoubleType => floatBinary "+" FAdd values
    Sub DoubleType => floatBinary "-" FSub values
    Mul DoubleType => floatBinary "*" FMul values
    Div DoubleType => floatBinary "/" FDiv values
    Neg DoubleType => floatUnary "negate" FNeg values
    LT DoubleType => comparison "<" FLt values
    LTE DoubleType => comparison "<=" FLe values
    EQ DoubleType => comparison "==" FEq values
    GTE DoubleType => comparison ">=" FGe values
    GT DoubleType => comparison ">" FGt values
    DoubleSin => floatUnary "sin" FSin values
    DoubleCos => floatUnary "cos" FCos values
    DoubleSqrt => floatUnary "sqrt" FSqrt values
    other => failLower ("unsupported Idris primitive in shader: " ++ show other)

component : String -> Nat -> List SomeOperand -> Lower SomeOperand
component operation index values = do
  value <- liftEither (one operation values)
  PackFloatTuple n vector <- liftEither (expectFloatTuple value)
  Just position <- pure (natToFin index n)
    | Nothing => failLower (operation ++ " is invalid for vec" ++ show n)
  result <- emit (RComponent position vector)
  pure (PackOperand TFloat result)

floatTupleConstructor2 : List SomeOperand -> Lower SomeOperand
floatTupleConstructor2 values = do
  (x, y) <- liftEither (two "vec2" values)
  x' <- liftEither (expectFloat x)
  y' <- liftEither (expectFloat y)
  result <- emit (RFloatTuple2 x' y')
  pure (PackOperand (TFloatTuple 2) result)

floatTupleConstructor3 : List SomeOperand -> Lower SomeOperand
floatTupleConstructor3 values = do
  (x, y, z) <- liftEither (three "vec3" values)
  x' <- liftEither (expectFloat x)
  y' <- liftEither (expectFloat y)
  z' <- liftEither (expectFloat z)
  result <- emit (RFloatTuple3 x' y' z')
  pure (PackOperand (TFloatTuple 3) result)

floatTupleConstructor4 : List SomeOperand -> Lower SomeOperand
floatTupleConstructor4 values = do
  (x, y, z, w) <- liftEither (four "vec4" values)
  x' <- liftEither (expectFloat x)
  y' <- liftEither (expectFloat y)
  z' <- liftEither (expectFloat z)
  w' <- liftEither (expectFloat w)
  result <- emit (RFloatTuple4 x' y' z' w')
  pure (PackOperand (TFloatTuple 4) result)

componentBinaryOperation : String -> ComponentBinaryOperation -> List SomeOperand -> Lower SomeOperand
componentBinaryOperation operation constructor values = do
  (left, right) <- liftEither (two operation values)
  PackFloatTuplePair n left' right' <- liftEither (matchingFloatTuples left right)
  result <- emit (RComponentBinary constructor left' right')
  pure (PackOperand (TFloatTuple n) result)

scaleComponents : List SomeOperand -> Lower SomeOperand
scaleComponents values = do
  (scalar, vector) <- liftEither (two "scale_components" values)
  scalar' <- liftEither (expectFloat scalar)
  PackFloatTuple n vector' <- liftEither (expectFloatTuple vector)
  result <- emit (RScaleComponents scalar' vector')
  pure (PackOperand (TFloatTuple n) result)

componentProductSum : List SomeOperand -> Lower SomeOperand
componentProductSum values = do
  (left, right) <- liftEither (two "component_product_sum" values)
  PackFloatTuplePair _ left' right' <- liftEither (matchingFloatTuples left right)
  result <- emit (RComponentProductSum left' right')
  pure (PackOperand TFloat result)

euclideanComponentNorm : List SomeOperand -> Lower SomeOperand
euclideanComponentNorm values = do
  value <- liftEither (one "euclidean_component_norm" values)
  PackFloatTuple _ vector <- liftEither (expectFloatTuple value)
  result <- emit (REuclideanComponentNorm vector)
  pure (PackOperand TFloat result)

normalizeComponentsUnchecked : List SomeOperand -> Lower SomeOperand
normalizeComponentsUnchecked values = do
  value <- liftEither (one "normalize_components_unchecked" values)
  PackFloatTuple n vector <- liftEither (expectFloatTuple value)
  result <- emit (RNormalizeComponentsUnchecked vector)
  pure (PackOperand (TFloatTuple n) result)

coordinatePairing : List SomeOperand -> Lower SomeOperand
coordinatePairing values = do
  (covectorValue, vectorValue) <- liftEither (two "coordinate_pairing" values)
  PackArray dimension AFloat covector <- liftEither (expectArray covectorValue)
    | _ => failLower "coordinate pairing requires scalar coordinate arrays"
  vector <- liftEither (expect (TArray dimension AFloat) vectorValue)
  reduceCoordinates dimension dimension 0 covector vector (OFloat 0.0)
  where
    reduceCoordinates : (dimension : Nat) -> (remaining : Nat) -> Nat ->
      Operand (TArray dimension AFloat) -> Operand (TArray dimension AFloat) ->
      Operand TFloat -> Lower SomeOperand
    reduceCoordinates _ Z _ _ _ accumulated = pure (PackOperand TFloat accumulated)
    reduceCoordinates dimension (S remaining) coordinateIndex covector vector accumulated = do
      let index = OFloat (cast coordinateIndex)
      coefficient <- emit (RArrayIndex dimension covector index)
      coordinate <- emit (RArrayIndex dimension vector index)
      product <- emit (RFloatBinary FMul coefficient coordinate)
      next <- emit (RFloatBinary FAdd accumulated product)
      reduceCoordinates dimension remaining (S coordinateIndex) covector vector next

lowerExtPrim : Env -> Name -> List Administrative_Normal_Form_Variable -> Lower SomeOperand
lowerExtPrim env primitive arguments = do
  values <- liftEither (resolveRuntimeArgs env arguments)
  let primitiveName = nameRoot primitive
  if show primitive /= "Shader.Source." ++ primitiveName &&
     show primitive /= "Shader.Coordinates." ++ primitiveName
    then failLower ("external primitive is not a canonical shader declaration: " ++ show primitive)
    else pure ()
  case nameRoot primitive of
    "coordinate_pairing" => coordinatePairing values
    "array_at" => arrayIndex values
    "int_to_double" => intToFloat values
    "vec2" => floatTupleConstructor2 values
    "vec3" => floatTupleConstructor3 values
    "vec4" => floatTupleConstructor4 values
    "x" => component "x" 0 values
    "y" => component "y" 1 values
    "z" => component "z" 2 values
    "w" => component "w" 3 values
    "add_components" => componentBinaryOperation "add_components" AddComponents values
    "subtract_components" => componentBinaryOperation "subtract_components" SubtractComponents values
    "scale_components" => scaleComponents values
    "component_product_sum" => componentProductSum values
    "euclidean_component_norm" => euclideanComponentNorm values
    "normalize_components_unchecked" => normalizeComponentsUnchecked values
    "absF" => floatUnary "absF" FAbs values
    "sqrtF" => floatUnary "sqrtF" FSqrt values
    "sinF" => floatUnary "sinF" FSin values
    "cosF" => floatUnary "cosF" FCos values
    "floorF" => floatUnary "floorF" FFloor values
    "fractF" => floatUnary "fractF" FFract values
    "logF" => floatUnary "logF" FLog values
    "expF" => floatUnary "expF" FExp values
    "minF" => floatBinary "minF" FMin values
    "maxF" => floatBinary "maxF" FMax values
    "atan2F" => floatBinary "atan2F" FAtan2 values
    "powF" => floatBinary "powF" FPow values
    "clampF" => floatTernary "clampF" FClamp values
    "mixF" => floatTernary "mixF" FMix values
    "smoothstepF" => floatTernary "smoothstepF" FSmoothstep values
    other => failLower ("unsupported external primitive in shader: " ++ show primitive)

findDef : Name -> ShaderDefs -> Maybe Administrative_Normal_Form_Definition
findDef _ [] = Nothing
findDef wanted ((name, definition) :: rest) =
  if wanted == name then Just definition else findDef wanted rest

bindArguments : List Int -> List SomeOperand -> Either String Env
bindArguments [] [] = Right []
bindArguments (parameter :: params) (value :: values) = do
  rest <- bindArguments params values
  Right ((parameter, value) :: rest)
bindArguments params values =
  Left ("function expected " ++ show (length params) ++
        " runtime arguments, received " ++ show (length values))

argumentForParameter : Int -> List Int -> List Administrative_Normal_Form_Variable -> Maybe Administrative_Normal_Form_Variable
argumentForParameter _ [] [] = Nothing
argumentForParameter wanted (parameter :: params) (argument :: arguments) =
  if wanted == parameter
     then Just argument
     else argumentForParameter wanted params arguments
argumentForParameter _ _ _ = Nothing

startsAtZero : Operand TFloat -> Bool
startsAtZero (OFloat value) = value == 0.0
startsAtZero _ = False

loopStateAllowed : ValueTy -> Bool
loopStateAllowed (TArray _ _) = False
loopStateAllowed _ = True

arrayAccessSafe : Nat -> String -> Rhs ty -> Bool
arrayAccessSafe maximum indexName (RArrayIndex capacity _ index) =
  case index of
    OLocal name => name == indexName && maximum <= capacity
    _ => False
arrayAccessSafe _ _ _ = True

statementArraysSafe : Nat -> String -> Statement -> Bool
statementArraysSafe maximum indexName (SBinding (MkBinding _ _ rhs)) =
  arrayAccessSafe maximum indexName rhs
statementArraysSafe maximum indexName
                    (SIf _ _ _ thenStatements _ elseStatements _) =
  all (statementArraysSafe maximum indexName) thenStatements &&
  all (statementArraysSafe maximum indexName) elseStatements
statementArraysSafe _ _ (SBoundedLoop _ _ _ _ _ _ _ _ _) = False

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

mutual
  lowerLoopBody : ShaderDefs -> List Name -> Env -> Name ->
                  List Int -> Int -> Administrative_Normal_Form -> Lower SomeOperand
  lowerLoopBody definitions stack env self params stateParameter
                (Administrative_Normal_Form_Binding _ variable value scope) = do
    lowered <- lowerANF definitions stack env value
    lowerLoopBody definitions stack ((variable, lowered) :: env)
                  self params stateParameter scope
  lowerLoopBody _ _ env self params stateParameter
                (Administrative_Normal_Form_Named_Function_Application _ _ called arguments) =
    if called == self
       then case argumentForParameter stateParameter params arguments of
              Nothing => failLower "bounded loop recursion has no state argument"
              Just stateArgument => liftEither (resolveVar env stateArgument)
       else failLower ("bounded loop body ends in unexpected call: " ++ show called)
  lowerLoopBody _ _ _ self _ _ _ =
    failLower ("bounded loop body for " ++ show self ++
               " is outside the admitted tail-iteration source shape")

  lowerBoundedCall : ShaderDefs -> List Name -> Name -> BoundedLoopShape ->
                     Env -> Lower SomeOperand
  lowerBoundedCall definitions stack self shape callEnv = do
    indexValue <- liftEither (lookupLocal (loopIndexParameter shape) callEnv)
    index <- liftEither (expectFloat indexValue)
    if startsAtZero index
       then pure ()
       else failLower "bounded shader iteration must start at index 0"
    activeValue <- liftEither (lookupLocal (loopActiveParameter shape) callEnv)
    active <- liftEither (expectFloat activeValue)
    stateValue <- liftEither (lookupLocal (loopStateParameter shape) callEnv)
    case stateValue of
      PackOperand stateTy initialState =>
        if not (loopStateAllowed stateTy)
           then failLower "bounded shader iteration cannot carry an array as loop state"
           else MkLower $ \state => do
             let resultName = "_idris_t" ++ show (nextTemp state)
                 indexName = resultName ++ "_index_value"
                 stateName = resultName ++ "_state"
                 bodyEnv =
                   ( loopIndexParameter shape
                   , PackOperand TFloat (OLocal indexName)
                   ) ::
                   ( loopStateParameter shape
                   , PackOperand stateTy (OLocal stateName)
                   ) :: callEnv
                 bodyStart = MkLowerState (S (nextTemp state)) []
             (bodyState, bodyValue) <-
               runLower
                 (lowerLoopBody definitions (self :: stack) bodyEnv self
                                (loopParameters shape) (loopStateParameter shape)
                                (loopBody shape))
                 bodyStart
             bodyResult <- expect stateTy bodyValue
             let bodyStatements = reverse (reversedStatements bodyState)
             if all (statementArraysSafe (loopMaximum shape) indexName)
                    bodyStatements
                then
                  let statement =
                        SBoundedLoop stateTy resultName indexName stateName
                          (loopMaximum shape) (Just active) initialState
                          bodyStatements bodyResult
                      final =
                        MkLowerState (nextTemp bodyState)
                                     (statement :: reversedStatements state)
                   in Right (final, PackOperand stateTy (OLocal resultName))
                else Left ("bounded loop array access is not proven within " ++
                           show (loopMaximum shape) ++ " elements")

  lowerCall : ShaderDefs -> List Name -> Env -> Name -> List Administrative_Normal_Form_Variable -> Lower SomeOperand
  lowerCall definitions stack env name arguments = do
    if elem name stack
       then failLower ("recursive shader call is not supported: " ++ show name)
       else pure ()
    values <- liftEither (resolveRuntimeArgs env arguments)
    Just definition <- pure (findDef name definitions)
      | Nothing => failLower ("shader calls unknown definition " ++ show name)
    case definition of
      Make_Administrative_Normal_Form_Function params body => do
        callEnv <- liftEither (bindArguments params values)
        case matchBoundedLoop name definition of
          Just shape => lowerBoundedCall definitions stack name shape callEnv
          Nothing => lowerANF definitions (name :: stack) callEnv body
      _ => failLower ("shader call does not name a first-order function: " ++ show name)

  lowerStructuredCase : ShaderDefs -> List Name -> Env -> Operand TBool ->
                        Administrative_Normal_Form -> Administrative_Normal_Form -> Lower SomeOperand
  lowerStructuredCase definitions stack env condition trueBody falseBody =
    MkLower $ \state => do
      let resultName = "_idris_t" ++ show (nextTemp state)
          branchStart = MkLowerState (S (nextTemp state)) []
      (falseState, falseValue) <-
        runLower (lowerANF definitions stack env falseBody) branchStart
      let trueStart = MkLowerState (nextTemp falseState) []
      (trueState, trueValue) <-
        runLower (lowerANF definitions stack env trueBody) trueStart
      case (trueValue, falseValue) of
        (PackOperand trueTy trueResult, PackOperand falseTy falseResult) =>
          case decEq trueTy falseTy of
            No _ => Left ("case branches have different shader types: " ++
                          show trueTy ++ " and " ++ show falseTy)
            Yes Refl =>
              let statement =
                    SIf trueTy resultName condition
                      (reverse (reversedStatements trueState)) trueResult
                      (reverse (reversedStatements falseState)) falseResult
                  final = MkLowerState (nextTemp trueState)
                                       (statement :: reversedStatements state)
               in Right (final, PackOperand trueTy (OLocal resultName))

  lowerConstCase : ShaderDefs -> List Name -> Env -> Administrative_Normal_Form_Variable ->
                   List Administrative_Normal_Form_Constant_Alternative -> Maybe Administrative_Normal_Form -> Lower SomeOperand
  lowerConstCase definitions stack env scrutinee alternatives defaultBranch = do
    conditionValue <- liftEither (resolveVar env scrutinee)
    condition <- liftEither (expectBool conditionValue)
    let falseBranch = case findConstBranch False alternatives of
                           Just body => Just body
                           Nothing => defaultBranch
    let trueBranch = case findConstBranch True alternatives of
                          Just body => Just body
                          Nothing => defaultBranch
    Just falseBody <- pure falseBranch
      | Nothing => failLower "boolean case has no false/default branch"
    Just trueBody <- pure trueBranch
      | Nothing => failLower "boolean case has no true/default branch"
    lowerStructuredCase definitions stack env condition trueBody falseBody

  lowerConCase : ShaderDefs -> List Name -> Env -> Administrative_Normal_Form_Variable ->
                 List Administrative_Normal_Form_Constructor_Alternative -> Maybe Administrative_Normal_Form -> Lower SomeOperand
  lowerConCase definitions stack env scrutinee alternatives defaultBranch = do
    conditionValue <- liftEither (resolveVar env scrutinee)
    condition <- liftEither (expectBool conditionValue)
    let falseBranch = case findConBranch False alternatives of
                           Just body => Just body
                           Nothing => defaultBranch
    let trueBranch = case findConBranch True alternatives of
                          Just body => Just body
                          Nothing => defaultBranch
    Just falseBody <- pure falseBranch
      | Nothing => failLower "boolean case has no false/default branch"
    Just trueBody <- pure trueBranch
      | Nothing => failLower "boolean case has no true/default branch"
    lowerStructuredCase definitions stack env condition trueBody falseBody

  lowerANF : ShaderDefs -> List Name -> Env -> Administrative_Normal_Form -> Lower SomeOperand
  lowerANF _ _ env (Administrative_Normal_Form_Variable_Expression _ variable) = liftEither (resolveVar env variable)
  lowerANF _ _ _ (Administrative_Normal_Form_Primitive_Value _ (Db value)) = pure (PackOperand TFloat (OFloat value))
  lowerANF _ _ _ (Administrative_Normal_Form_Primitive_Value _ constant) =
    case boolConstant constant of
      Just value => pure (PackOperand TBool (OBool value))
      Nothing => failLower ("unsupported literal in shader: " ++ show constant)
  lowerANF definitions stack env (Administrative_Normal_Form_Binding _ variable value scope) = do
    lowered <- lowerANF definitions stack env value
    lowerANF definitions stack ((variable, lowered) :: env) scope
  lowerANF _ _ env (Administrative_Normal_Form_Primitive_Operation _ _ primitive arguments) =
    lowerPrim env primitive (toList arguments)
  lowerANF _ _ env (Administrative_Normal_Form_External_Primitive _ _ primitive arguments) =
    lowerExtPrim env primitive arguments
  lowerANF definitions stack env (Administrative_Normal_Form_Named_Function_Application _ _ name arguments) =
    lowerCall definitions stack env name arguments
  lowerANF definitions stack env (Administrative_Normal_Form_Constant_Case _ scrutinee alternatives defaultBranch) =
    lowerConstCase definitions stack env scrutinee alternatives defaultBranch
  lowerANF definitions stack env (Administrative_Normal_Form_Constructor_Case _ scrutinee alternatives defaultBranch) =
    lowerConCase definitions stack env scrutinee alternatives defaultBranch
  lowerANF _ _ _ (Administrative_Normal_Form_Constructor_Value _ name _ _ []) = case nameRoot name of
    "False" => pure (PackOperand TBool (OBool False))
    "True" => pure (PackOperand TBool (OBool True))
    _ => failLower ("heap-shaped constructor values are not supported in shaders: " ++ show name)
  lowerANF _ _ _ (Administrative_Normal_Form_Constructor_Value _ name _ _ _) =
    failLower ("heap-shaped constructor values are not supported in shaders: " ++ show name)
  lowerANF _ _ _ (Administrative_Normal_Form_Partial_Application _ name _ _) =
    failLower ("partial application is not supported in shaders: " ++ show name)
  lowerANF _ _ _ (Administrative_Normal_Form_Closure_Application _ _ _ _) =
    failLower "closure application is not supported in shaders"
  lowerANF _ _ _ (Administrative_Normal_Form_Erased_Value _) = failLower "erased value used as shader result"
  lowerANF _ _ _ (Administrative_Normal_Form_Crash _ message) = failLower ("shader contains a crash: " ++ message)

interfaceEnv : List Int -> List InterfaceVar -> Either String Env
interfaceEnv [] [] = Right []
interfaceEnv (parameter :: params) (MkInterfaceVar name _ ty :: variables) = do
  rest <- interfaceEnv params variables
  Right ((parameter, PackOperand ty (OLocal name)) :: rest)
interfaceEnv params variables =
  Left ("entry Administrative_Normal_Form has " ++ show (length params) ++
        " arguments, but its checked Idris signature has " ++ show (length variables))

public export
lowerFragment : EntrySpec -> Name -> ShaderDefs -> Administrative_Normal_Form_Definition ->
                Either String FragmentProgram
lowerFragment spec entryName definitions (Make_Administrative_Normal_Form_Function params body) = do
  env <- interfaceEnv params (entryInterface spec)
  let initial = MkLowerState 0 []
  (final, value) <- runLower (lowerANF definitions [entryName] env body) initial
  output <- expect (TFloatTuple 4) value
  Right (MkFragmentProgram spec (reverse (reversedStatements final)) output)
lowerFragment _ entryName _ _ =
  Left ("exported shader entry is not a function: " ++ show entryName)
