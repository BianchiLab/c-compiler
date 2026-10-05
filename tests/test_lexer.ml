let () =
  match Lexer.tokenize "12345" with
  | [Lexer.Constant 12345] ->
      print_endline "Correct integer constant"

  | _ ->
      failwith "Unexpected integer token"

let () =
  match Lexer.tokenize "foo123" with 
  | [Lexer.Identifier "foo123"] ->
      print_endline "Correct identifier with digits" 
    
  | _ ->
      failwith "Unexpected identifier with digits" 

let () =
  match Lexer.tokenize "hello" with
  | [Lexer.Identifier "hello"] ->
      print_endline "Correct identifier"

  | _ ->
      failwith "Unexpected identifier token"


let () = 
  match Lexer.tokenize "_hello" with 
  | [Lexer.Identifier "_hello"] -> 
      print_endline "Correct identifier with underscore" 

  | _ -> 
      failwith "Unexpected identifier with underscore" 



let () =
  match Lexer.tokenize "int" with
  | [Lexer.Int] ->
      print_endline "Correct int keyword"

  | _ ->
      failwith "Unexpected int keyword"


let () =
  match Lexer.tokenize "void" with
  | [Lexer.Void] ->
      print_endline "Correct void keyword"

  | _ ->
      failwith "Unexpected void keyword"


let () =
  match Lexer.tokenize "return" with
  | [Lexer.Return] ->
      print_endline "Correct return keyword"

  | _ ->
      failwith "Unexpected return keyword"


let () = 
  try 
    ignore (Lexer.tokenize "@");
    failwith "Expected lexer error" 

  with 
  | Lexer.Lexer_error _ -> 
      print_endline "Correctly rejected invalid character" 


let () = 
  try 
    ignore (Lexer.tokenize "123abc");
    failwith "Expected lexer error" 

  with 
  | Lexer.Lexer_error _ -> 
      print_endline "Correctly rejected invalid number" 

let () =
  match Lexer.tokenize "123;" with 
  | [Lexer.Constant 123; Lexer.Semicolon] -> 
      print_endline "Correctly accepted number before punctuation"

  | _ -> 
      failwith "Unexpected tokens" 


let () =
  match Lexer.tokenize "// comment\n123" with
  | [Lexer.Constant 123] ->
      print_endline "Correctly ignored line comment"
  | _ ->
      failwith "Unexpected tokens after line comment"


let () =
  match Lexer.tokenize "/* comment */ 123" with
  | [Lexer.Constant 123] ->
      print_endline "Correctly ignored block comment"
  | _ ->
      failwith "Unexpected tokens after block comment"


let () =
  try
    ignore (Lexer.tokenize "/* unterminated");
    failwith "Expected lexer error"
  with
  | Lexer.Lexer_error _ ->
      print_endline "Correctly rejected unterminated comment"