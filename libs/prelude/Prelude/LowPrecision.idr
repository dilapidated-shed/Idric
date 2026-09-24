module Prelude.LowPrecision

import Builtin
import Prelude.Basics
import Prelude.Display
import Prelude.EqOrd
import Prelude.Float16
import Prelude.Interpolation
import Prelude.Num
import Prelude.Show
import Prelude.Types

%default total

-- Source semantics for compact floating formats.  The carrier is the compiler's
-- primitive binary32 Float.  E4M3, E5M2, and E3M2 arithmetic widens one
-- operation to that carrier and immediately quantizes back.  Storage layout is
-- deliberately not exposed here; direct backends may use the actual narrow
-- payloads.

private
as_float : Integer -> Float
as_float = prim__cast_IntegerFloat

private
float_divide : Float -> Float -> Float
float_divide left right = assert_total (prim__div_Float left right)

private
zero : Float
zero = as_float 0

private
half : Float
half = float_divide (as_float 1) (as_float 2)

private
floor_bounded : Nat -> Integer -> Integer -> Float -> Integer
floor_bounded Z lower upper value = lower
floor_bounded (S fuel) lower upper value =
  let width = prim__sub_Integer upper lower in
    if width <= 1
       then lower
       else
         let midpoint =
               prim__add_Integer
                 lower
                 (assert_total (prim__div_Integer width 2))
             midpoint_value = as_float midpoint in
           if midpoint_value <= value
              then floor_bounded fuel midpoint upper value
              else floor_bounded fuel lower midpoint value

private
round_nearest_even : Float -> Integer
round_nearest_even value =
  let lower = floor_bounded 6 0 32 value
      lower_value = as_float lower
      fraction = prim__sub_Float value lower_value in
    if fraction < half
       then lower
       else if fraction > half
               then prim__add_Integer lower 1
               else if assert_total (prim__mod_Integer lower 2) == 0
                       then lower
                       else prim__add_Integer lower 1

-- Starting at the largest normal power-of-two bin, walk down to the bin that
-- contains the magnitude.  At the bottom, the same step also covers
-- subnormals.
private
step_for : Nat -> Float -> Float -> Float -> Float
step_for Z magnitude threshold significand_divisor =
  float_divide threshold significand_divisor
step_for (S fuel) magnitude threshold significand_divisor =
  if magnitude >= threshold
     then float_divide threshold significand_divisor
     else step_for fuel magnitude
            (float_divide threshold (as_float 2))
            significand_divisor

private
quantize_signed :
  (nan_to_zero : Bool) ->
  (step_fuel : Nat) ->
  (largest_bin : Float) ->
  (significand_divisor : Float) ->
  (maximum_finite : Float) ->
  Float -> Float
quantize_signed nan_to_zero step_fuel largest_bin significand_divisor
                maximum_finite value =
  if value /= value
     then if nan_to_zero then zero else value
     else if value == zero
             then value
             else
               let negative = value < zero
                   magnitude =
                     if negative then prim__negate_Float value else value
                   bounded =
                     if magnitude >= maximum_finite
                        then maximum_finite
                        else
                          let step =
                                step_for step_fuel magnitude largest_bin
                                  significand_divisor
                              scaled = float_divide magnitude step
                              rounded = round_nearest_even scaled
                              rounded_value =
                                prim__mul_Float (as_float rounded) step
                          in if rounded_value > maximum_finite
                                then maximum_finite
                                else rounded_value
               in if negative then prim__negate_Float bounded else bounded

private
dyadic_fraction :
  Nat -> Float -> Integer -> Integer -> (Integer, Integer)
dyadic_fraction Z fraction numerator denominator = (numerator, denominator)
dyadic_fraction (S fuel) fraction numerator denominator =
  if fraction == zero
     then (numerator, denominator)
     else
       let doubled = prim__mul_Float fraction (as_float 2)
           bit = if doubled >= as_float 1 then 1 else 0
           rest = prim__sub_Float doubled (as_float bit)
       in dyadic_fraction fuel rest
            (prim__add_Integer (prim__mul_Integer numerator 2) bit)
            (prim__mul_Integer denominator 2)

