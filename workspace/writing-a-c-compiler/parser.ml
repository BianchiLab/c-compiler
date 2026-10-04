open Lexer

let expect expected tokens =
  match tokens with
  | actual :: rest ->
      if actual = expected then
        rest
      else
        failwith "Syntax error"
  | [] ->
      failwith "Unexpected end of input"


let precedence token =
  match token with
  | Asterisk
  | Slash
  | Percent ->
      50

  | Plus
  | Minus ->
      45

  | LessThan
  | LessEqual
  | GreaterThan 
  | GreaterEqual -> 
      35

  | EqualEqual
  | NotEqual ->
      30 

  | And -> 
      10 
  
  | Or ->
      5 
  | Equal ->
      1 

  | _ ->
      -1


let parse_binop token =
  match token with
  | Plus ->
      Ast.Add

  | Minus ->
      Ast.Substract

  | Asterisk ->
      Ast.Multiply

  | Slash ->
      Ast.Divide

  | Percent ->
      Ast.Remainder

  | And -> 
      Ast.And 
  
  | Or -> 
      Ast.Or 

  | EqualEqual -> 
      Ast.Equal 

  | NotEqual -> 
      Ast.NotEqual 

  | LessThan -> 
      Ast.LessThan

  | LessEqual -> 
      Ast.LessOrEqual

  | GreaterThan -> 
      Ast.GreaterThan

  | _ ->
      failwith "Not a binary operator"


let rec parse_factor tokens =
  match tokens with
  | Constant n :: rest ->
      (Ast.Constant n, rest)

  | Identifier name :: rest -> 
      (Ast.Var name, rest)

  | Minus :: rest ->
      let (inner_exp, remaining) =
        parse_factor rest
      in

      (Ast.Unary (Ast.Negate, inner_exp), remaining)

  | Tilde :: rest ->
      let (inner_exp, remaining) =
        parse_factor rest
      in

      (Ast.Unary (Ast.Complement, inner_exp), remaining)

  | Bang :: rest -> 
      let (inner_exp, remaining) = 
        parse_factor rest 
      in 

      (Ast.Unary (Ast.Not, inner_exp), remaining)

  | LeftParen :: rest ->
      let (inner_exp, remaining) =
        parse_exp rest 0
      in

      let remaining =
        expect RightParen remaining
      in

      (inner_exp, remaining)

  | _ ->
      failwith "Malformed factor"

and parse_exp tokens min_prec =
  let (left, tokens) =
    parse_factor tokens
  in

  parse_binary left tokens min_prec


and parse_binary left tokens min_prec =
  match tokens with
  | token :: rest
    when precedence token >= min_prec ->
      let prec =
        precedence token 
      in 

      if token = Equal then 
        let (right, remaining) = 
          parse_exp rest prec 
        in 
        let new_left = 
          Ast.Assignment (left, right)
        in 
        parse_binary new_left remaining min_prec

    else 
      let operator =
        parse_binop token
      in

      let (right, remaining) =
        parse_exp rest (prec + 1)
      in

      let new_left =
        Ast.Binary (operator, left, right)
      in

      parse_binary new_left remaining min_prec

  | _ ->
      (left, tokens)

let parse_statement tokens =
  match tokens with
  | Return :: rest ->
      let (return_val, tokens) =
        parse_exp rest 0
      in
      let tokens =
        expect Semicolon tokens
      in
      (Ast.Return return_val, tokens)

  | Semicolon :: rest ->
      (Ast.Null, rest)

  | _ ->
      let (expression, tokens) =
        parse_exp tokens 0
      in
      let tokens =
        expect Semicolon tokens
      in
      (Ast.Expression expression, tokens)

let parse_declaration tokens = 
  let tokens = 
    expect Int tokens 
  in 

  match tokens with 
  | Identifier name :: rest -> 
      begin 
        match rest with 
        | Equal :: rest -> 
            let (init_exp, tokens) =
              parse_exp rest 0 
            in 

            let tokens = 
              expect Semicolon tokens 
            in 

            (Ast.Declaration (name, Some init_exp), tokens)
        
        | _ -> 
            let tokens =
              expect Semicolon rest 
            in 

            (Ast.Declaration (name, None), tokens)
      end 

| _ ->
    failwith "Expected Identifier in declaration" 

let rec parse_block_items tokens =
  match tokens with 
  | RightBrace :: _ -> 
      ([], tokens)

  | Int :: _ -> 
      let (declaration, tokens) =
        parse_declaration tokens 
      in 
 
      let (rest, tokens) =
        parse_block_items tokens 
      in 

      (Ast.D declaration :: rest, tokens) 
  
  | _ ->
      let (statement, tokens) = 
        parse_statement tokens 
      in 

      let (rest, tokens) = 
        parse_block_items tokens 
      in 

      (Ast.S statement :: rest, tokens)

let parse_function tokens = 
  let tokens = 
    expect Int tokens 
  in 

  let (name, tokens) =
    match tokens with 
    | Identifier name :: rest ->
        (name, rest)
    
    | _ ->
        failwith "Expected function name" 
  in 

  let tokens = 
    expect LeftParen tokens 
  in 

  let tokens = 
    expect Void tokens 
  in 

  let tokens =
    expect RightParen tokens 
  in 
  
  let tokens = 
    expect LeftBrace tokens 
  in 

  let (body, tokens) = 
    parse_block_items tokens 
  in 

  let tokens = 
    expect RightBrace tokens 
  in 

  (Ast.Function (name, body), tokens)

let parse_program tokens =
  let (function_def, tokens) =
    parse_function tokens
  in

  match tokens with
  | [] ->
      Ast.Program function_def

  | _ ->
      failwith "Unexpected tokens after function"

