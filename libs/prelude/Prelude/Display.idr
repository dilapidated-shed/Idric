module Prelude.Display

%default total

||| Human-facing presentation. Unlike Show, this interface is allowed to choose
||| notation for readability: mathematical glyphs, vulgar fractions, compact
||| units, and other display conventions. It must not be used as a serialization
||| format.
public export
interface Display ty where
  constructor MkDisplay
  display : ty -> String

export
Display String where
  display value = value
