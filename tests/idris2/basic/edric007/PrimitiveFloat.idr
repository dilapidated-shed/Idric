module PrimitiveFloat

main : IO ()
main =
  let two = prim__cast_IntegerFloat 2
      left : Float
      left = assert_total (prim__div_Float (prim__cast_IntegerFloat 3) two)
      right : Float
      right = assert_total (prim__div_Float (prim__cast_IntegerFloat 9)
                                            (prim__cast_IntegerFloat 4))
      expected : Float
      expected = assert_total (prim__div_Float (prim__cast_IntegerFloat 15)
                                               (prim__cast_IntegerFloat 4)) in
    if prim__eq_Float (prim__add_Float left right) expected == 1
       then putStrLn "primitive-float: PASS"
       else putStrLn "primitive-float: FAIL"
