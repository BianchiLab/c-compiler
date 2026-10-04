open Tacky
open Assembly

let () =
  let tacky_program =
    Tacky.Program
      (Tacky.Function
        ("main",
         [
           Tacky.Binary
             (Tacky.Multiply,
              Tacky.Constant 3,
              Tacky.Constant 4,
              Tacky.Var "tmp.0");

           Tacky.Binary
             (Tacky.Add,
              Tacky.Constant 2,
              Tacky.Var "tmp.0",
              Tacky.Var "tmp.1");

           Tacky.Return (Tacky.Var "tmp.1");
         ]))
  in

  let assembly_program =
    Tacky.convert_program tacky_program
  in

  match assembly_program with
  | Assembly.Program
      (Assembly.Function (name, instructions)) ->

      Printf.printf "Function: %s\n" name;
      Printf.printf "Instructions: %d\n" (List.length instructions);

      List.iter
        (fun instruction ->
          match instruction with

          | Assembly.Mov
              (Assembly.Imm n, Assembly.Pseudo name) ->
              Printf.printf
                "Mov $%d -> %s\n"
                n
                name

          | Assembly.Binary
              (Assembly.Mul, src, Assembly.Pseudo name) ->
              Printf.printf
                "Mul %s, %s\n"
                (match src with
                 | Assembly.Imm n -> Printf.sprintf "$%d" n
                 | Assembly.Pseudo s -> s
                 | _ -> "?")
                name

          | Assembly.Binary
              (Assembly.Add, src, Assembly.Pseudo name) ->
              Printf.printf
                "Add %s, %s\n"
                (match src with
                 | Assembly.Imm n -> Printf.sprintf "$%d" n
                 | Assembly.Pseudo s -> s
                 | _ -> "?")
                name

          | Assembly.Mov
              (Assembly.Pseudo name, Assembly.Reg Assembly.AX) ->
              Printf.printf
                "Mov %s -> AX\n"
                name

          | Assembly.Ret ->
              Printf.printf "Ret\n"

          | _ ->
              Printf.printf "Other instruction\n")
        instructions