let emit_operand operand = 
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
    
  | Assembly.Stack offset -> 
      Printf.sprintf "%d(%%rbp)" offset 

  | Assembly.Pseudo name -> 
      failwith 
        ("Cannot emit pseudo-register: " ^ name)

let emit_byte_operand operand =
  match operand with
  | Assembly.Reg Assembly.AX ->
      "%al"
  | Assembly.Reg Assembly.DX ->
      "%dl"
  | Assembly.Reg Assembly.R10 ->
      "%r10b"
  | Assembly.Reg Assembly.R11 ->
      "%r11b"
  | Assembly.Stack offset ->
      Printf.sprintf "%d(%%rbp)" offset
  | _ ->
      failwith "Invalid operand for setcc"

let emit_condition_code condition = 
  match condition with 
  | Assembly.E ->
      "e"
  | Assembly.NE ->
      "ne"
  | Assembly.G ->
      "g"
  | Assembly.GE ->
      "ge"
  | Assembly.L -> 
      "l"
  | Assembly.LE ->
      "le" 


let emit_instruction instruction =
  match instruction with 
  | Assembly.Mov (src, dst) -> 
      Printf.sprintf
        "\tmovl %s, %s" 
        (emit_operand src)
        (emit_operand dst)
      
  | Assembly.Unary (Assembly.Neg, operand) ->
      Printf.sprintf
        "\tnegl %s"
        (emit_operand operand)

  | Assembly.Unary (Assembly.Not, operand) -> 
      Printf.sprintf
        "\tnotl %s"
        (emit_operand operand)

  | Assembly.Binary (Assembly.Add, src, dst) ->
      Printf.sprintf
        "\taddl %s, %s"

        (emit_operand src)
        (emit_operand dst)

  | Assembly.Binary (Assembly.Sub, src, dst) ->
      Printf.sprintf
        "\tsubl %s, %s" 
        (emit_operand src)  
        (emit_operand dst)  

  | Assembly.Binary (Assembly.Mul, src, dst) ->
      Printf.sprintf
        "\tnull %s, %s" 
        (emit_operand src)
        (emit_operand dst)

  | Assembly.Cmp (src, dst) ->
      Printf.sprintf
        "\tcmpl %s, %s"
        (emit_operand src)
        (emit_operand dst)

  | Assembly.Set (condition, operand) ->
      Printf.sprintf
      "\tset%s %s"
      (emit_condition_code condition)
      (emit_byte_operand operand)

  | Assembly.Jump label ->
      Printf.sprintf
      "\tjmp .L%s"
      label 
  
  | Assembly.JumpIf (condition, label) ->
      Printf.sprintf
        "\tj%s .L%s" 
        (emit_condition_code condition)
        label

  | Assembly.Label label ->
      Printf.sprintf
      ".L%s:"
      label

  | Assembly.Idiv operand -> 
      Printf.sprintf 
        "\tidivl %s" 
        (emit_operand operand)

  | Assembly.Cdq -> 
    "\tcdq" 
    
  | Assembly.AllocateStack n -> 
      Printf.sprintf
        "\tsubq $%d, %%rsp"
        n

  | Assembly.Ret -> 
      "\tmovq %rbp, %rsp\n\tpopq %rbp\n\tret" 


let emit_function name instructions = 
  let emitted_instructions =
    List.map emit_instruction instructions 
    |> String.concat "\n"
  in 

  Printf.sprintf
   ".globl %s\n%s:\n\tpushq %%rbp\n\tmovq %%rsp, %%rbp\n%s"
    name 
    name 
    emitted_instructions
  
let emit_program program = 
  match program with
  | Assembly.Program 
      (Assembly.Function (name, instructions)) -> 

      let output =
        emit_function name instructions
      in 

      output
      ^ "\n.section .note.GNU-stack, \"\", @progbits\n" 

