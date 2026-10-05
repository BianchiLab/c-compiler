(* -------------------------------------------------------------------------- *)
(* Lexer errors                                                               *)
(* -------------------------------------------------------------------------- *)

exception Lexer_error of string


(* -------------------------------------------------------------------------- *)
(* Tokens                                                                     *)
(* -------------------------------------------------------------------------- *)

type token =
  | Int
  | Void
  | Return
  | Identifier of string
  | Constant of int
  | OpenParen
  | CloseParen
  | OpenBrace
  | CloseBrace
  | Semicolon


(* -------------------------------------------------------------------------- *)
(* Character classification                                                   *)
(* -------------------------------------------------------------------------- *)

(* Whitespace is ignored by the lexer. *)
let is_whitespace = function
  | ' ' | '\t' | '\n' | '\r' -> true
  | _ -> false


(* Integer constants consist only of decimal digits. *)
let is_digit = function
  | '0' .. '9' -> true
  | _ -> false


(* Identifiers must begin with a letter or underscore. *)
let is_letter = function
  | 'a' .. 'z'
  | 'A' .. 'Z'
  | '_' -> true
  | _ -> false


(* After the first character, identifiers may also contain digits. *)
let is_identifier_char c =
  is_letter c || is_digit c


(* -------------------------------------------------------------------------- *)
(* Identifier classification                                                  *)
(* -------------------------------------------------------------------------- *)

(* Keywords are lexed like identifiers first, then classified here. *)
let classify_identifier text =
  match text with
  | "int" -> Int
  | "void" -> Void
  | "return" -> Return
  | _ -> Identifier text


(* -------------------------------------------------------------------------- *)
(* Tokenization                                                               *)
(* -------------------------------------------------------------------------- *)

let tokenize input =
  (* Find the position where an integer constant ends. *)
  let rec scan_number i =
    if i < String.length input && is_digit input.[i] then
      scan_number (i + 1)
    else
      i
  in

  (* Find the position where an identifier ends. *)
  let rec scan_identifier i =
    if i < String.length input && is_identifier_char input.[i] then
      scan_identifier (i + 1)
    else
      i
  in

  (* Skip a // comment through the end of the line. *)
  let rec scan_line_comment i =
    if i >= String.length input then
      i
    else if input.[i] = '\n' then
      i
    else
      scan_line_comment (i + 1)
  in

  (* Skip a /* comment through the closing */. *)
  let rec scan_block_comment i =
    if i + 1 >= String.length input then
      raise (Lexer_error "unterminated comment")
    else if input.[i] = '*' && input.[i + 1] = '/' then
      i + 2
    else
      scan_block_comment (i + 1)
  in

  (* Scan the input from left to right, building the token list. *)
  let rec loop i tokens =
    if i >= String.length input then
      List.rev tokens

    (* Ignore whitespace. *)
    else if is_whitespace input.[i] then
      loop (i + 1) tokens

    (* Skip // comments. *)
    else if input.[i] = '/'
         && i + 1 < String.length input
         && input.[i + 1] = '/'
    then
      loop (scan_line_comment (i + 2)) tokens

    (* Skip /* comments. *)
    else if input.[i] = '/'
         && i + 1 < String.length input
         && input.[i + 1] = '*'
    then
      loop (scan_block_comment (i + 2)) tokens

    (* Integer constant. *)
    else if is_digit input.[i] then
      let end_pos = scan_number (i + 1) in

      (* A number cannot be immediately followed by an identifier
         character. For example, "123abc" is invalid. *)
      if end_pos < String.length input
         && is_identifier_char input.[end_pos]
      then
        raise (Lexer_error "invalid number")
      else
        let text =
          String.sub input i (end_pos - i)
        in

        let value =
          int_of_string text
        in

        loop end_pos (Constant value :: tokens)

    (* Identifier or keyword. *)
    else if is_letter input.[i] then
      let end_pos =
        scan_identifier (i + 1)
      in

      let text =
        String.sub input i (end_pos - i)
      in

      loop end_pos (classify_identifier text :: tokens)

    (* Punctuation. *)
    else
      match input.[i] with
      | '(' ->
          loop (i + 1) (OpenParen :: tokens)

      | ')' ->
          loop (i + 1) (CloseParen :: tokens)

      | '{' ->
          loop (i + 1) (OpenBrace :: tokens)

      | '}' ->
          loop (i + 1) (CloseBrace :: tokens)

      | ';' ->
          loop (i + 1) (Semicolon :: tokens)

      (* Anything else is an invalid token. *)
      | _ ->
          raise (Lexer_error "unsupported character")
  in

  loop 0 []
