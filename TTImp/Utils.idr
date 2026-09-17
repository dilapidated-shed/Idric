module TTImp.Utils

import Core.Env
import Core.Value
import Core.UnifyState
import TTImp.TTImp

import Data.String

import Idris.Syntax

import Libraries.Data.NameMap
import Libraries.Utils.String

%default covering


-- Appends the ' character to "x" until it is unique with respect to "xs".
export
genUniqueStr : (xs : List String) -> (x : String) -> String
genUniqueStr xs x = if x `elem` xs then genUniqueStr xs (x ++ "'") else x


-- Extract the RawImp pieces from a ImpDecl so they can be searched for unquotes
-- Used in findBindableNames{,Quot}
rawImpFromDecl : ImpDecl -> List RawImp
rawImpFromDecl decl = case decl of
    Elaborable_Claim (MkWithData fc1 $ Make_Elaborable_Claim_Data y z ys ty) => [ty.val]
    Elaborable_Data_Declaration fc1 y _ (MkImpData fc2 n tycon opts datacons)
        => maybe id (::) tycon $ map val datacons
    Elaborable_Data_Declaration fc1 y _ (MkImpLater fc2 n tycon) => [tycon]
    Elaborable_Definition fc1 y ys => getFromClause !ys
    Elaborable_Parameter_Block fc1 ys zs => rawImpFromDecl !zs ++ map getParamTy (forget ys)
    Elaborable_Record_Declaration fc1 y z _ (MkWithData _ (MkImpRecord header body)) => do
        binder <- header.val
        field <- body.val
        getFromPiInfo binder.val.info ++ [binder.val.boundType] ++ getFromIField field
    Elaborable_Expected_Failure fc1 msg zs => rawImpFromDecl !zs
    Elaborable_Namespace_Block fc1 ys zs => rawImpFromDecl !zs
    Elaborable_Transformation fc1 y z w => [z, w]
    Elaborable_Run_Elaborator_Declaration fc1 y => [] -- Not sure about this either
    Elaborable_Pragma _ _ f => []
    Elaborable_Logging k => []
    Elaborable_Builtin_Declaration {} => []
  where getParamTy : ImpParameter' RawImp -> RawImp
        getParamTy binder = binder.val.boundType
        getFromClause : ImpClause -> List RawImp
        getFromClause (PatClause fc1 lhs rhs) = [lhs, rhs]
        getFromClause (WithClause fc1 lhs rig wval prf flags ys) = [wval, lhs] ++ getFromClause !ys
        getFromClause (ImpossibleClause fc1 lhs) = [lhs]
        getFromPiInfo : PiInfo RawImp -> List RawImp
        getFromPiInfo (DefImplicit x) = [x]
        getFromPiInfo _ = []
        getFromIField : Elaborable_Field -> List RawImp
        getFromIField field = getFromPiInfo field.val.info ++ [field.val.boundType]


-- Identify lower case names in argument position, which we can bind later.
-- Don't go under case, let, or local bindings, or Elaborable_Alternative.
--
-- arg: Is the current expression in argument position? (We don't want to implicitly
--      bind funtions.)
--
-- env: Local names in scope. We only want to bind free variables, so we need this.
export
findBindableNames : (arg : Bool) -> (env : List Name) -> (used : List String) ->
                    RawImp -> List (Name, Name)

-- Helper to traverse the inside of a quoted expression, looking for unquotes
findBindableNamesQuot : List Name -> (used : List String) -> RawImp ->
                        List (Name, Name)

findBindableNames True env used (Elaborable_Name fc nm@(UN (Basic n)))
      -- If the identifier is not bound locally and begins with a lowercase letter..
    = if not (nm `elem` env) && lowerFirst n
         then [(nm, UN $ Basic $ genUniqueStr used n)]
         else []
findBindableNames arg env used (Elaborable_Dependent_Function_Type fc rig p mn aty retty)
    = let env' = case mn of
                      Nothing => env
                      Just n => n :: env in
          findBindableNames True env used aty ++
          findBindableNames True env' used retty
findBindableNames arg env used (Elaborable_Lambda fc rig p mn aty sc)
    = let env' = case mn of
                      Nothing => env
                      Just n => n :: env in
      findBindableNames True env used aty ++
      findBindableNames True env' used sc
findBindableNames arg env used (Elaborable_Apply fc fn av)
    = findBindableNames False env used fn ++ findBindableNames True env used av
findBindableNames arg env used (Elaborable_Named_Apply fc fn n av)
    = findBindableNames False env used fn ++ findBindableNames True env used av
