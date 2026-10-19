module Backend.NVIDIA.PTX

import Backend.GLSLES.IR
import Data.Fin
import Data.List
import Data.String

%default total

||| A deliberately bounded real compute follower of the checked shader IR.
||| All arithmetic is explicit F32 round-to-nearest, with no .ftz or FMA.
||| Input arrays contain one tightly packed vector per thread. Uniform scalars
||| are kernel parameters; output is four F32 values per thread.
public export
legalTarget : String -> Bool
legalTarget target = elem target ["sm_80", "sm_90", "sm_100", "sm_103"]

register : String -> String
register name = "%scalar_" ++ name

component : String -> Nat -> String
component name index = "%vector_" ++ name ++ "_" ++ show index

indices : Nat -> List Nat
indices Z = []
indices (S count) = 0 :: map S (indices count)

literal : Double -> Either String String
literal value =
  let text = show value in
  if elem text ["nan", "NaN", "inf", "Infinity", "-inf", "-Infinity"]
     then Left "PTX literal requires finite F32 conversion"
     else Right (if any (\c => c == '.' || c == 'e' || c == 'E') (unpack text)
                    then text else text ++ ".0")

scalar : Operand TFloat -> Either String String
scalar (OLocal name) = Right (register name)
scalar (OFloat value) = literal value

predicate : Operand TBool -> String
predicate (OLocal name) = register name
predicate (OBool value) = if value then "1" else "0"

vector : (width : Nat) -> Operand (TFloatTuple width) -> List String
vector width (OLocal name) = map (component name) (indices width)

declarations : ValueTy -> String -> Either String (List String)
declarations TFloat name = Right [".reg .f32 " ++ register name ++ ";"]
declarations TBool name = Right [".reg .pred " ++ register name ++ ", " ++ register name ++
                               "_yes, " ++ register name ++ "_no, " ++ register name ++ "_inverse;"]
declarations (TFloatTuple width) name =
  if elem width [2, 3, 4]
     then Right (map (\r => ".reg .f32 " ++ r ++ ";") (map (component name) (indices width)))
     else Left "PTX vector width must be 2, 3, or 4"
declarations _ _ = Left "PTX follower refuses integer and array values"

instruction : String -> String -> List String -> String
instruction opcode destination operands =
  "  " ++ opcode ++ " " ++ concat (intersperse ", " (destination :: operands)) ++ ";"

moveVector : String -> List String -> List String
moveVector name values = zipWith (\index, value => instruction "mov.f32" (component name index) [value])
                                 (indices (length values)) values

unary : FloatUnary -> Either String String
unary FNeg = Right "neg.f32"
unary FAbs = Right "abs.f32"
unary FSqrt = Right "sqrt.rn.f32"
unary _ = Left "PTX follower refuses transcendental/approximate unary operations"

binary : FloatBinary -> Either String String
binary FAdd = Right "add.rn.f32"
binary FSub = Right "sub.rn.f32"
binary FMul = Right "mul.rn.f32"
binary FDiv = Right "div.rn.f32"
binary FMin = Right "min.f32"
binary FMax = Right "max.f32"
binary _ = Left "PTX follower refuses transcendental/approximate binary operations"

comparison : Comparison -> String
comparison FLt = "lt"
comparison FLe = "le"
comparison FEq = "eq"
comparison FGe = "ge"
comparison FGt = "gt"

select : (ty : ValueTy) -> String -> Operand TBool -> Operand ty -> Operand ty ->
         Either String (List String)
select TFloat name condition first second = do
  a <- scalar first
  b <- scalar second
  Right [instruction "selp.f32" (register name) [a, b, predicate condition]]
select TBool name condition first second =
  Right [instruction "and.pred" (register name ++ "_yes") [predicate condition, predicate first],
         instruction "not.pred" (register name ++ "_inverse") [predicate condition],
         instruction "and.pred" (register name ++ "_no") [register name ++ "_inverse", predicate second],
         instruction "or.pred" (register name) [register name ++ "_yes", register name ++ "_no"]]
select (TFloatTuple width) name condition first second =
  Right (zipWith (\index, (a, b) => instruction "selp.f32" (component name index)
                    [a, b, predicate condition])
                 (indices width) (zip (vector width first) (vector width second)))
select _ _ _ _ _ = Left "PTX follower refuses non-floating selects"

rhs : (ty : ValueTy) -> String -> Rhs ty -> Either String (List String)
rhs _ name (RFloatUnary operation value) = do
  opcode <- unary operation
  input <- scalar value
  Right [instruction opcode (register name) [input]]
rhs _ name (RFloatBinary operation first second) = do
  opcode <- binary operation
  a <- scalar first
  b <- scalar second
  Right [instruction opcode (register name) [a, b]]
rhs _ name (RComparison operation first second) = do
  a <- scalar first
  b <- scalar second
  Right [instruction ("setp." ++ comparison operation ++ ".f32") (register name) [a, b]]
rhs _ name (RBoolUnary BNot value) =
  Right [instruction "not.pred" (register name) [predicate value]]
rhs _ name (RBoolBinary operation first second) =
  Right [instruction (case operation of BAnd => "and.pred"; BOr => "or.pred")
                     (register name) [predicate first, predicate second]]
rhs _ name (RFloatTuple2 first second) = do
  values <- traverse scalar [first, second]
  Right (moveVector name values)
rhs _ name (RFloatTuple3 first second third) = do
  values <- traverse scalar [first, second, third]
  Right (moveVector name values)