private
finite_fraction : Float -> (Bool, Integer, Integer)
finite_fraction value =
  let negative = value < zero
      magnitude = if negative then prim__negate_Float value else value
      whole = floor_bounded 19 0 262144 magnitude
      fraction = prim__sub_Float magnitude (as_float whole)
      (fraction_numerator, denominator) =
        dyadic_fraction 24 fraction 0 1
      numerator =
        prim__add_Integer
          (prim__mul_Integer whole denominator)
          fraction_numerator
  in (negative, numerator, denominator)

private
show_carrier : Float -> String
show_carrier value =
  if value /= value
     then "NaN"
     else
       let infinity = float_divide (as_float 1) zero in
         if value == infinity
            then "Infinity"
            else if value == prim__negate_Float infinity
                    then "-Infinity"
                    else
                      let (negative, numerator, denominator) =
                            finite_fraction value
                          sign = if negative then "-" else ""
                      in if denominator == 1
                            then sign ++ show numerator
                            else sign ++ show numerator ++ "/" ++ show denominator

private
super_digit : Char -> Char
super_digit '0' = '⁰'
super_digit '1' = '¹'
super_digit '2' = '²'
super_digit '3' = '³'
super_digit '4' = '⁴'
super_digit '5' = '⁵'
super_digit '6' = '⁶'
super_digit '7' = '⁷'
super_digit '8' = '⁸'
super_digit '9' = '⁹'
super_digit c = c

private
sub_digit : Char -> Char
sub_digit '0' = '₀'
sub_digit '1' = '₁'
sub_digit '2' = '₂'
sub_digit '3' = '₃'
sub_digit '4' = '₄'
sub_digit '5' = '₅'
sub_digit '6' = '₆'
sub_digit '7' = '₇'
sub_digit '8' = '₈'
sub_digit '9' = '₉'
sub_digit c = c

private
map_digits : (Char -> Char) -> Integer -> String
map_digits f value = pack (map f (unpack (show value)))

private
common_vulgar : Integer -> Integer -> Maybe String
common_vulgar 1 2 = Just "½"
common_vulgar 1 4 = Just "¼"
common_vulgar 3 4 = Just "¾"
common_vulgar 1 8 = Just "⅛"
common_vulgar 3 8 = Just "⅜"
common_vulgar 5 8 = Just "⅝"
common_vulgar 7 8 = Just "⅞"
common_vulgar _ _ = Nothing

private
vulgar : Integer -> Integer -> String
vulgar numerator denominator =
  case common_vulgar numerator denominator of
    Just glyph => glyph
    Nothing =>
      map_digits super_digit numerator ++
      "⁄" ++
      map_digits sub_digit denominator

private
display_carrier : Float -> String
display_carrier value =
  if value /= value
     then "NaN"
     else
       let infinity = float_divide (as_float 1) zero in
         if value == infinity
            then "∞"
            else if value == prim__negate_Float infinity
                    then "−∞"
                    else
                      let (negative, numerator, denominator) =
                            finite_fraction value
                          sign = if negative then "−" else ""
                      in if denominator == 1
                            then sign ++ show numerator
                            else sign ++ vulgar numerator denominator


-- OCP OFP8 E4M3 -------------------------------------------------------------

public export
record E4M3 where
  constructor MkE4M3
  e4m3_carrier : Float

public export
e4m3_from_float : Float -> E4M3
e4m3_from_float value =
  MkE4M3
    (quantize_signed False 14 (as_float 256) (as_float 8)
      (as_float 448) value)

public export
e4m3 : Float16 -> E4M3
e4m3 (MkFloat16 value) = e4m3_from_float value

public export
e4m3_to_float : E4M3 -> Float
e4m3_to_float (MkE4M3 value) = value

public export
e4m3_to_float16 : E4M3 -> Float16
e4m3_to_float16 (MkE4M3 value) = idricFloat16 value

public export
e4m3_add : E4M3 -> E4M3 -> E4M3
e4m3_add (MkE4M3 left) (MkE4M3 right) =
  e4m3_from_float (prim__add_Float left right)

public export
e4m3_subtract : E4M3 -> E4M3 -> E4M3
e4m3_subtract (MkE4M3 left) (MkE4M3 right) =
  e4m3_from_float (prim__sub_Float left right)

public export
e4m3_multiply : E4M3 -> E4M3 -> E4M3
e4m3_multiply (MkE4M3 left) (MkE4M3 right) =
  e4m3_from_float (prim__mul_Float left right)

public export
e4m3_divide : E4M3 -> E4M3 -> E4M3
e4m3_divide (MkE4M3 left) (MkE4M3 right) =
  e4m3_from_float (float_divide left right)