findBindableNames arg env used (Elaborable_Automatic_Apply fc fn av)
    = findBindableNames False env used fn ++ findBindableNames True env used av
findBindableNames arg env used (Elaborable_With_Apply fc fn av)
    = findBindableNames False env used fn ++ findBindableNames True env used av
findBindableNames arg env used (Elaborable_As_Pattern fc _ _ nm@(UN (Basic n)) pat)
    = (nm, UN $ Basic $ genUniqueStr used n) :: findBindableNames arg env used pat
findBindableNames arg env used (Elaborable_As_Pattern fc _ _ n pat)
    = findBindableNames arg env used pat
findBindableNames arg env used (Elaborable_Must_Unify fc r pat)
    = findBindableNames arg env used pat
findBindableNames arg env used (Elaborable_Delayed_Type fc r t)
    = findBindableNames arg env used t
findBindableNames arg env used (Elaborable_Delay fc t)
    = findBindableNames arg env used t
findBindableNames arg env used (Elaborable_Force fc t)
    = findBindableNames arg env used t
findBindableNames arg env used (Elaborable_Quote fc t)
    = findBindableNamesQuot env used t
findBindableNames arg env used (Elaborable_Quote_Declarations fc d)
    = findBindableNamesQuot env used !(rawImpFromDecl !d)
findBindableNames arg env used (Elaborable_Alternative fc u alts)
    = concatMap (findBindableNames arg env used) alts
findBindableNames arg env used (Elaborable_Record_Update fc updates tm)
    = findBindableNames True env used tm ++
      concatMap (findBindableNames True env used . getFieldUpdateTerm) updates
-- We've skipped case, let and local - rather than guess where the
-- name should be bound, leave it to the programmer
findBindableNames arg env used tm = []

findBindableNamesQuot env used (Elaborable_Dependent_Function_Type fc x y z argTy retTy)
    = findBindableNamesQuot env used ![argTy, retTy]
findBindableNamesQuot env used (Elaborable_Lambda fc x y z argTy lamTy)
    = findBindableNamesQuot env used ![argTy, lamTy]
findBindableNamesQuot env used (Elaborable_Binding fc lhsfc x y nTy nVal scope)
    = findBindableNamesQuot env used ![nTy, nVal, scope]
findBindableNamesQuot env used (Elaborable_Case fc _ x ty xs)
    = findBindableNamesQuot env used !([x, ty] ++ getRawImp !xs)
  where getRawImp : ImpClause -> List RawImp
        getRawImp (PatClause fc1 lhs rhs) = [lhs, rhs]
        getRawImp (WithClause fc1 lhs rig wval prf flags ys) = [wval, lhs] ++ getRawImp !ys
        getRawImp (ImpossibleClause fc1 lhs) = [lhs]
findBindableNamesQuot env used (Elaborable_Local_Definitions fc xs x)
    = findBindableNamesQuot env used !(x :: rawImpFromDecl !xs)
findBindableNamesQuot env used (Elaborable_Case_Local_Definition fc uname internalName args x)
    = findBindableNamesQuot env used x
findBindableNamesQuot env used (Elaborable_Apply fc x y)
    = findBindableNamesQuot env used ![x, y]
findBindableNamesQuot env used (Elaborable_Named_Apply fc x y z)
    = findBindableNamesQuot env used ![x, z]
findBindableNamesQuot env used (Elaborable_Automatic_Apply fc x y)
    = findBindableNamesQuot env used ![x, y]
findBindableNamesQuot env used (Elaborable_With_Apply fc x y)
    = findBindableNamesQuot env used ![x, y]
findBindableNamesQuot env used (Elaborable_Rewrite fc x y)
    = findBindableNamesQuot env used ![x, y]
findBindableNamesQuot env used (Elaborable_Coerced fc x)
    = findBindableNamesQuot env used x
findBindableNamesQuot env used (Elaborable_Bind_Here fc x y)
    = findBindableNamesQuot env used y
findBindableNamesQuot env used (Elaborable_Record_Update fc xs x)
    = findBindableNamesQuot env used !(x :: map getFieldUpdateTerm xs)
findBindableNamesQuot env used (Elaborable_As_Pattern fc nfc x y z)
    = findBindableNamesQuot env used z
findBindableNamesQuot env used (Elaborable_Delayed_Type fc x y)
    = findBindableNamesQuot env used y
findBindableNamesQuot env used (Elaborable_Delay fc x)
    = findBindableNamesQuot env used x
findBindableNamesQuot env used (Elaborable_Force fc x)
    = findBindableNamesQuot env used x
