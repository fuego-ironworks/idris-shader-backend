module Backend.AMD.LLVM

import Backend.GLSLES.IR
import Data.Fin
import Data.List
import Data.String

%default total

value : Operand TFloat -> Either String String
value (OLocal name) = Right ("%value_" ++ name)
value (OFloat number) =
  let text = show number
      decimal = if any (\c => c == '.' || c == 'e' || c == 'E') (unpack text)
                   then text else text ++ ".0"
   in if elem number [-2.0, -1.0, 0.0, 1.0, 2.0]
         then Right decimal
         else Left "LLVM pixel slice requires an exactly representable literal from 0, +/-1, +/-2"

opcode : FloatBinary -> Either String String
opcode FAdd = Right "fadd"
opcode FSub = Right "fsub"
opcode FMul = Right "fmul"
opcode FDiv = Right "fdiv"
opcode _ = Left "LLVM follower refuses this floating operation"

isInput2 : String -> List InterfaceVar -> Bool
isInput2 _ [] = False
isInput2 name (MkInterfaceVar actual FragmentInput (TFloatTuple 2) :: rest) =
  name == actual || isInput2 name rest
isInput2 name (_ :: rest) = isInput2 name rest

binding : List InterfaceVar -> Binding -> Either String (List String)
binding inputs (MkBinding TFloat name (RFloatBinary operation first second)) = do
  instruction <- opcode operation
  a <- value first
  b <- value second
  Right ["  %value_" ++ name ++ " = " ++ instruction ++ " float " ++ a ++ ", " ++ b]
binding inputs (MkBinding TFloat name (RComponent index (OLocal source))) =
  if isInput2 source inputs && finToNat index < 2
     then Right ["  %value_" ++ name ++ " = extractelement <2 x float> %value_" ++ source ++ ", i32 " ++ show (finToNat index)]
     else Left "LLVM component requires a checked two-component input"
binding inputs (MkBinding (TFloatTuple 4) name (RFloatTuple4 first second third fourth)) = do
  a <- value first
  b <- value second
  c <- value third
  d <- value fourth
  Right ["  %pack_" ++ name ++ "_0 = insertelement <4 x float> poison, float " ++ a ++ ", i32 0",
         "  %pack_" ++ name ++ "_1 = insertelement <4 x float> %pack_" ++ name ++ "_0, float " ++ b ++ ", i32 1",
         "  %pack_" ++ name ++ "_2 = insertelement <4 x float> %pack_" ++ name ++ "_1, float " ++ c ++ ", i32 2",
         "  %value_" ++ name ++ " = insertelement <4 x float> %pack_" ++ name ++ "_2, float " ++ d ++ ", i32 3"]
binding _ _ = Left "LLVM follower refuses this checked IR binding"

statement : List InterfaceVar -> Statement -> Either String (List String)
statement inputs (SBinding checkedBinding) = binding inputs checkedBinding
statement _ _ = Left "LLVM follower refuses control flow in this initial pixel slice"

input : InterfaceVar -> Either String (String, List String)
input (MkInterfaceVar name Uniform TFloat) = Right ("float %value_" ++ name, [])
input (MkInterfaceVar name FragmentInput (TFloatTuple 2)) =
  Right ("ptr addrspace(1) %arg_" ++ name,
    ["  %address_" ++ name ++ " = getelementptr <2 x float>, ptr addrspace(1) %arg_" ++ name ++ ", i32 %__index",
     "  %value_" ++ name ++ " = load <2 x float>, ptr addrspace(1) %address_" ++ name ++ ", align 4"])
input _ = Left "LLVM ABI admits sample vec2 buffers and scalar uniforms only"

public export
emitLLVM : String -> FragmentProgram -> Either String String
emitLLVM target program = do
  if elem target ["gfx942", "gfx950", "gfx1250"] then Right ()
     else Left "unsupported AMD target; no generic fallback"
  let inputs = entryInterface (spec program)
  arguments <- traverse input inputs
  body <- traverse (statement inputs) (statements program)
  let resultName = case result program of OLocal name => "%value_" ++ name
      signature = concat (intersperse ", " (map fst arguments ++ ["ptr addrspace(1) %__output", "i32 %__count"]))
  Right (unlines (["target triple = \"amdgcn-amd-amdhsa\"",
    "declare i32 @llvm.amdgcn.workitem.id.x()", "declare i32 @llvm.amdgcn.workgroup.id.x()",
    "define amdgpu_kernel void @shader_kernel(" ++ signature ++ ") #0 {", "entry:",
    "  %__thread = call i32 @llvm.amdgcn.workitem.id.x()",
    "  %__block = call i32 @llvm.amdgcn.workgroup.id.x()",
    "  %__base = mul i32 %__block, 64", "  %__index = add i32 %__base, %__thread",
    "  %__inside = icmp ult i32 %__index, %__count", "  br i1 %__inside, label %sample, label %done",
    "sample:"] ++ concatMap snd arguments ++ concat body ++
    ["  %__destination = getelementptr <4 x float>, ptr addrspace(1) %__output, i32 %__index",
     "  store <4 x float> " ++ resultName ++ ", ptr addrspace(1) %__destination, align 4",
     "  br label %done", "done:", "  ret void", "}",
     "attributes #0 = { \"target-cpu\"=\"" ++ target ++ "\" \"amdgpu-flat-work-group-size\"=\"64,64\" }"]))
