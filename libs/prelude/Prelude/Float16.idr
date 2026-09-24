module Prelude.Float16

import Builtin
import Prelude.Basics
import Prelude.EqOrd
import Prelude.Interpolation
import Prelude.Num
import Prelude.Show
import Prelude.Types

%default total

||| Idriç's ordinary floating value. The Prelude carrier is the compiler's
||| primitive floating value, not an inherited wider floating primitive.
||| Every constructor and arithmetic operation rounds through the IEEE-754
||| binary16 boundary. A later compiler slice can make binary16 itself a core
||| primitive without changing this source-level contract.
public export
record Float16 where
  constructor MkFloat16
  float16Carrier : Float

private
asFloat : Integer -> Float
asFloat = prim__cast_IntegerFloat

private
half : Float
half = assert_total (prim__div_Float (asFloat 1) (asFloat 2))

||| Find the integer floor of a nonnegative primitive floating value inside a
||| known integer interval. The recursion depth is supplied explicitly so the
||| Prelude never needs a floating-to-integer primitive.
private
floorBounded : Nat -> Integer -> Integer -> Float -> Integer
floorBounded Z lower upper value = lower
floorBounded (S fuel) lower upper value =
  let width = prim__sub_Integer upper lower in
    if width <= 1
       then lower
       else
         let midpoint = prim__add_Integer
                          lower
                          (assert_total (prim__div_Integer width 2))
             midpointValue = asFloat midpoint in
           if midpointValue <= value
              then floorBounded fuel midpoint upper value
              else floorBounded fuel lower midpoint value

private
roundNearestEven : Float -> Integer
roundNearestEven value =
  let lower = floorBounded 12 0 2048 value
      lowerValue = asFloat lower
      fraction = prim__sub_Float value lowerValue in
    if fraction < half
       then lower
       else if fraction > half
               then prim__add_Integer lower 1
               else if assert_total (prim__mod_Integer lower 2) == 0
                       then lower
                       else prim__add_Integer lower 1

||| Return the binary16 unit in the last place for a positive finite value.
||| The recursive bound is fixed by the binary16 exponent range.
private
halfStep : Nat -> Float -> Float -> Float
halfStep Z value threshold =
  assert_total (prim__div_Float (asFloat 1) (asFloat 16777216)) -- 2^-24
halfStep (S fuel) value threshold =
  if value >= threshold
     then assert_total (prim__div_Float threshold (asFloat 1024))
     else halfStep fuel value
                   (assert_total (prim__div_Float threshold (asFloat 2)))

private
quantizeFloat16Carrier : Float -> Float
quantizeFloat16Carrier value =
  if value /= value
     then value -- preserve NaN
     else if value == asFloat 0
             then value -- preserve signed zero
             else
               let negative = value < asFloat 0
                   magnitude = if negative then prim__negate_Float value else value in
                 if magnitude >= asFloat 65520
                    then let infinity = assert_total
                                          (prim__div_Float (asFloat 1) (asFloat 0)) in
                           if negative then prim__negate_Float infinity else infinity
                    else
                      let step = halfStep 29 magnitude (asFloat 32768)
                          scaled = assert_total (prim__div_Float magnitude step)
                          rounded = roundNearestEven scaled
                          roundedValue = prim__mul_Float (asFloat rounded) step in
                        if negative
                           then prim__negate_Float roundedValue
                           else roundedValue

||| Explicitly pass a primitive floating value through the binary16 rounding
||| boundary. The `.idric` lexer uses this for decimal literals.
public export
idricFloat16 : Float -> Float16
idricFloat16 value = MkFloat16 (quantizeFloat16Carrier value)

public export
Num Float16 where
  (MkFloat16 left) + (MkFloat16 right) =
    idricFloat16 (prim__add_Float left right)
  (MkFloat16 left) * (MkFloat16 right) =
    idricFloat16 (prim__mul_Float left right)
  fromInteger value = idricFloat16 (asFloat value)

public export
Neg Float16 where
  negate (MkFloat16 value) = idricFloat16 (prim__negate_Float value)
  (MkFloat16 left) - (MkFloat16 right) =
    idricFloat16 (prim__sub_Float left right)

public export
Abs Float16 where
  abs (MkFloat16 value) =
    if value < asFloat 0
       then idricFloat16 (prim__negate_Float value)
       else MkFloat16 value

public export
Fractional Float16 where
  (MkFloat16 left) / (MkFloat16 right) =
    idricFloat16 (assert_total (prim__div_Float left right))

public export
Eq Float16 where
  (MkFloat16 left) == (MkFloat16 right) = left == right

public export
Ord Float16 where
  (MkFloat16 left) < (MkFloat16 right) = left < right
  (MkFloat16 left) <= (MkFloat16 right) = left <= right
  (MkFloat16 left) > (MkFloat16 right) = left > right
  (MkFloat16 left) >= (MkFloat16 right) = left >= right