public export
Num E4M3 where
  (+) = e4m3_add
  (*) = e4m3_multiply
  fromInteger value = e4m3_from_float (as_float value)

public export
Neg E4M3 where
  negate (MkE4M3 value) = e4m3_from_float (prim__negate_Float value)
  (-) = e4m3_subtract

public export
Abs E4M3 where
  abs (MkE4M3 value) =
    if value < zero
       then e4m3_from_float (prim__negate_Float value)
       else MkE4M3 value

public export
Fractional E4M3 where
  (/) = e4m3_divide

public export
Eq E4M3 where
  (MkE4M3 left) == (MkE4M3 right) = left == right

public export
Ord E4M3 where
  (MkE4M3 left) < (MkE4M3 right) = left < right
  (MkE4M3 left) <= (MkE4M3 right) = left <= right
  (MkE4M3 left) > (MkE4M3 right) = left > right
  (MkE4M3 left) >= (MkE4M3 right) = left >= right

export
Show E4M3 where
  showPrec _ (MkE4M3 value) = show_carrier value

export
Display E4M3 where
  display (MkE4M3 value) = display_carrier value

export
Interpolation E4M3 where
  interpolate = display


-- OCP OFP8 E5M2 -------------------------------------------------------------

public export
record E5M2 where
  constructor MkE5M2
  e5m2_carrier : Float

public export
e5m2_from_float : Float -> E5M2
e5m2_from_float value =
  MkE5M2
    (quantize_signed False 29 (as_float 32768) (as_float 4)
      (as_float 57344) value)

public export
e5m2 : Float16 -> E5M2
e5m2 (MkFloat16 value) = e5m2_from_float value

public export
e5m2_to_float : E5M2 -> Float
e5m2_to_float (MkE5M2 value) = value

public export
e5m2_to_float16 : E5M2 -> Float16
e5m2_to_float16 (MkE5M2 value) = idricFloat16 value

public export
e5m2_add : E5M2 -> E5M2 -> E5M2
e5m2_add (MkE5M2 left) (MkE5M2 right) =
  e5m2_from_float (prim__add_Float left right)

public export
e5m2_subtract : E5M2 -> E5M2 -> E5M2
e5m2_subtract (MkE5M2 left) (MkE5M2 right) =
  e5m2_from_float (prim__sub_Float left right)

public export
e5m2_multiply : E5M2 -> E5M2 -> E5M2
e5m2_multiply (MkE5M2 left) (MkE5M2 right) =
  e5m2_from_float (prim__mul_Float left right)

public export
e5m2_divide : E5M2 -> E5M2 -> E5M2
e5m2_divide (MkE5M2 left) (MkE5M2 right) =
  e5m2_from_float (float_divide left right)

public export
Num E5M2 where
  (+) = e5m2_add
  (*) = e5m2_multiply
  fromInteger value = e5m2_from_float (as_float value)

public export
Neg E5M2 where
  negate (MkE5M2 value) = e5m2_from_float (prim__negate_Float value)
  (-) = e5m2_subtract

public export
Abs E5M2 where
  abs (MkE5M2 value) =
    if value < zero
       then e5m2_from_float (prim__negate_Float value)
       else MkE5M2 value

public export
Fractional E5M2 where
  (/) = e5m2_divide

public export
Eq E5M2 where
  (MkE5M2 left) == (MkE5M2 right) = left == right

public export
Ord E5M2 where
  (MkE5M2 left) < (MkE5M2 right) = left < right
  (MkE5M2 left) <= (MkE5M2 right) = left <= right
  (MkE5M2 left) > (MkE5M2 right) = left > right
  (MkE5M2 left) >= (MkE5M2 right) = left >= right

export
Show E5M2 where
  showPrec _ (MkE5M2 value) = show_carrier value

export
Display E5M2 where
  display (MkE5M2 value) = display_carrier value

export
Interpolation E5M2 where
  interpolate = display


-- OCP MX FP6 E3M2 -----------------------------------------------------------

public export
record E3M2 where
  constructor MkE3M2
  e3m2_carrier : Float

public export
e3m2_from_float : Float -> E3M2
e3m2_from_float value =
  MkE3M2
    (quantize_signed True 6 (as_float 16) (as_float 4)
      (as_float 28) value)

