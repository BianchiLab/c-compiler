let () =
  let operands = 
    [
        Assembly.Imm 8; 
        Assembly.Reg Assembly.AX; 
        Assembly.Reg Assembly.R10; 
        Assembly.Stack (-4);
        Assembly.Stack (-12); 
    ]
  in 

  List.iter 
    (fun operand ->
      Printf.printf "%s\n"
        (Emitter.emit_operand operand))
    operands
