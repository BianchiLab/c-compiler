let () = 
  let program = 
    Assembly.Program
      (Assembly.Function
        ("main",
          [
            Assembly.AllocateStack 8; 

            Assembly.Mov
              (Assembly.Imm 8, Assembly.Stack(-4)); 

            Assembly.Unary
              (Assembly.Neg, Assembly.Stack(-4)); 

            Assembly.Mov
              (Assembly.Stack (-4), Assembly.Reg Assembly.AX); 

            Assembly.Ret; 
          ]))
    in

    Printf.printf
      "%s"
      (Emitter.emit_program program)
