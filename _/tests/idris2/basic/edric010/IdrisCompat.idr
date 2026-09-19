module IdrisCompat

export
idris_text_equal : String -> String -> Bool
idris_text_equal left right = left == right