findBindableNamesQuot env used (Elaborable_Unquote fc x)
    = findBindableNames True env used x
findBindableNamesQuot env used (Elaborable_With_Unambiguous_Names fc xs x)
    = findBindableNamesQuot env used x
findBindableNamesQuot env used (Elaborable_Name fc x) = []
findBindableNamesQuot env used (Elaborable_Search fc depth) = []
findBindableNamesQuot env used (Elaborable_Alternative fc x xs) = []
findBindableNamesQuot env used (Elaborable_Bind_Name fc x) = []
findBindableNamesQuot env used (Elaborable_Primitive_Value fc c) = []
findBindableNamesQuot env used (Elaborable_Type_Universe fc) = []
findBindableNamesQuot env used (Elaborable_Hole fc x) = []
findBindableNamesQuot env used (Implicit fc bindIfUnsolved) = []
-- These are the ones I'm not sure about
findBindableNamesQuot env used (Elaborable_Must_Unify fc x y)
    = findBindableNamesQuot env used y
findBindableNamesQuot env used (Elaborable_Unification_Log fc k x)
    = findBindableNamesQuot env used x
-- Should f `(g `(List ~(x))) bind "x" as a parameter to "f"?
-- Depends how (or if) recursive quoting works
findBindableNamesQuot env used (Elaborable_Quote fc x) = []
findBindableNamesQuot env used (Elaborable_Quote_Name fc x) = []
findBindableNamesQuot env used (Elaborable_Quote_Declarations fc xs) = []
findBindableNamesQuot env used (Elaborable_Run_Elaborator fc _ x) = []

||| Lower-case names normally become implicit binders. A lower-case type or
||| data constructor introduced by Idriç choice syntax is a global name
||| instead, so leave it for ordinary name resolution.
export
excludeKnownTyOrDataCons :
  {auto c : Ref Ctxt Defs} ->
  List (Name, Name) -> Core (List (Name, Name))
excludeKnownTyOrDataCons ns
    = do defs <- get Ctxt
         filterM (keep defs) ns
  where
    isTyOrDataCon : (Name, Int, GlobalDef) -> Bool
    isTyOrDataCon (_, _, gdef) =
      case definition gdef of
        TCon {} => True
        DCon {} => True
        _ => False

    keep : Defs -> (Name, Name) -> Core Bool
    keep defs (n, _) = do
      matches <- lookupCtxtName n (gamma defs)
      pure $ not (any isTyOrDataCon matches)

export
findUniqueBindableNames :
  {auto c : Ref Ctxt Defs} ->
  FC -> (arg : Bool) -> (env : List Name) -> (used : List String) ->
  RawImp -> Core (List (Name, Name))
findUniqueBindableNames fc arg env used t
  = do assoc <- excludeKnownTyOrDataCons
                  (nub (findBindableNames arg env used t))
       when (showShadowingWarning !getSession) $
         do defs <- get Ctxt
            let ctxt = gamma defs
            ns <- map catMaybes $ for assoc $ \ (n, _) => do
                    ns <- lookupCtxtName n ctxt
                    let ns = flip List.mapMaybe ns $ \(n, _, d) =>
                               case definition d of
                                -- do not warn about holes: `?a` is not actually
                                -- getting shadowed as it will not become a
                                -- toplevel declaration
                                 Hole {} => Nothing
                                 _ => pure n
                    pure $ MkPair n <$> fromList ns
            whenJust (fromList ns) $ recordWarning . ShadowingGlobalDefs fc
       pure assoc

export
findAllNames : (env : List Name) -> RawImp -> List Name
findAllNames env (Elaborable_Name fc n)
    = if not (n `elem` env) then [n] else []
findAllNames env (Elaborable_Dependent_Function_Type fc rig p mn aty retty)
    = let env' = case mn of
                      Nothing => env
                      Just n => n :: env in
          findAllNames env aty ++ findAllNames env' retty
findAllNames env (Elaborable_Lambda fc rig p mn aty sc)
    = let env' = case mn of
                      Nothing => env
                      Just n => n :: env in
      findAllNames env' aty ++ findAllNames env' sc
findAllNames env (Elaborable_Apply fc fn av)
    = findAllNames env fn ++ findAllNames env av
findAllNames env (Elaborable_Named_Apply fc fn n av)
    = findAllNames env fn ++ findAllNames env av
findAllNames env (Elaborable_Automatic_Apply fc fn av)
    = findAllNames env fn ++ findAllNames env av
