let instructions =
  [
    Assembly.Mov
      (Assembly.Pseudo "tmp.0", Assembly.Pseudo "tmp.1");

    Assembly.Cmp
      (Assembly.Pseudo "tmp.0", Assembly.Pseudo "tmp.1");

    Assembly.Set
      (Assembly.L, Assembly.Pseudo "tmp.1");

    Assembly.Ret
  ]

let (instructions, stack_size) =
  Tacky.replace_pseudoregisters instructions

let instructions =
  Tacky.fix_assembly instructions stack_size

let string_of_operand operand =
  match operand with
  | Assembly.Imm n ->
      Printf.sprintf "$%d" n
  | Assembly.Reg Assembly.AX ->
      "%eax"
  | Assembly.Reg Assembly.DX ->
      "%edx"
  | Assembly.Reg Assembly.R10 ->
      "%r10d"
  | Assembly.Reg Assembly.R11 ->
      "%r11d"
  | Assembly.Stack n ->
      Printf.sprintf "%d(%%rbp)" n
  | Assembly.Pseudo name ->
      name

let () =
  List.iter
    (fun instruction ->
      match instruction with
      | Assembly.AllocateStack n ->
          Printf.printf "AllocateStack(%d)\n" n

      | Assembly.Mov (src, dst) ->
          Printf.printf
            "Mov %s -> %s\n"
            (string_of_operand src)
            (string_of_operand dst)

      | Assembly.Cmp (src, dst) ->
          Printf.printf
            "Cmp %s -> %s\n"
            (string_of_operand src)
            (string_of_operand dst)

      | Assembly.Set (condition, operand) ->
          Printf.printf
            "Set %s -> %s\n"
            (match condition with
             | Assembly.E -> "E"
             | Assembly.NE -> "NE"
             | Assembly.G -> "G"
             | Assembly.GE -> "GE"
             | Assembly.L -> "L"
             | Assembly.LE -> "LE")
            (string_of_operand operand)

      | Assembly.Ret ->
          Printf.printf "Ret\n"

      | _ ->
          Printf.printf "Other\n")
    instructions