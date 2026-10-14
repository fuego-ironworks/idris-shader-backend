module Backend.GLSLES.Signature

import Backend.GLSLES.IR
import Core.Name
import Core.TT
import Data.String

%default covering

parseNat : Term vars -> Either String Nat
parseNat (Ref _ _ name) =
  if show name == "Prelude.Types.Z"
     then Right 0
     else Left ("expected a concrete size, received " ++ show name)
parseNat (App _ (Ref _ _ name) predecessor) =
  if show name == "Prelude.Types.S"
     then S <$> parseNat predecessor
     else Left ("expected a concrete size, received " ++ show name)
parseNat _ = Left "expected a concrete size"

arrayElement : ValueTy -> Either String ArrayElementTy
arrayElement TFloat = Right AFloat
arrayElement TBool = Right ABool
arrayElement TInt = Right AInt
arrayElement (TFloatTuple n) = Right (AFloatTuple n)
arrayElement (TArray _ _) = Left "nested shader arrays are not supported"

parseValueTy : Term vars -> Either String ValueTy
parseValueTy (PrimVal _ (PrT DoubleType)) = Right TFloat
parseValueTy (PrimVal _ (PrT IntType)) = Right TInt
parseValueTy (Ref _ _ name) =
  if show name == "Prelude.Types.Bool"
    then Right TBool
    else Left ("unsupported shader entry type " ++ show name)
parseValueTy (App _ (Ref _ _ name) width) =
  if show name == "Shader.Source.ShaderFloatTuple"
     then do
       n <- parseNat width
       if n >= 2 && n <= 4
          then Right (TFloatTuple n)
          else Left ("GLSL ES vectors must have width 2, 3, or 4; received " ++ show n)
     else Left ("unsupported shader entry type " ++ show name)
parseValueTy (App _ (App _ (Ref _ _ name) count) elementType) =
  if show name == "Shader.Source.SArray"
     then do
       n <- parseNat count
       if n == 0
          then Left "shader arrays must contain at least one element"
          else do
            element <- parseValueTy elementType >>= arrayElement
            Right (TArray n element)
     else if show name == "Shader.Coordinates.VectorCoordinates" ||
             show name == "Shader.Coordinates.CovectorCoordinates"
       then do
         dimension <- parseNat count
         case elementType of
           Ref _ _ frame =>
             if (dimension == 4 && show frame == "Shader.Coordinates.CartesianReal4") ||
                (dimension == 32 && (show frame == "Shader.Coordinates.CartesianReal32" ||
                                    show frame == "Shader.Coordinates.OtherCartesianReal32"))
               then Right (TArray dimension AFloat)
               else Left ("unsupported real coordinate frame " ++ show frame)
           _ => Left "coordinate packets require a concrete named Cartesian frame"
       else Left ("unsupported shader entry type " ++ show name)
parseValueTy _ = Left "unsupported shader entry type"

sourceTypeDescription : Term vars -> Either String String
sourceTypeDescription value@(App _ (App _ (Ref _ _ name) count) (Ref _ _ frame)) =
  if show name == "Shader.Coordinates.VectorCoordinates" ||
     show name == "Shader.Coordinates.CovectorCoordinates"
    then do
      dimension <- parseNat count
      _ <- parseValueTy value
      Right (nameRoot name ++ " dimension=" ++ show dimension ++
             " ambient-field=real frame=" ++ show frame ++
             " packing=fixed-scalar-array")
    else show <$> parseValueTy value
sourceTypeDescription value = show <$> parseValueTy value

||| Stable schema derived from the checked source before role erasure.
||| Internal binder IDs are deliberately absent from the serialized interface.
public export
checkedSourceSchema : ClosedTerm -> Either String String
checkedSourceSchema value = unlines <$> describe 0 value
  where
    describe : Nat -> Term vars -> Either String (List String)
    describe argument (Bind _ _ (Pi _ _ Explicit argumentType) scope) = do
      description <- sourceTypeDescription argumentType
      rest <- describe (S argument) scope
      Right (("argument=" ++ show argument ++ " " ++ description) :: rest)
    describe _ (Bind _ _ (Pi _ _ _ _) _) =
      Left "shader entry points may not have implicit or auto arguments"
    describe _ resultType = do
      description <- sourceTypeDescription resultType
      Right ["result " ++ description]

||| Read shader types before Idris erases them on the way to Administrative_Normal_Form.
public export
shaderSignature : ClosedTerm -> Either String (List ValueTy, ValueTy)
shaderSignature = go []
  where
    go : List ValueTy -> Term vars -> Either String (List ValueTy, ValueTy)
    go reversed (Bind _ _ (Pi _ _ Explicit argumentType) scope) = do
      ty <- parseValueTy argumentType
      go (ty :: reversed) scope
    go _ (Bind _ _ (Pi _ _ _ _) _) =
      Left "shader entry points may not have implicit or auto arguments"
    go reversed resultType = do
      result <- parseValueTy resultType
      Right (reverse reversed, result)
