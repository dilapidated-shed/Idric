module IdrisCompat

import Data.String

joined→⇒←≤name : Integer
joined→⇒←≤name = 11

export
idris_compat_value : Integer
idris_compat_value = joined→⇒←≤name

export
idris_string_module_words : List String
idris_string_module_words = Data.String.words "Idris keeps Data.String"
