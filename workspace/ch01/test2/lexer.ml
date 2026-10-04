type token = 
    | Int
    | Void 
    | Return 
    | Identifer of string 
    | Constant of int 
    | LeftParen 
    | RightParen 
    | LeftBrace 
    | RightBrace
    | Semicolon 

let is_whitespace c =
  c = ' ' || c = '\n' || c = '\t' || c = '\r' 

let is_letter c = 
  ('a' <= c && c <= 'z') || 
  ('A' <= c && c <= 'Z') || 
  c = '_' 

let is_digit c =
  '0' <= c && c <= '9' 

let is_identifier_char c = 
  is_letter c || is_digit c

let keyword_or_identifier s = 
  match s with 
  | "int" -> Int 
  | "void" -> Void 
  | "return" -> Return
  | _ -> Identifer s 

let () = 
  let input = "int main(void) { return 42; }" in 
  Printf.printf "input: %s\n" input 

let () = 
  print_endline "Lexer is running!"