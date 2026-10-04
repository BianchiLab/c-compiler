type token =
  | Int
  | Void
  | Return
  | Identifier of string
  | Constant of int
  | LeftParen
  | RightParen
  | LeftBrace
  | RightBrace
  | Semicolon
  | Tilde
  | Minus
  | Decrement
  | Plus 
  | Asterisk 
  | Slash 
  | Percent 
  | Bang
  | And 
  | Or 
  | Equal 
  | EqualEqual
  | NotEqual 
  | LessThan 
  | GreaterThan 
  | LessEqual 
  | GreaterEqual 

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
  | _ -> Identifier s

let tokenize input =
  let length = String.length input in

  let rec scan pos tokens =
    if pos >= length then
      List.rev tokens
    else
      let c = input.[pos] in

      if is_whitespace c then
        scan (pos + 1) tokens

      else if c = '(' then
        scan (pos + 1) (LeftParen :: tokens)
      
      else if c = ')' then 
        scan (pos + 1) (RightParen :: tokens)
      
      else if c = '{' then 
        scan (pos + 1) (LeftBrace :: tokens)

      else if c = '}' then 
        scan (pos + 1) (RightBrace :: tokens)

      else if c = ';' then 
        scan (pos + 1) (Semicolon :: tokens)
   
      else if c = '~' then
        scan (pos + 1) (Tilde :: tokens)

      else if c = '-' then
        if pos + 1 < length && input.[pos + 1] = '-' then
          scan (pos + 2) (Decrement :: tokens)
        else
          scan (pos + 1) (Minus :: tokens)

      else if c = '+' then 
        scan (pos + 1) (Plus :: tokens)

      else if c = '*' then 
        scan (pos + 1) (Asterisk :: tokens)
      
      else if c = '/' then 
        scan (pos + 1) (Slash :: tokens)

            else if c = '%' then 
        scan (pos + 1) (Percent :: tokens)

      else if c = '!' then
        if pos + 1 < length && input.[pos + 1] = '=' then
          scan (pos + 2) (NotEqual :: tokens)
        else
          scan (pos + 1) (Bang :: tokens)

      else if c = '&' then
        if pos + 1 < length && input.[pos + 1] = '&' then
          scan (pos + 2) (And :: tokens)
        else
          failwith "Unknown character"

      else if c = '|' then
        if pos + 1 < length && input.[pos + 1] = '|' then
          scan (pos + 2) (Or :: tokens)
        else
          failwith "Unknown character"

      else if c = '=' then
        if pos + 1 < length && input.[pos + 1] = '=' then
          scan (pos + 2) (EqualEqual :: tokens)
        else
          scan (pos + 1) (Equal :: tokens)

      else if c = '<' then
        if pos + 1 < length && input.[pos + 1] = '=' then
          scan (pos + 2) (LessEqual :: tokens)
        else
          scan (pos + 1) (LessThan :: tokens)

      else if c = '>' then
        if pos + 1 < length && input.[pos + 1] = '=' then
          scan (pos + 2) (GreaterEqual :: tokens)
        else
          scan (pos + 1) (GreaterThan :: tokens)

      else if is_letter c then

    let start = pos in

    let rec scan_identifier pos =
      if pos < length && is_identifier_char input.[pos] then
        scan_identifier (pos + 1)
      else
        pos
    in

    let end_pos = scan_identifier pos in
    let name = String.sub input start (end_pos - start) in

    scan end_pos (keyword_or_identifier name :: tokens)

  else if is_digit c then
    let start = pos in

    let rec scan_number pos =
      if pos < length && is_digit input.[pos] then
        scan_number (pos + 1)
      else
        pos
    in

    let end_pos = scan_number pos in
    let number =
      int_of_string (String.sub input start (end_pos - start))
    in

    scan end_pos (Constant number :: tokens)

  else
    failwith "Unknown character"
    in

    scan 0 []

(*
let () = 
  let filename = Sys.argv.(2) in 

  let channel = open_in filename in 
  let input = really_input_string channel (in_channel_length channel) in 
  close_in channel; 

  let _tokens = tokenize input in 

  ()
*)