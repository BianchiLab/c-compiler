open Assembly 

let ()= 
  let instructions = 
    [
        Mov (Imm 8, Pseudo "tmp.0"); 
        Unary (Neg, Pseudo "tmp.0"); 
        Ret; 
    ]
  in 


match instructions with 
| [
    Mov (Imm n, Pseudo name); 
    Unary (Neg, Pseudo unary_name);
    Ret
] -> 
  Printf.printf
    "Move: %d -> %s\nUnary Neg: %s\nReturn\n" 
    n 
    name
    unary_name

| _ -> 
    failwith "Unexpected assembly AST" 

