let () = 
  let instructions = 
    [
        Assembly.Mov 
          (Assembly.Imm 8, Assembly.Stack (-4)); 

        Assembly.Unary
          (Assembly.Neg, Assembly.Stack (-4)); 

        Assembly.Unary
          (Assembly.Not, Assembly.Stack (-4)); 

        Assembly.Binary
          (Assembly.Add,
            Assembly.Reg Assembly.R10, 
          Assembly.Stack (-8)); 

        Assembly.Binary
          (Assembly.Sub, 
           Assembly.Imm 2, 
           Assembly.Stack (-8)); 

        Assembly.Cdq; 

        Assembly.Idiv
          (Assembly.Reg Assembly.R10); 

        Assembly.AllocateStack 8; 

        Assembly.Mov 
          (Assembly.Stack (-4), Assembly.Reg Assembly.R10);

        Assembly.Mov 
          (Assembly.Reg Assembly.R10, Assembly.Stack(-8)); 

        Assembly.Ret; 
    ]
  in

  List.iter
    (fun instruction ->
      Printf.printf "%s\n"
        (Emitter.emit_instruction instruction))
      instructions