findAllNames env (Elaborable_With_Apply fc fn av)
    = findAllNames env fn ++ findAllNames env av
findAllNames env (Elaborable_As_Pattern fc _ _ n pat)
    = n :: findAllNames env pat
findAllNames env (Elaborable_Must_Unify fc r pat)
    = findAllNames env pat
findAllNames env (Elaborable_Delayed_Type fc r t)
    = findAllNames env t
findAllNames env (Elaborable_Delay fc t)
    = findAllNames env t
findAllNames env (Elaborable_Force fc t)
    = findAllNames env t
findAllNames env (Elaborable_Quote fc t)
    = findAllNames env t
findAllNames env (Elaborable_Unquote fc t)
    = findAllNames env t
findAllNames env (Elaborable_Alternative fc u alts)
    = concatMap (findAllNames env) alts
findAllNames env (Elaborable_Record_Update fc updates tm)
    = findAllNames env tm
    ++ concatMap (findAllNames env . getFieldUpdateTerm) updates
    ++ concatMap (map (UN . Basic) . getFieldUpdatePath) updates
-- We've skipped case, let and local - rather than guess where the
-- name should be bound, leave it to the programmer
findAllNames env tm = []

-- Find the names in a type that affect the 'using' declarations (i.e.
-- the ones that mean the declaration will be added).
export
findIBindVars : RawImp -> List Name
findIBindVars (Elaborable_Dependent_Function_Type fc rig p mn aty retty)
    = findIBindVars aty ++ findIBindVars retty
findIBindVars (Elaborable_Lambda fc rig p mn aty sc)
    = findIBindVars aty ++ findIBindVars sc
findIBindVars (Elaborable_Apply fc fn av)
    = findIBindVars fn ++ findIBindVars av
findIBindVars (Elaborable_Named_Apply fc fn n av)
    = findIBindVars fn ++ findIBindVars av
findIBindVars (Elaborable_Automatic_Apply fc fn av)
    = findIBindVars fn ++ findIBindVars av
findIBindVars (Elaborable_With_Apply fc fn av)
    = findIBindVars fn ++ findIBindVars av
findIBindVars (Elaborable_Bind_Name fc v)
    = [v]
findIBindVars (Elaborable_Delayed_Type fc r t)
    = findIBindVars t
findIBindVars (Elaborable_Delay fc t)
    = findIBindVars t
findIBindVars (Elaborable_Force fc t)
    = findIBindVars t
findIBindVars (Elaborable_Alternative fc u alts)
    = concatMap findIBindVars alts
findIBindVars (Elaborable_Record_Update fc updates tm)
    = findIBindVars tm ++ concatMap (findIBindVars . getFieldUpdateTerm) updates
-- We've skipped case, let and local - rather than guess where the
-- name should be bound, leave it to the programmer
findIBindVars tm = []

