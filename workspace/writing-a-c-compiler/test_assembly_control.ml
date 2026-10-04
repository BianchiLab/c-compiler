let print_instruction instruction =
  match instruction with
  | Assembly.Cmp (src, dst) ->
      Printf.printf "Cmp %s, %s\n"
        (match src with
         | Assembly.Imm n -> Printf.sprintf "$%d" n
         | Assembly.Reg Assembly.AX -> "%eax"
         | Assembly.Reg Assembly.DX -> "%edx"
         | Assembly.Reg Assembly.R10 -> "%r10d"
         | Assembly.Reg Assembly.R11 -> "%r11d"
         | Assembly.Stack n -> Printf.sprintf "%d(%%rbp)" n
         | Assembly.Pseudo name -> name)
        (match dst with
         | Assembly.Imm n -> Printf.sprintf "$%d" n
         | Assembly.Reg Assembly.AX -> "%eax"
         | Assembly.Reg Assembly.DX -> "%edx"
         | Assembly.Reg Assembly.R10 -> "%r10d"
         | Assembly.Reg Assembly.R11 -> "%r11d"
         | Assembly.Stack n -> Printf.sprintf "%d(%%rbp)" n
         | Assembly.Pseudo name -> name)

  | Assembly.Set (condition, operand) ->
      let condition_name =
        match condition with
        | Assembly.E -> "E"
        | Assembly.NE -> "NE"
        | Assembly.G -> "G"
        | Assembly.GE -> "GE"
        | Assembly.L -> "L"
        | Assembly.LE -> "LE"
      in
      Printf.printf "Set %s -> %s\n"
        condition_name
        (match operand with
         | Assembly.Pseudo name -> name
         | Assembly.Stack n -> Printf.sprintf "Stack(%d)" n
         | Assembly.Reg Assembly.AX -> "AX"
         | Assembly.Reg Assembly.DX -> "DX"
         | Assembly.Reg Assembly.R10 -> "R10"
         | Assembly.Reg Assembly.R11 -> "R11"
         | Assembly.Imm n -> Printf.sprintf "Imm(%d)" n)

  | Assembly.Jump label ->
      Printf.printf "Jump -> %s\n" label

  | Assembly.JumpIf (condition, label) ->
      let condition_name =
        match condition with
        | Assembly.E -> "E"
        | Assembly.NE -> "NE"
        | Assembly.G -> "G"
        | Assembly.GE -> "GE"
        | Assembly.L -> "L"
        | Assembly.LE -> "LE"
      in
      Printf.printf "JumpIf %s -> %s\n"
        condition_name label

  | Assembly.Label label ->
      Printf.printf "Label %s\n" label

let () =
  let instructions = [
    Assembly.Cmp
      (Assembly.Imm 5, Assembly.Pseudo "tmp.0");

    Assembly.Set
      (Assembly.L, Assembly.Pseudo "tmp.1");

    Assembly.JumpIf
      (Assembly.E, "equal_label");

    Assembly.Jump "end_label";

    Assembly.Label "equal_label";

    Assembly.Set
      (Assembly.E, Assembly.Pseudo "tmp.1");

    Assembly.Label "end_label";
  ] in

  List.iter print_instruction instructions