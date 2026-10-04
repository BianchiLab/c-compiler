let () =
  let tokens =
    Lexer.tokenize "! && || == != < > <= >="
  in

  List.iter
    (fun token ->
      match token with
      | Lexer.Bang -> print_endline "Bang"
      | Lexer.And -> print_endline "And"
      | Lexer.Or -> print_endline "Or"
      | Lexer.EqualEqual -> print_endline "EqualEqual"
      | Lexer.NotEqual -> print_endline "NotEqual"
      | Lexer.LessThan -> print_endline "LessThan"
      | Lexer.GreaterThan -> print_endline "GreaterThan"
      | Lexer.LessEqual -> print_endline "LessEqual"
      | Lexer.GreaterEqual -> print_endline "GreaterEqual"
      | _ -> print_endline "Other")
    tokens