public export
e3m2 : Float16 -> E3M2
e3m2 (MkFloat16 value) = e3m2_from_float value

public export
e3m2_to_float : E3M2 -> Float
e3m2_to_float (MkE3M2 value) = value

public export
e3m2_to_float16 : E3M2 -> Float16
e3m2_to_float16 (MkE3M2 value) = idricFloat16 value

public export
e3m2_add : E3M2 -> E3M2 -> E3M2
e3m2_add (MkE3M2 left) (MkE3M2 right) =
  e3m2_from_float (prim__add_Float left right)

public export
e3m2_subtract : E3M2 -> E3M2 -> E3M2
e3m2_subtract (MkE3M2 left) (MkE3M2 right) =
  e3m2_from_float (prim__sub_Float left right)

public export
e3m2_multiply : E3M2 -> E3M2 -> E3M2
e3m2_multiply (MkE3M2 left) (MkE3M2 right) =
  e3m2_from_float (prim__mul_Float left right)

public export
e3m2_divide : E3M2 -> E3M2 -> E3M2
e3m2_divide (MkE3M2 left) (MkE3M2 right) =
  e3m2_from_float (float_divide left right)

public export
Num E3M2 where
  (+) = e3m2_add
  (*) = e3m2_multiply
  fromInteger value = e3m2_from_float (as_float value)

public export
Neg E3M2 where
  negate (MkE3M2 value) = e3m2_from_float (prim__negate_Float value)
  (-) = e3m2_subtract

public export
Abs E3M2 where
  abs (MkE3M2 value) =
    if value < zero
       then e3m2_from_float (prim__negate_Float value)
       else MkE3M2 value

public export
Fractional E3M2 where
  (/) = e3m2_divide

public export
Eq E3M2 where
  (MkE3M2 left) == (MkE3M2 right) = left == right

public export
Ord E3M2 where
  (MkE3M2 left) < (MkE3M2 right) = left < right
  (MkE3M2 left) <= (MkE3M2 right) = left <= right
  (MkE3M2 left) > (MkE3M2 right) = left > right
  (MkE3M2 left) >= (MkE3M2 right) = left >= right

export
Show E3M2 where
  showPrec _ (MkE3M2 value) = show_carrier value

export
Display E3M2 where
  display (MkE3M2 value) = display_carrier value

export
Interpolation E3M2 where
  interpolate = display


-- Ootomo-Naruse unsigned E5M3 ----------------------------------------------

public export
record E5M3 where
  constructor MkE5M3
  e5m3_carrier : Float

private
quantize_e5m3 : Float -> Maybe Float
quantize_e5m3 value =
  let minimum = float_divide (as_float 1) (as_float 32768)
      limit = as_float 131072 in
    if value /= value
       then Nothing
       else if value < minimum || value >= limit
               then Nothing
               else
                 let step = step_for 31 value (as_float 65536) (as_float 8)
                     scaled = float_divide value step
                     lower = floor_bounded 5 0 16 scaled
                     midpoint =
                       prim__mul_Float
                         (prim__add_Float (as_float lower) half)
                         step
                 in Just midpoint

||| Construct the unsigned Ootomo-Naruse E5M3 storage value when the input is
||| in the format's positive normal source domain.  Zero, negative values,
||| infinities, NaNs, and out-of-range values are rejected rather than assigned
||| invented semantics.
public export
e5m3_from_float : Float -> Maybe E5M3
e5m3_from_float value =
  case quantize_e5m3 value of
    Nothing => Nothing
    Just stored => Just (MkE5M3 stored)

public export
e5m3 : Float16 -> Maybe E5M3
e5m3 (MkFloat16 value) = e5m3_from_float value

public export
e5m3_to_float : E5M3 -> Float
e5m3_to_float (MkE5M3 value) = value

public export
Eq E5M3 where
  (MkE5M3 left) == (MkE5M3 right) = left == right

public export
Ord E5M3 where
  (MkE5M3 left) < (MkE5M3 right) = left < right
  (MkE5M3 left) <= (MkE5M3 right) = left <= right
  (MkE5M3 left) > (MkE5M3 right) = left > right
  (MkE5M3 left) >= (MkE5M3 right) = left >= right

export
Show E5M3 where
  showPrec _ (MkE5M3 value) = show_carrier value

export
Display E5M3 where
  display (MkE5M3 value) = display_carrier value

export
Interpolation E5M3 where
  interpolate = display
