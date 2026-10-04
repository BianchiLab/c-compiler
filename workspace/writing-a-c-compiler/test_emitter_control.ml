let () =
  let instructions =
    [
      Assembly.Cmp
        (Assembly.Imm 0, Assembly.Stack (-4));

      Assembly.Set
        (Assembly.E, Assembly.Stack (-4));

      Assembly.Jump "end";

      Assembly.Label "true";

      Assembly.JumpIf
        (Assembly.NE, "true");

      Assembly.Label "end";
    ]
  in

  List.iter
    (fun instruction ->
      print_endline (Emitter.emit_instruction instruction))
    instructions