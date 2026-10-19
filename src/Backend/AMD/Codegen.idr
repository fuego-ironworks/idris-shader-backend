module Backend.AMD.Codegen

import Backend.AMD.LLVM
import Backend.GLSLES.Codegen
import Backend.GLSLES.FloatSemantics
import Backend.GLSLES.IR
import Backend.GLSLES.Lower
import Compiler.Common
import Core.Context
import Core.Core
import Core.FC
import Core.Options
import Idris.Syntax

%default covering

failure : String -> Core a
failure message = throw (GenericMsg emptyFC ("AMDGPU backend: " ++ message))

compileAMD : Ref Ctxt Defs -> Ref Syn SyntaxInfo -> String -> String ->
             ClosedTerm -> String -> Core (Maybe String)
compileAMD defs syn temporary outputDir term outfile = do
  shader <- prepareExportedShader "amdgcn" defs term
  schema <- checkShaderInterface defs shader
  program <- lowerExportedShader schema shader
  session <- getSession {c = defs}
  let requested = directives session
  case directiveValue "float-width=" requested of
    Nothing => pure ()
    Just "f32" => pure ()
    _ => failure "AMDGPU follower requires F32; no width reinterpretation"
  let target = maybe "gfx942" id (directiveValue "amd-target=" requested)
  source <- case emitLLVM target program of
    Left message => failure message
    Right value => pure value
  writeRequestedIR requested F32 program
  let output = outputDir ++ "/" ++ outfile ++ ".ll"
  writeShader output source
  pure (Just output)

executeAMD : Ref Ctxt Defs -> Ref Syn SyntaxInfo -> String -> ClosedTerm -> Core ()
executeAMD _ _ _ _ = failure "ROCm launch and numerical readback require a physical AMD GPU"

public export
amdCodegen : Codegen
amdCodegen = MkCG compileAMD executeAMD Nothing Nothing
