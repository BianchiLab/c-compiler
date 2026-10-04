let run command =
  let status = Sys.command command in
  if status <> 0 then exit 1

let () =
  if Array.length Sys.argv < 2 then begin
    prerr_endline "usage: mycc <file.c>";
    exit 1
  end;

  let input = Sys.argv.(1) in
  let preprocessed = "hello.i" in
  let assembly = "hello.s" in
  let output = "hello" in

  (* 1. Preprocess *)
  run
    (Printf.sprintf
       "gcc -E -P %s -o %s"
       input preprocessed);

  (* 2. Compile -- STUB FOR NOW *)
  let oc = open_out assembly in
  output_string oc
    ".global main\n\
     main:\n\
     \tmov $42, %eax\n\
     \tret\n";
  close_out oc;

  (* 3. Assemble and link *)
  run
    (Printf.sprintf
       "gcc %s -o %s"
       assembly output);

  (* Delete temporary files *)
  Sys.remove preprocessed;
  Sys.remove assembly