mutual
  -- Substitute for either an explicit variable name, or a bound variable name
  -- TODO association list should be map (should the `List Name` be a set as well?)
  substNames' : Bool -> List Name -> List (Name, RawImp) ->
                RawImp -> RawImp
  substNames' False bound ps (Elaborable_Name fc n)
      = if not (n `elem` bound)
           then case lookup n ps of
                     Just t => t
                     _ => Elaborable_Name fc n
           else Elaborable_Name fc n
  substNames' True bound ps (Elaborable_Bind_Name fc n)
      = if not (n `elem` bound)
           then case lookup n ps of
                     Just t => t
                     _ => Elaborable_Bind_Name fc n
           else Elaborable_Bind_Name fc n
  substNames' bvar bound ps (Elaborable_Dependent_Function_Type fc r p mn argTy retTy)
      = let bound' = maybe bound (\n => n :: bound) mn in
            Elaborable_Dependent_Function_Type fc r p mn (substNames' bvar bound ps argTy)
                          (substNames' bvar bound' ps retTy)
  substNames' bvar bound ps (Elaborable_Lambda fc r p mn argTy scope)
      = let bound' = maybe bound (\n => n :: bound) mn in
            Elaborable_Lambda fc r p mn (substNames' bvar bound ps argTy)
                           (substNames' bvar bound' ps scope)
  substNames' bvar bound ps (Elaborable_Binding fc lhsFC r n nTy nVal scope)
      = let bound' = n :: bound in
            Elaborable_Binding fc lhsFC r n (substNames' bvar bound ps nTy)
                              (substNames' bvar bound ps nVal)
                              (substNames' bvar bound' ps scope)
  substNames' bvar bound ps (Elaborable_Case fc opts y ty xs)
      = Elaborable_Case fc opts
          (substNames' bvar bound ps y) (substNames' bvar bound ps ty)
          (map (substNamesClause' bvar bound ps) xs)
  substNames' bvar bound ps (Elaborable_Local_Definitions fc xs y)
      = let bound' = definedInBlock emptyNS xs ++ bound in
            Elaborable_Local_Definitions fc (map (substNamesDecl' bvar bound ps) xs)
                      (substNames' bvar bound' ps y)
  substNames' bvar bound ps (Elaborable_Apply fc fn arg)
      = Elaborable_Apply fc (substNames' bvar bound ps fn) (substNames' bvar bound ps arg)
  substNames' bvar bound ps (Elaborable_Named_Apply fc fn y arg)
      = Elaborable_Named_Apply fc (substNames' bvar bound ps fn) y (substNames' bvar bound ps arg)
  substNames' bvar bound ps (Elaborable_Automatic_Apply fc fn arg)
      = Elaborable_Automatic_Apply fc (substNames' bvar bound ps fn) (substNames' bvar bound ps arg)
  substNames' bvar bound ps (Elaborable_With_Apply fc fn arg)
      = Elaborable_With_Apply fc (substNames' bvar bound ps fn) (substNames' bvar bound ps arg)
  substNames' bvar bound ps (Elaborable_Alternative fc y xs)
      = Elaborable_Alternative fc y (map (substNames' bvar bound ps) xs)
  substNames' bvar bound ps (Elaborable_Coerced fc y)
      = Elaborable_Coerced fc (substNames' bvar bound ps y)
  substNames' bvar bound ps (Elaborable_As_Pattern fc nameFC s y pattern)
      = Elaborable_As_Pattern fc nameFC s y (substNames' bvar bound ps pattern)
  substNames' bvar bound ps (Elaborable_Must_Unify fc r pattern)
      = Elaborable_Must_Unify fc r (substNames' bvar bound ps pattern)
  substNames' bvar bound ps (Elaborable_Delayed_Type fc r t)
      = Elaborable_Delayed_Type fc r (substNames' bvar bound ps t)
  substNames' bvar bound ps (Elaborable_Delay fc t)
      = Elaborable_Delay fc (substNames' bvar bound ps t)
  substNames' bvar bound ps (Elaborable_Force fc t)
      = Elaborable_Force fc (substNames' bvar bound ps t)
  substNames' bvar bound ps (Elaborable_Record_Update fc updates tm)
      = Elaborable_Record_Update fc (map (mapFieldUpdateTerm $ substNames' bvar bound ps) updates)
                   (substNames' bvar bound ps tm)
  substNames' bvar bound ps tm = tm

  substNamesClause' : Bool -> List Name -> List (Name, RawImp) ->
                      ImpClause -> ImpClause
  substNamesClause' bvar bound ps (PatClause fc lhs rhs)
      = let bound' = map snd (findBindableNames True bound [] lhs)
                     ++ findIBindVars lhs
                     ++ bound in
            PatClause fc (substNames' bvar [] [] lhs)
                         (substNames' bvar bound' ps rhs)
  substNamesClause' bvar bound ps (WithClause fc lhs rig wval prf flags cs)
      = let bound' = map snd (findBindableNames True bound [] lhs)
                     ++ findIBindVars lhs
                     ++ bound in
            WithClause fc (substNames' bvar [] [] lhs) rig
                          (substNames' bvar bound' ps wval) prf flags cs
  substNamesClause' bvar bound ps (ImpossibleClause fc lhs)
      = ImpossibleClause fc (substNames' bvar bound [] lhs)

  substNamesData' : Bool -> List Name -> List (Name, RawImp) ->
                    ImpData -> ImpData
  substNamesData' bvar bound ps (MkImpData fc n con opts dcons)
      = MkImpData fc n (map (substNames' bvar bound ps) con) opts
                  (map (map (substNames' bvar bound ps)) dcons)
  substNamesData' bvar bound ps (MkImpLater fc n con)
      = MkImpLater fc n (substNames' bvar bound ps con)

  substNamesDecl' : Bool -> List Name -> List (Name, RawImp ) ->
                   ImpDecl -> ImpDecl
  substNamesDecl' bvar bound ps (Elaborable_Claim claim)
      = Elaborable_Claim $ map {type $= map (substNames' bvar bound ps)} claim
  substNamesDecl' bvar bound ps (Elaborable_Definition fc n cs)
      = Elaborable_Definition fc n (map (substNamesClause' bvar bound ps) cs)
  substNamesDecl' bvar bound ps (Elaborable_Data_Declaration fc vis mbtot d)
      = Elaborable_Data_Declaration fc vis mbtot (substNamesData' bvar bound ps d)
  substNamesDecl' bvar bound ps (Elaborable_Expected_Failure fc msg ds)
      = Elaborable_Expected_Failure fc msg (map (substNamesDecl' bvar bound ps) ds)
  substNamesDecl' bvar bound ps (Elaborable_Namespace_Block fc ns ds)
      = Elaborable_Namespace_Block fc ns (map (substNamesDecl' bvar bound ps) ds)
  substNamesDecl' bvar bound ps d = d

export
substNames : List Name -> List (Name, RawImp) ->
             RawImp -> RawImp
substNames = substNames' False

export
substBindVars : List Name -> List (Name, RawImp) ->
                RawImp -> RawImp
substBindVars = substNames' True

export
substNamesClause : List Name -> List (Name, RawImp) ->
                   ImpClause -> ImpClause
substNamesClause = substNamesClause' False

mutual
  export
  substLoc : FC -> RawImp -> RawImp
  substLoc fc' (Elaborable_Name fc n) = Elaborable_Name fc' n
  substLoc fc' (Elaborable_Dependent_Function_Type fc r p mn argTy retTy)
      = Elaborable_Dependent_Function_Type fc' r p mn (substLoc fc' argTy)
                      (substLoc fc' retTy)
  substLoc fc' (Elaborable_Lambda fc r p mn argTy scope)
      = Elaborable_Lambda fc' r p mn (substLoc fc' argTy)
                        (substLoc fc' scope)
  substLoc fc' (Elaborable_Binding fc lhsFC r n nTy nVal scope)
      = Elaborable_Binding fc' fc' r n (substLoc fc' nTy)
                     (substLoc fc' nVal)
                     (substLoc fc' scope)
  substLoc fc' (Elaborable_Case fc opts y ty xs)
      = Elaborable_Case fc' opts (substLoc fc' y) (substLoc fc' ty)
                  (map (substLocClause fc') xs)
  substLoc fc' (Elaborable_Local_Definitions fc xs y)
      = Elaborable_Local_Definitions fc' (map (substLocDecl fc') xs)
                   (substLoc fc' y)
  substLoc fc' (Elaborable_Apply fc fn arg)
      = Elaborable_Apply fc' (substLoc fc' fn) (substLoc fc' arg)
  substLoc fc' (Elaborable_Named_Apply fc fn y arg)
      = Elaborable_Named_Apply fc' (substLoc fc' fn) y (substLoc fc' arg)
  substLoc fc' (Elaborable_Automatic_Apply fc fn arg)
      = Elaborable_Automatic_Apply fc' (substLoc fc' fn) (substLoc fc' arg)
  substLoc fc' (Elaborable_With_Apply fc fn arg)
      = Elaborable_With_Apply fc' (substLoc fc' fn) (substLoc fc' arg)
  substLoc fc' (Elaborable_Alternative fc y xs)
      = Elaborable_Alternative fc' y (map (substLoc fc') xs)
  substLoc fc' (Elaborable_Coerced fc y)
      = Elaborable_Coerced fc' (substLoc fc' y)
  substLoc fc' (Elaborable_As_Pattern fc nameFC s y pattern)
      = Elaborable_As_Pattern fc' fc' s y (substLoc fc' pattern)
  substLoc fc' (Elaborable_Must_Unify fc r pattern)
      = Elaborable_Must_Unify fc' r (substLoc fc' pattern)
  substLoc fc' (Elaborable_Delayed_Type fc r t)
      = Elaborable_Delayed_Type fc' r (substLoc fc' t)
  substLoc fc' (Elaborable_Delay fc t)
      = Elaborable_Delay fc' (substLoc fc' t)
  substLoc fc' (Elaborable_Force fc t)
      = Elaborable_Force fc' (substLoc fc' t)
  substLoc fc' (Elaborable_Record_Update fc updates tm)
      = Elaborable_Record_Update fc' (map (mapFieldUpdateTerm $ substLoc fc') updates)
                    (substLoc fc' tm)
  substLoc fc' tm = tm

  export
  substLocClause : FC -> ImpClause -> ImpClause
  substLocClause fc' (PatClause fc lhs rhs)
      = PatClause fc' (substLoc fc' lhs)
                      (substLoc fc' rhs)
  substLocClause fc' (WithClause fc lhs rig wval prf flags cs)
      = WithClause fc' (substLoc fc' lhs) rig
                       (substLoc fc' wval)
                       prf
                       flags
                       (map (substLocClause fc') cs)
  substLocClause fc' (ImpossibleClause fc lhs)
      = ImpossibleClause fc' (substLoc fc' lhs)

  substLocData : FC -> ImpData -> ImpData
  substLocData fc' (MkImpData fc n con opts dcons)
      = MkImpData fc' n (map (substLoc fc') con) opts
                        (map (map (substLoc fc') . set "fc" fc') dcons)
  substLocData fc' (MkImpLater fc n con)
      = MkImpLater fc' n (substLoc fc' con)

  substLocDecl : FC -> ImpDecl -> ImpDecl
  substLocDecl fc' (Elaborable_Claim (MkWithData _ $ Make_Elaborable_Claim_Data r vis opts td))
      = Elaborable_Claim (MkFCVal fc' $ Make_Elaborable_Claim_Data r vis opts (map (substLoc fc') (set "fc" fc' td)))
  substLocDecl fc' (Elaborable_Definition fc n cs)
      = Elaborable_Definition fc' n (map (substLocClause fc') cs)
  substLocDecl fc' (Elaborable_Data_Declaration fc vis mbtot d)
      = Elaborable_Data_Declaration fc' vis mbtot (substLocData fc' d)
  substLocDecl fc' (Elaborable_Expected_Failure fc msg ds)
      = Elaborable_Expected_Failure fc' msg (map (substLocDecl fc') ds)
  substLocDecl fc' (Elaborable_Namespace_Block fc ns ds)
      = Elaborable_Namespace_Block fc' ns (map (substLocDecl fc') ds)
  substLocDecl fc' d = d

nameNum : String -> (String, Maybe Int)
nameNum str = case span isDigit (reverse str) of
  ("", _) => (str, Nothing)
  (nums, pre) => case unpack pre of
    ('_' :: rest) => (reverse (pack rest), Just $ cast (reverse nums))
    _ => (str, Nothing)

nextNameNum : (String, Maybe Int) -> (String, Maybe Int)
nextNameNum (str, mn) = (str, Just $ maybe 0 (1+) mn)

unNameNum : (String, Maybe Int) -> String
unNameNum (str, Nothing) = str
unNameNum (str, Just n) = fastConcat [str, "_", show n]


-- TODO use a set of `String`s
export
uniqueBasicName : Defs -> List String -> String -> Core String
uniqueBasicName defs used n
    = if !usedName
         then uniqueBasicName defs used (next n)
         else pure n
  where
    usedName : Core Bool
    usedName
        = pure $ case !(lookupTyName (UN $ Basic n) (gamma defs)) of
                      [] => n `elem` used
                      _ => True

    next : String -> String
    next = unNameNum . nextNameNum . nameNum

export
uniqueHoleName : {auto s : Ref Syn SyntaxInfo} ->
                 Defs -> List String -> String -> Core String
uniqueHoleName defs used n
    = do syn <- get Syn
         uniqueBasicName defs (used ++ holeNames syn) n

export
uniqueHoleNames : {auto s : Ref Syn SyntaxInfo} ->
                  Defs -> Nat -> String -> Core (List String)
uniqueHoleNames defs = go [] where

  go : List String -> Nat -> String -> Core (List String)
  go acc Z _ = pure (reverse acc)
  go acc (S n) hole = do
    hole' <- uniqueHoleName defs acc hole
    go (hole' :: acc) n hole'

-- concatenation of the first two arguments must not be empty, or else we loop forever
unique : List String -> List String -> Int -> List Name -> String
unique [] supply suff usedns = unique supply supply (suff + 1) usedns
unique (str :: next) supply suff usedns
    = let var = mkVarN str suff in
          if UN (Basic var) `elem` usedns
             then unique next supply suff usedns
             else var
  where
    mkVarN : String -> Int -> String
    mkVarN x 0 = x
    mkVarN x i = x ++ show i


export
getArgName : {vars : _} ->
             {auto c : Ref Ctxt Defs} ->
             Defs -> Name ->
             List Name -> -- explicitly bound names (possibly coming later),
                          -- so we don't invent a default
                          -- name that duplicates it
             List Name -> -- names bound so far
             NF vars -> Core String
getArgName defs x bound allvars ty
    = do defnames <- findNames ty
         pure $ getName x defnames allvars
  where
    lookupName : Name -> List (Name, a) -> Core (Maybe a)
    lookupName n [] = pure Nothing
    lookupName n ((n', t) :: ts)
        = if !(getFullName n) == !(getFullName n')
             then pure (Just t)
             else lookupName n ts

    notBound : String -> Bool
    notBound x = not $ UN (Basic x) `elem` bound

    defaultNames : List String
    defaultNames = ["x", "y", "z", "w", "v", "s", "t", "u"]

    namesFor : Name -> Core (Maybe (List String))
    namesFor n = lookupName n (NameMap.toList (namedirectives defs))

    findNamesM : NF vars -> Core (Maybe (List String))
    findNamesM (NBind _ x (Pi {}) _)
        = pure (Just ["f", "g"])
    findNamesM (NTCon _ n d [(_, v)]) = do
          case dropNS !(full (gamma defs) n) of
            UN (Basic "List") =>
              do nf <- evalClosure defs v
                 case !(findNamesM nf) of
                   Nothing => namesFor n
                   Just ns => pure (Just (map (++ "s") ns))
            UN (Basic "Maybe") =>
              do nf <- evalClosure defs v
                 case !(findNamesM nf) of
                   Nothing => namesFor n
                   Just ns => pure (Just (map ("m" ++) ns))
            UN (Basic "SnocList") =>
              do nf <- evalClosure defs v
                 case !(findNamesM nf) of
                   Nothing => namesFor n
                   Just ns => pure (Just (map ("s" ++) ns))
            _ => namesFor n
    findNamesM (NTCon _ n _ _) = namesFor n
    findNamesM (NPrimVal fc $ PrT c) = do
          let defaultPos = ["m", "n", "p", "q"]
          let defaultInts = ["i", "j", "k", "l"]
          pure $ Just $ filter notBound $ case c of
            IntType => defaultInts
            Int8Type => defaultInts
            Int16Type => defaultInts
            Int32Type => defaultInts
            Int64Type => defaultInts
            IntegerType => defaultInts
            Bits8Type => defaultPos
            Bits16Type => defaultPos
            Bits32Type => defaultPos
            Bits64Type => defaultPos
            StringType => ["str"]
            CharType => ["c","d"]
            DoubleType => ["dbl"]
            WorldType => ["wrld", "w"]
    findNamesM ty = pure Nothing

    findNames : NF vars -> Core (List String)
    findNames nf = pure $ filter notBound $ fromMaybe defaultNames !(findNamesM nf)

    getName : Name -> List String -> List Name -> String
    getName (UN (Basic n)) defs used =
      -- # 1742 Uppercase names are not valid for pattern variables
      let candidate = ifThenElse (lowerFirst n) n (toLower n) in
      unique (candidate :: defs) (candidate :: defs) 0 used
    getName _ [] used = unique defaultNames defaultNames 0 $ used ++ bound
    getName _ defs used = unique defs defs 0 used

export
getArgNames : {vars : _} ->
              {auto c : Ref Ctxt Defs} ->
              Defs -> List Name -> List Name -> Env Term vars -> NF vars ->
              Core (List String)
getArgNames defs bound allvars env (NBind fc x (Pi _ _ p ty) sc)
    = do ns <- case p of
                    Explicit => pure [!(getArgName defs x bound allvars !(evalClosure defs ty))]
                    _ => pure []
         sc' <- sc defs (toClosure defaultOpts env (Erased fc Placeholder))
         pure $ ns ++ !(getArgNames defs bound (map (UN . Basic) ns ++ allvars) env sc')
getArgNames defs bound allvars env val = pure []

export
etaExpandImplicits : {auto c : Ref Ctxt Defs} ->
                     {auto u : Ref UST UState} ->
                     FC -> (ty, lhs, rhs : RawImp) ->
                     Core (RawImp, RawImp)
etaExpandImplicits fc ty lhs rhs
    = do let imps = collectImplicits ty
         namedImps <- for imps $ \nm => (nm,) <$> genVarName "arg"
         let lhsArgs = namedImps <&> makeArg True
         let rhsArgs = namedImps <&> makeArg False
         pure (apply lhs lhsArgs, apply rhs rhsArgs)
  where
    collectImplicits : RawImp -> List Name
    collectImplicits (Elaborable_Dependent_Function_Type _ _ Explicit _        _ ty) = []
    collectImplicits (Elaborable_Dependent_Function_Type _ _ _        (Just n) _ ty) = n :: collectImplicits ty
    collectImplicits _                                = []

    ivar : (bind : Bool) -> Name -> RawImp
    ivar True  = Elaborable_Bind_Name fc
    ivar False = Elaborable_Name fc

    makeArg : (bind : Bool) -> (Name, Name) -> Arg
    makeArg bind (n, bindName) = Named fc n $ ivar bind bindName
