let () =
  let instructions =
    [ Assembly.Mov (Assembly.Imm 8, Assembly.Stack (-4));

      Assembly.Unary (Assembly.Neg, Assembly.Stack (-4));

      Assembly.Mov (Assembly.Imm 10, Assembly.Stack (-8));

      Assembly.Mov (Assembly.Stack (-4), Assembly.Stack (-8));

      Assembly.Ret;
    ]
  in
  let fixed_instructions = Tacky.fix_assembly instructions 8 in
  List.iter
    (fun instruction ->
      match instruction with
      | Assembly.AllocateStack n -> Printf.printf "AllocateStack(%d)\n" n

      | Assembly.Mov (Assembly.Imm n, Assembly.Stack offset) ->
        Printf.printf "Mov $%d -> Stack(%d)\n" n offset

      | Assembly.Unary (Assembly.Neg, Assembly.Stack offset) ->
        Printf.printf "Neg Stack(%d)\n" offset

      | Assembly.Mov (Assembly.Stack src, Assembly.Reg Assembly.R10) ->
        Printf.printf "Mov Stack(%d) -> R10\n" src

      | Assembly.Mov (Assembly.Reg Assembly.R10, Assembly.Stack dst) ->
        Printf.printf "Mov R10 -> Stack(%d)\n" dst

      | Assembly.Ret -> Printf.printf "Ret\n"

      | _ -> Printf.printf "Other instruction\n")
    fixed_instructions