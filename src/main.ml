let preprocess input_file =
  let preprocessed_file =
    input_file ^ ".i"
  in

  let command =
    Printf.sprintf
      "gcc -E -P %s -o %s"
      input_file
      preprocessed_file
  in

  let exit_code =
    Sys.command command
  in

  if exit_code <> 0 then
    failwith "Preprocessing failed";

  preprocessed_file

let compile _preprocessed_file =
  failwith "Compiler not implemented yet"

let assemble_and_link assembly_file output_file =
  let command =
    Printf.sprintf
      "gcc %s -o %s"
      assembly_file
      output_file
  in

  let exit_code =
    Sys.command command
  in

  if exit_code <> 0 then
    failwith "Assembly/linking failed"


(* -------------------------------------------------------------------------- *)
(* Compiler driver                                                            *)
(* -------------------------------------------------------------------------- *)

let run_compiler input_file =
  try
    let preprocessed_file =
      preprocess input_file
    in

    let assembly_file =
      compile preprocessed_file
    in

    let output_file =
      Filename.chop_extension input_file
    in

    assemble_and_link assembly_file output_file;

    Sys.remove assembly_file

  with
  | Failure message ->
      prerr_endline message;
      exit 1


(* -------------------------------------------------------------------------- *)
(* Lexer test                                                                 *)
(* -------------------------------------------------------------------------- *)

let run_lexer filename =
  let input =
    In_channel.with_open_text filename In_channel.input_all
  in

  try
    ignore (Lexer.tokenize input)
  with
  | Lexer.Lexer_error message ->
      prerr_endline ("lexer error: " ^ message);
      exit 1


(* -------------------------------------------------------------------------- *)
(* Entry point                                                                *)
(* -------------------------------------------------------------------------- *)

let () =
  match Array.to_list Sys.argv with
  | [_; "--lex"; filename] ->
      run_lexer filename

  | [_; input_file] ->
      run_compiler input_file

  | _ ->
      prerr_endline "Usage: Compiler SOURCE_FILE";
      exit 1