private
fractionDigits : Nat -> Float -> String
fractionDigits Z fraction = ""
fractionDigits (S fuel) fraction =
  let scaled = prim__mul_Float fraction (asFloat 10)
      digit = floorBounded 4 0 10 scaled
      rest = prim__sub_Float scaled (asFloat digit) in
    show digit ++ fractionDigits fuel rest

private
stripLeadingZeros : List Char -> List Char
stripLeadingZeros ('0' :: rest) = stripLeadingZeros rest
stripLeadingZeros rest = rest

private
trimTrailingZeros : String -> String
trimTrailingZeros digits =
  let trimmed = reverse (stripLeadingZeros (reverse (unpack digits))) in
    case trimmed of
      [] => "0"
      _ => pack trimmed

||| Format the binary16 value without routing through the inherited wide
||| floating primitive. Eight fractional decimal digits are enough to
||| distinguish every finite binary16 value; trailing zeroes are removed.
private
showFloat16Carrier : Float -> String
showFloat16Carrier value =
  if value /= value
     then "NaN"
     else
       let infinity = assert_total (prim__div_Float (asFloat 1) (asFloat 0)) in
         if value == infinity
            then "Infinity"
            else if value == prim__negate_Float infinity
                    then "-Infinity"
                    else
                      let negative = value < asFloat 0
                          magnitude = if negative then prim__negate_Float value else value
                          whole = floorBounded 17 0 65536 magnitude
                          fraction = prim__sub_Float magnitude (asFloat whole)
                          sign = if negative then "-" else ""
                          decimals = trimTrailingZeros (fractionDigits 8 fraction) in
                        sign ++ show whole ++ "." ++ decimals


private
superDigit : Char -> Char
superDigit '0' = '⁰'
superDigit '1' = '¹'
superDigit '2' = '²'
superDigit '3' = '³'
superDigit '4' = '⁴'
superDigit '5' = '⁵'
superDigit '6' = '⁶'
superDigit '7' = '⁷'
superDigit '8' = '⁸'
superDigit '9' = '⁹'
superDigit c = c

private
subDigit : Char -> Char
subDigit '0' = '₀'
subDigit '1' = '₁'
subDigit '2' = '₂'
subDigit '3' = '₃'
subDigit '4' = '₄'
subDigit '5' = '₅'
subDigit '6' = '₆'
subDigit '7' = '₇'
subDigit '8' = '₈'
subDigit '9' = '₉'
subDigit c = c

private
mapDigits : (Char -> Char) -> Integer -> String
mapDigits f value = pack (map f (unpack (show value)))

private
commonVulgar : Integer -> Integer -> Maybe String
commonVulgar 1 2 = Just "½"
commonVulgar 1 4 = Just "¼"
commonVulgar 3 4 = Just "¾"
commonVulgar 1 8 = Just "⅛"
commonVulgar 3 8 = Just "⅜"
commonVulgar 5 8 = Just "⅝"
commonVulgar 7 8 = Just "⅞"
commonVulgar _ _ = Nothing

private
vulgar : Integer -> Integer -> String
vulgar numerator denominator =
  case commonVulgar numerator denominator of
    Just glyph => glyph
    Nothing =>
      mapDigits superDigit numerator ++ "⁄" ++ mapDigits subDigit denominator

private
dyadicFraction :
  Nat -> Float -> Integer -> Integer -> (Integer, Integer)
dyadicFraction Z fraction numerator denominator = (numerator, denominator)
dyadicFraction (S fuel) fraction numerator denominator =
  if fraction == asFloat 0
     then (numerator, denominator)
     else
       let doubled = prim__mul_Float fraction (asFloat 2)
           bit = if doubled >= asFloat 1 then 1 else 0
           rest = prim__sub_Float doubled (asFloat bit)
       in dyadicFraction fuel rest
            (prim__add_Integer (prim__mul_Integer numerator 2) bit)
            (prim__mul_Integer denominator 2)

||| Human-facing exact rendering of a binary16 value. Finite non-integral
||| values are shown as vulgar dyadic fractions rather than decimal digits.
||| This is presentation only: Show remains the canonical machine/debug text.
export
displayFloat16 : Float16 -> String
displayFloat16 (MkFloat16 value) =
  if value /= value
     then "NaN"
     else
       let infinity = assert_total (prim__div_Float (asFloat 1) (asFloat 0)) in
         if value == infinity
            then "∞"
            else if value == prim__negate_Float infinity
                    then "−∞"
                    else
                      let negative = value < asFloat 0
                          magnitude = if negative then prim__negate_Float value else value
                          whole = floorBounded 17 0 65536 magnitude
                          fraction = prim__sub_Float magnitude (asFloat whole)
                          (fractionNumerator, denominator) =
                            dyadicFraction 24 fraction 0 1
                          numerator =
                            prim__add_Integer
                              (prim__mul_Integer whole denominator)
                              fractionNumerator
                          sign = if negative then "−" else ""
                      in if denominator == 1
                            then sign ++ show numerator
                            else sign ++ vulgar numerator denominator

export
Interpolation Float16 where
  interpolate = displayFloat16

export
Show Float16 where
  showPrec _ (MkFloat16 value) = showFloat16Carrier value
