module Backend.GLSLES.Codegen

import Backend.GLSLES.Emit
import Backend.GLSLES.FloatSemantics
import Backend.GLSLES.Interface
import Backend.GLSLES.IR
import Backend.GLSLES.Lower
import Backend.GLSLES.Signature
import Compiler.ANF
import Compiler.Common
import Core.Context
import Core.Core
import Core.FC
import Core.Options
import Data.String
import Idris.Syntax
import System.File
import System

%default covering

backendError : String -> Core a
backendError message = coreLift $ die ("Error: GLSL ES backend: " ++ message)

fromEither : Either String a -> Core a
fromEither (Left message) = backendError message
fromEither (Right value) = pure value

findANF : Name -> List (Name, Administrative_Normal_Form_Definition) -> Maybe Administrative_Normal_Form_Definition
findANF _ [] = Nothing
findANF wanted ((name, definition) :: rest) =
  if wanted == name then Just definition else findANF wanted rest

renderANFDefinitions : List (Name, Administrative_Normal_Form_Definition) -> String
renderANFDefinitions [] = ""
renderANFDefinitions ((name, definition) :: rest) =
  show name ++ " = " ++ show definition ++ "\n" ++ renderANFDefinitions rest

entryType : {auto c : Ref Ctxt Defs} -> Name -> Core ClosedTerm
entryType name = do
  context <- get Ctxt
  found <- lookupCtxtExact name (gamma context)
  case found of
    Nothing => backendError ("could not recover the type of exported entry " ++ show name)
    Just global => toFullNames (type global)

public export
writeShader : String -> String -> Core ()
writeShader path source = do
  result <- coreLift $ writeFile path source
  case result of
    Left error => backendError ("could not write " ++ path ++ ": " ++ show error)
    Right () => pure ()

public export
directiveValue : String -> List String -> Maybe String
directiveValue _ [] = Nothing
directiveValue needle (value :: rest) =
  if isPrefixOf needle value
     then Just (pack (drop (length (unpack needle)) (unpack value)))
     else directiveValue needle rest

selectedFloatWidth : List String -> Either String FloatWidth
selectedFloatWidth values = case directiveValue "float-width=" values of
  Nothing => Right defaultFloatWidth
  Just "" => Left "float-width directive requires f16 or f32"
  Just value => parseFloatWidth value

selectedFloatPrecision : FloatWidth -> List String -> Either String ShaderPrecision
selectedFloatPrecision width values = case directiveValue "float-precision=" values of
  Nothing => Right (shaderPrecision width)
  Just "lowp" => Right Low
  Just "mediump" => Right Medium
  Just "highp" => Right High
  Just "" => Left "float-precision directive requires lowp, mediump, or highp"
  Just value => Left ("float-precision must be lowp, mediump, or highp, received " ++ value)

requireSingleShaderExport : List (Name, String) -> Core (Name, String)
requireSingleShaderExport [] =
  backendError "no shader entry; add %export \"glsles:fragment|name=in,name=uniform\""
requireSingleShaderExport [entry] = pure entry
requireSingleShaderExport entries =
  backendError ("expected one glsles export, received " ++ show (length entries))

public export
record ExportedShader where
  constructor MkExportedShader
  shaderEntryName : Name
  shaderExportAnnotation : String
  shaderDefinitions : ShaderDefs

public export
prepareExportedShader : String -> Ref Ctxt Defs -> ClosedTerm -> Core ExportedShader
prepareExportedShader group defs term = do
  compilation <- getCompileDataWith {c = defs} [group] False Administrative_Normal_Form term
  (resolvedName, annotation) <- requireSingleShaderExport (exported compilation)
  entryName <- toFullNames resolvedName
  pure (MkExportedShader entryName annotation (anf compilation))

public export
checkShaderInterface : Ref Ctxt Defs -> ExportedShader -> Core EntrySpec
checkShaderInterface defs shader = do
  raw <- fromEither (parseRawEntry (shaderExportAnnotation shader))
  signature <- entryType {c = defs} (shaderEntryName shader)
  (argumentTypes, resultType) <- fromEither (shaderSignature signature)
  fromEither (makeEntrySpec raw argumentTypes resultType)

public export
lowerExportedShader : EntrySpec -> ExportedShader -> Core FragmentProgram
lowerExportedShader spec shader = do
  let entryName = shaderEntryName shader
  let definitions = shaderDefinitions shader
  Just definition <- pure (findANF entryName definitions)
    | Nothing => backendError ("could not find Administrative_Normal_Form for exported entry " ++ show entryName)
  fromEither (lowerFragment spec entryName definitions definition)

public export
writeRequestedIR : List String -> FloatWidth -> FragmentProgram -> Core ()
writeRequestedIR requestedDirectives width program =
  case directiveValue "dump-ir=" requestedDirectives of
    Nothing => pure ()
    Just "" => backendError "dump-ir directive requires a path"
    Just path => do
      renderedIR <- fromEither (dumpFragmentIRWithWidth width program)
      writeShader path renderedIR

writeFragmentOutput :
  List String ->
  FloatWidth ->
  String ->
  String ->
  FragmentProgram ->
  Core String
writeFragmentOutput requestedDirectives width outputDir outfile program = do
  precision <- fromEither (selectedFloatPrecision width requestedDirectives)
  source <- fromEither (emitFragmentWithPrecision precision program)
  let output = outputDir ++ "/" ++ outfile ++ ".frag"
  writeShader output source
  pure output

public export
compileGLSLES :
  Ref Ctxt Defs ->
  Ref Syn SyntaxInfo ->
  (tmpDir : String) -> (outputDir : String) ->
  ClosedTerm -> (outfile : String) -> Core (Maybe String)
compileGLSLES defs syn tmpDir outputDir term outfile = do
  shader <- prepareExportedShader "glsles" defs term
  spec <- checkShaderInterface defs shader
  checkedSourceType <- entryType {c = defs} (shaderEntryName shader)
  checkedSchema <- fromEither (checkedSourceSchema checkedSourceType)
  writeShader (outputDir ++ "/" ++ outfile ++ ".source-interface")
    ("schema=checked-shader-source-v1\n" ++ checkedSchema ++
     "arithmetic=shader-profile-approximation; source Double does not promise binary64\n")
  session <- getSession {c = defs}
  let requestedDirectives = directives session
  case directiveValue "dump-anf=" requestedDirectives of
    Nothing => pure ()
    Just "" => backendError "dump-anf directive requires a path"
    Just path => writeShader path (renderANFDefinitions (shaderDefinitions shader))
  program <- lowerExportedShader spec shader
  width <- fromEither (selectedFloatWidth requestedDirectives)
  writeRequestedIR requestedDirectives width program
  output <- writeFragmentOutput requestedDirectives width outputDir outfile program
  pure (Just output)

public export
executeGLSLES :
  Ref Ctxt Defs ->
  Ref Syn SyntaxInfo ->
  (tmpDir : String) -> ClosedTerm -> Core ()
executeGLSLES defs syn tmpDir term =
  coreLift $ putStrLn "GLSL ES shaders are compiled, not executed by Idris2."

public export
glslesCodegen : Codegen
glslesCodegen = MkCG compileGLSLES executeGLSLES Nothing Nothing
