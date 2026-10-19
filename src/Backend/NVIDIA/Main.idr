module Backend.NVIDIA.Main

import Backend.NVIDIA.Codegen
import Compiler.Common
import Idris.Driver

main : IO ()
main = mainWithCodegens [("ptx", ptxCodegen)]
