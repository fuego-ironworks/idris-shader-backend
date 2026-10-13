module Backend.NVIDIA.Codegen

import Backend.GLSLES.Codegen
import Backend.GLSLES.FloatSemantics
import Backend.GLSLES.IR
import Backend.GLSLES.Lower
import Backend.NVIDIA.PTX
import Compiler.Common
import Core.Context
import Core.Core
import Core.FC
import Core.Options
import Idris.Syntax

%default covering

failure : String -> Core a
failure message = throw (GenericMsg emptyFC ("PTX backend: " ++ message))

checked : Either String a -> Core a
checked (Left message) = failure message
checked (Right value) = pure value

compilePTX : Ref Ctxt Defs -> Ref Syn SyntaxInfo -> String -> String ->
             ClosedTerm -> String -> Core (Maybe String)
compilePTX defs syn temporary outputDir term outfile = do
  shader <- prepareExportedShader "ptx" defs term
  schema <- checkShaderInterface defs shader
  program <- lowerExportedShader schema shader
  session <- getSession {c = defs}
  let requested = directives session
  case directiveValue "float-width=" requested of
    Nothing => pure ()
    Just "f32" => pure ()
    _ => failure "PTX follower requires explicit F32; F16 cannot be reinterpreted"
  let target = maybe "sm_80" id (directiveValue "ptx-target=" requested)
  source <- checked (emitPTX target program)
  writeRequestedIR requested F32 program
  let output = outputDir ++ "/" ++ outfile ++ ".ptx"
  writeShader output source
  pure (Just output)

executePTX : Ref Ctxt Defs -> Ref Syn SyntaxInfo -> String -> ClosedTerm -> Core ()
executePTX _ _ _ _ = failure "GPU launch and numerical readback require a physical CUDA driver"

public export
ptxCodegen : Codegen
ptxCodegen = MkCG compilePTX executePTX Nothing Nothing
