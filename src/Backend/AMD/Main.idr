module Backend.AMD.Main

import Backend.AMD.Codegen
import Compiler.Common
import Idris.Driver

main : IO ()
main = mainWithCodegens [("amdgcn", amdCodegen)]