rhs _ name (RFloatTuple4 first second third fourth) = do
  values <- traverse scalar [first, second, third, fourth]
  Right (moveVector name values)
rhs _ name (RComponent index (OLocal source)) =
  Right [instruction "mov.f32" (register name) [component source (finToNat index)]]
rhs ty name (RSelect condition first second) = select ty name condition first second
rhs _ _ _ = Left "PTX follower refuses this checked IR operation"

assign : (ty : ValueTy) -> String -> Operand ty -> Either String (List String)
assign TFloat name value = do
  input <- scalar value
  Right [instruction "mov.f32" (register name) [input]]
assign TBool name value = Right [instruction "and.pred" (register name) [predicate value, "1"]]
assign (TFloatTuple width) name value = Right (moveVector name (vector width value))
assign _ _ _ = Left "PTX follower refuses integer/array branch results"

mutual
  statement : Statement -> Either String (List String, List String)
  statement (SBinding (MkBinding ty name value)) = do
    registers <- declarations ty name
    body <- rhs ty name value
    Right (registers, body)
  statement (SIf ty name condition thenStatements first elseStatements second) = do
    registers <- declarations ty name
    (thenRegisters, thenBody) <- statementsCode thenStatements
    (elseRegisters, elseBody) <- statementsCode elseStatements
    thenResult <- assign ty name first
    elseResult <- assign ty name second
    let test = "%branch_" ++ name
        testCode = instruction "and.pred" test [predicate condition, "1"]
        otherwise = "ELSE_" ++ name
        finished = "END_" ++ name
    Right (registers ++ thenRegisters ++ elseRegisters ++ [".reg .pred " ++ test ++ ";"],
           [testCode, "  @!" ++ test ++ " bra " ++ otherwise ++ ";"] ++ thenBody ++ thenResult ++
           ["  bra " ++ finished ++ ";", otherwise ++ ":"] ++ elseBody ++ elseResult ++ [finished ++ ":"])
  statement (SBoundedLoop _ _ _ _ _ _ _ _ _) = Left "PTX follower refuses bounded loops"

  statementsCode : List Statement -> Either String (List String, List String)
  statementsCode [] = Right ([], [])
  statementsCode (first :: rest) = do
    (registers, body) <- statement first
    (remainingRegisters, remainingBody) <- statementsCode rest
    Right (registers ++ remainingRegisters, body ++ remainingBody)

||| The ABI names are prefixed and never taken as compiler-generated locals.
input : InterfaceVar -> Either String (List String, List String, List String)
input (MkInterfaceVar name Uniform TFloat) =
  Right ([".param .f32 p_arg_" ++ name], [".reg .f32 " ++ register name ++ ";"],
         [instruction "ld.param.f32" (register name) ["[p_arg_" ++ name ++ "]"]])
input (MkInterfaceVar name FragmentInput (TFloatTuple width)) = do
  registers <- declarations (TFloatTuple width) name
  let body = [instruction "ld.param.u64" "%__input" ["[p_arg_" ++ name ++ "]"],
              instruction "mul.wide.u32" "%__offset" ["%__index", show (4 * width)],
              instruction "add.u64" "%__input" ["%__input", "%__offset"]] ++
             map (\index => instruction "ld.global.f32" (component name index)
                   ["[%__input+" ++ show (4 * index) ++ "]"]) (indices width)
  Right ([".param .u64 p_arg_" ++ name], registers, body)
input _ = Left "PTX ABI admits per-sample vectors and scalar uniforms only"

public export
emitPTX : String -> FragmentProgram -> Either String String
emitPTX target program = do
  if legalTarget target then Right () else Left "unsupported PTX target (no architecture suffix fallback)"
  inputs <- traverse input (entryInterface (spec program))
  lowered <- traverse statement (statements program)
  let kernelParameters = concatMap (\(p, _, _) => p) inputs ++ [".param .u64 p_output", ".param .u32 p_count"]
      registers = concatMap (\(_, r, _) => r) inputs ++ concatMap fst lowered
      body = concatMap (\(_, _, b) => b) inputs ++ concatMap snd lowered
      results = vector 4 (result program)
      stores = zipWith (\index, value => "  st.global.f32 [%__output+" ++ show (4 * index) ++ "], " ++ value ++ ";")
                       (indices 4) results
  Right (unlines ([".version 8.8", ".target " ++ target, ".address_size 64", "",
                  ".visible .entry shader_kernel(", "  " ++ concat (intersperse ",\n  " kernelParameters), ") {",
                  ".reg .b32 %__thread, %__block, %__blocksize, %__index, %__count;",
                  ".reg .b64 %__input, %__output, %__offset;", ".reg .pred %__outside;"] ++ registers ++
                 ["  mov.u32 %__thread, %tid.x;", "  mov.u32 %__block, %ctaid.x;",
                  "  mov.u32 %__blocksize, %ntid.x;",
                  "  mad.lo.u32 %__index, %__block, %__blocksize, %__thread;",
                  "  ld.param.u32 %__count, [p_count];", "  setp.ge.u32 %__outside, %__index, %__count;",
                  "  @%__outside bra DONE;"] ++ body ++
                 ["  ld.param.u64 %__output, [p_output];", "  mul.wide.u32 %__offset, %__index, 16;",
                  "  add.u64 %__output, %__output, %__offset;"] ++ stores ++ ["DONE:", "  ret;", "}"]))