let () =
  let tokens =
    [
      Return;
      Constant 2;
      Or;
      Constant 3;
      And;
      Constant 4;
      EqualEqual;
      Constant 4;
      Semicolon;
    ]
  in

  let (statement, remaining) =
    parse_statement tokens
  in

  match statement with
  | Ast.Return
      (Ast.Binary
        (Ast.Or,
         Ast.Constant 2,
         Ast.Binary
           (Ast.And,
            Ast.Constant 3,
            Ast.Binary
              (Ast.Equal,
               Ast.Constant 4,
               Ast.Constant 4)))) ->

      Printf.printf
        "Correct AST: 2 || (3 && (4 == 4))\n";

      Printf.printf
        "Remaining tokens: %d\n"
        (List.length remaining)

  | _ ->
      failwith "Unexpected AST"


let () = 
  let tokens = 
    [
      Identifier "x"; 
    ]
  in 

  let (expression, remaining) = 
    parse_exp tokens 0 
  in 

  match expression with 
  | Ast.Var "x" ->
      print_endline "Correct AST: Var x\n";

      Printf.printf 
        "Remaining tokens: %d\n" 
        (List.length remaining)

  | _ -> 
      failwith "Unexpected AST" 


let () =
  let tokens = 
    [
      Semicolon; 
    ]
  in 

  let (statement, remaining) = 
    parse_statement tokens 
  in 

  match statement with 
  | Ast.Null -> 
      print_endline "Correct AST: null statement"; 

      Printf.printf
        "Remaining tokens: %d\n" 
        (List.length remaining)

  | _ ->
      failwith "Unexpected AST" 

  
let () = 
  let tokens = 
    [
      Identifier "x"; 
      Equal; 
      Constant 5; 
      Semicolon; 
    ]
  in 

  let (statement, remaining) = 
    parse_statement tokens 
  in 

  match statement with 
  | Ast.Expression
      (Ast.Assignment (Ast.Var "x", Ast.Constant 5)) ->
        print_endline "Correct AST: x = 5;"; 

        Printf.printf 
        "Remaining tokens: %d\n" 
        (List.length remaining)

  | _ ->
      failwith "Unexpected AST" 


let () =
  let tokens = 
    [
      Return; 
      Constant 5; 
      Semicolon; 

      Semicolon; 

      Identifier "x";
      Equal; 
      Constant 10; 
      Semicolon; 

      RightBrace;
    ]
  in 

  let (items, remaining) = 
    parse_block_items tokens
  in 

  match items with 
  | [
    Ast.S (Ast.Return (Ast.Constant 5)); 
    Ast.S Ast.Null; 
    Ast.S 
      (Ast.Expression
        (Ast.Assignment (Ast.Var "x", Ast.Constant 10)));
  ] ->
    print_endline "Correct block items"; 
    Printf.printf
      "Remaining tokens: %d\n" 
      (List.length remaining)
  | _ ->
      failwith "Unexpected block AST" 

let () =
  let tokens =
    [
      Int; 
      Identifier "x";
      Semicolon; 
    ]
  in 

  let (declaration, remaining) =
    parse_declaration tokens 
  in 

  match declaration with 
  | Ast.Declaration ("x", None) ->
      print_endline "Correct AST: int x;"; 
    
      Printf.printf
        "Remaining tokens: %d\n"
        (List.length remaining)
  
  | _ -> failwith "Unexpected declaration AST" 


let () =
  let tokens =
    [
      Int; 
      Identifier "x";
      Equal; 
      Constant 5; 
      Semicolon; 
    ]
  in 

  let (declaration, remaining) =
    parse_declaration tokens 
  in 

  match declaration with 
  | Ast.Declaration ("x", Some (Ast.Constant 5)) ->
      print_endline "Correct AST: int x = 5;"; 

      Printf.printf
        "Remaining tokens: %d\n" 
        (List.length remaining)
  
  | _ -> 
    failwith "Unexpected declaration AST" 


let () =
  let tokens = 
    [
      Int; 
      Identifier "x"; 
      Equal; 
      Constant 5; 
      Semicolon; 

      Identifier "x"; 
      Equal;
      Constant 10; 
      Semicolon; 

      Return;
      Identifier "x";
      Semicolon; 

      RightBrace;
    ]
  in 

  let (items, remaining) =
    parse_block_items tokens 
  in 

  match items with 
  | [
      Ast.D
        (Ast.Declaration ("x", Some (Ast.Constant 5))); 

      Ast.S 
        (Ast.Expression
          (Ast.Assignment (Ast.Var "x", Ast.Constant 10)));

      Ast.S 
        (Ast.Return (Ast.Var "x"));
  ] ->
    print_endline "Correct mixed block"; 
    Printf.printf
      "Remaining tokens: %d\n" 
      (List.length remaining) 

| _ -> 
    failwith "Unexpected block AST" 


let () = 
  let tokens =
    [
      Int; 
      Identifier "main";
      LeftParen; 
      Void;
      RightParen; 
      LeftBrace;

      Int; 
      Identifier "x"; 
      Equal;
      Constant 5; 
      Semicolon; 

      Return; 
      Identifier "x";
      Semicolon; 

      RightBrace
    ]
  in 

  let (function_def, remaining) = 
    parse_function tokens 
  in 

  match function_def with 
  | Ast.Function
      ("main",
        [
          Ast.D 
            (Ast.Declaration ("x", Some (Ast.Constant 5))); 

            Ast.S 
              (Ast.Return (Ast.Var "x")); 
        ] ) -> 
      print_endline "Correct function AST"; 
      Printf.printf 
        "Remaining tokens: %d\n"
        (List.length remaining)

  | _ -> 
      failwith "Unexpected function AST" 

