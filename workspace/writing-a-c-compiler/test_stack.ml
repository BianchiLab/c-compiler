let () =
  let instructions =
    [ Assembly.Mov (Assembly.Imm 8, Assembly.Pseudo "tmp.0");

      Assembly.Unary (Assembly.Neg, Assembly.Pseudo "tmp.0");

      Assembly.Mov (Assembly.Imm 10, Assembly.Pseudo "tmp.1");

      Assembly.Mov (Assembly.Pseudo "tmp.0", Assembly.Pseudo "tmp.1");

      Assembly.Ret;
    ]
  in
  let new_instructions, final_offset =
    Tacky.replace_pseudoregisters instructions
  in
  List.iter
    (fun instruction ->
      match instruction with
      | Assembly.Mov (Assembly.Imm n, Assembly.Stack offset) ->
        Printf.printf "Mov $%d -> Stack(%d)\n" n offset

      | Assembly.Unary (Assembly.Neg, Assembly.Stack offset) ->
        Printf.printf "Neg stack(%d)\n" offset

      | Assembly.Mov (Assembly.Stack src, Assembly.Stack dst) ->
        Printf.printf "Mov Stack(%d) -> Stack(%d)\n" src dst

      | Assembly.Ret -> Printf.printf "Ret\n"

      | _ -> Printf.printf "Other instruction\n")
    new_instructions;
  Printf.printf "Final offset: %d\n" final_offset