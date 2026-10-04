let print_value value =
  match value with
  | Tacky.Constant n ->
      Printf.sprintf "%d" n
  | Tacky.Var name ->
      name

let print_instruction instruction =
  match instruction with
  | Tacky.Return value ->
      Printf.printf "Return %s\n" (print_value value)

  | Tacky.Unary (op, src, dst) ->
      let op_name =
        match op with
        | Tacky.Complement -> "Complement"
        | Tacky.Negate -> "Negate"
        | Tacky.Not -> "Not"
      in

      Printf.printf
        "Unary %s, %s -> %s\n"
        op_name
        (print_value src)
        (print_value dst)

  | Tacky.Binary (op, src1, src2, dst) ->
      let op_name =
        match op with
        | Tacky.Add -> "Add"
        | Tacky.Substract -> "Substract"
        | Tacky.Multiply -> "Multiply"
        | Tacky.Divide -> "Divide"
        | Tacky.Remainder -> "Remainder"
        | Tacky.Equal -> "Equal"
        | Tacky.NotEqual -> "NotEqual"
        | Tacky.LessThan -> "LessThan"
        | Tacky.LessOrEqual -> "LessOrEqual"
        | Tacky.GreaterThan -> "GreaterThan"
        | Tacky.GreaterOrEqual -> "GreaterOrEqual"
      in

      Printf.printf
        "Binary %s, %s, %s -> %s\n"
        op_name
        (print_value src1)
        (print_value src2)
        (print_value dst)

  | Tacky.Copy (src, dst) ->
      Printf.printf
        "Copy %s -> %s\n"
        (print_value src)
        (print_value dst)

  | Tacky.Jump label ->
      Printf.printf "Jump %s\n" label

  | Tacky.JumpIfZero (value, label) ->
      Printf.printf
        "JumpIfZero %s -> %s\n"
        (print_value value)
        label

  | Tacky.JumpIfNotZero (value, label) ->
      Printf.printf
        "JumpIfNotZero %s -> %s\n"
        (print_value value)
        label

  | Tacky.Label label ->
      Printf.printf "Label %s\n" label


let print_program program =
  match program with
  | Tacky.Program (Tacky.Function (name, instructions)) ->
      Printf.printf "Function: %s\n" name;
      List.iter print_instruction instructions


let test expression =
  let ast =
    Ast.Program
      (Ast.Function
        ("main",
         Ast.Return expression))
  in

  let program =
    Tacky.emit_tacky_program ast
  in

  print_program program;
  print_endline ""


let () =
  print_endline "=== NOT ===";

  test
    (Ast.Unary
      (Ast.Not,
       Ast.Constant 5));

  print_endline "=== LESS THAN ===";

  test
    (Ast.Binary
      (Ast.LessThan,
       Ast.Constant 2,
       Ast.Constant 3));

  print_endline "=== AND ===";

  test
    (Ast.Binary
      (Ast.And,
       Ast.Constant 1,
       Ast.Constant 2));

  print_endline "=== OR ===";

  test
    (Ast.Binary
      (Ast.Or,
       Ast.Constant 0,
       Ast.Constant 2));

    print_endline "=== NESTED LOGICAL === "; 

    test
      (Ast.Binary
        (Ast.Or, 
         Ast.Constant 2, 
         Ast.Binary
           (Ast.And, 
            Ast.Constant 3,
            Ast.Binary
              (Ast.Equal,
               Ast.Constant 4,
               Ast.Constant 4))))