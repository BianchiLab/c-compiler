module StringMap = Map.Make(String)

type variable_map = string StringMap.t

let counter = ref 0

let make_unique_name name =
  let unique_name =
    Printf.sprintf "%s.%d" name !counter
  in

  incr counter;

  unique_name


let resolve_declaration declaration map =
  match declaration with
  | Ast.Declaration (name, init_exp) ->

      if StringMap.mem name map then
        failwith "Duplicate variable declaration"

      else
        let unique_name =
          make_unique_name name
        in

        let map =
          StringMap.add name unique_name map
        in

        (Ast.Declaration (unique_name, init_exp), map)

let rec resolve_exp exp map = 
  match exp with 
  | Ast.Constant n -> 
      Ast.Constant n 
    
  | Ast.Var name ->
      begin 
        match StringMap.find_opt name map with 
        | Some unique_name ->
            Ast.Var unique_name

        | None -> 
            failwith "Undeclared Variable" 
    end 

  | Ast.Unary (operator, inner_exp) ->
      let resolved_exp =
        resolve_exp inner_exp map 
      in 

      Ast.Unary (operator, resolved_exp)
    
  | Ast.Binary (operator, left, right) ->
      let resolved_left = 
        resolve_exp left map 
      in 

      let resolved_right = 
        resolve_exp right map 
      in 

      Ast.Binary (operator, resolved_left, resolved_right) 

  | Ast.Assignment (left, right) ->
      begin 
        match left with 
        | Ast.Var name -> 
            let resolved_left = 
              resolve_exp left map 
            in 

            let resolved_right = 
              resolve_exp right map 
            in 

            Ast.Assignment (resolved_left, resolved_right)
        | _ ->
            failwith "Invalid assigment target" 
      end 

let () =
  let map = StringMap.empty in

  let unique_x = make_unique_name "x" in
  let map = StringMap.add "x" unique_x map in

  let unique_y = make_unique_name "y" in
  let map = StringMap.add "y" unique_y map in

  Printf.printf "x -> %s\n" (StringMap.find "x" map);
  Printf.printf "y -> %s\n" (StringMap.find "y" map)


let () =
  counter := 0

let () =
  let map = StringMap.empty in

  let declaration =
    Ast.Declaration ("x", None)
  in

  let (resolved, map) =
    resolve_declaration declaration map
  in

  match resolved with
  | Ast.Declaration ("x.0", None) ->
      print_endline "Correct declaration resolution";

      Printf.printf
        "x -> %s\n"
        (StringMap.find "x" map)

  | _ ->
      failwith "Unexpected resolved declaration"


let () = 
  counter := 0; 

  let map = StringMap.empty in 

  let map = 
    StringMap.add "x" "x.0" map 
  in 

  let expression =
    Ast.Var "x" 
  in 

  let resolved = 
    resolve_exp expression map 
  in 

  match resolved with 
  | Ast.Var "x.0" -> 
      print_endline "Correct variable resolution" 

  | _ ->
      failwith "Unexpected resolved expression" 


let () =
  let map = StringMap.empty in 

  let expression = 
    Ast.Var "y" 
  in 

  try 
    let _ = 
      resolve_exp expression map 
    in 

    failwith "Expected undeclared variable error" 

  with 
  | Failure message -> 
      if message = "Undeclared Variable" then 
        print_endline "Correct undeclared variable detection" 
      else
        failwith ("Unexpected error: " ^ message)


let () = 
  let map = StringMap.empty in 

  let map = 
    StringMap.add "x" "x.0" map 
  in 

  let expression = 
    Ast.Assignment
      (Ast.Var "x", Ast.Constant 5)
  in 

  let resolved = 
    resolve_exp expression map 
  in 

  match resolved with 
  | Ast.Assignment
      (Ast.Var "x.0", Ast.Constant 5) ->
      print_endline "Correct assigment resolution" 
 
  | _ -> 
      failwith "Unexpected resolved assigment" 


let () =
  let map = StringMap.empty in 

  let expression = 
    Ast.Assignment
      (Ast.Constant 2, Ast.Var "x")
  in 

  try 
    let _ =
      resolve_exp expression map 
    in 

    failwith "Expected Invalid assigment target error" 

  with
  | Failure message -> 
      if message = "Invalid assigment target" then 
        print_endline "Correct assigment LHS validation"
      else 
        failwith ("Unexpected error: " ^ message)

    
let () =
  let map = StringMap.empty in 

  let map =
    StringMap.add "x" "x.0" map 
  in 

  let map = 
    StringMap.add "y" "y.1" map 
  in 

  let expression =
    Ast.Unary
      (Ast.Negate,
       Ast.Binary
         (Ast.Add,
          Ast.Var "y", 
          Ast.Constant 3))
  in 

  let resolved =
    resolve_exp expression map 
  in 

  match resolved with 
  | Ast.Unary
       (Ast.Negate, 
        Ast.Binary
        (Ast.Add, 
         Ast.Var "y.1", 
         Ast.Constant 3)) ->
    print_endline "Correct recursive expression resolution" 

  | _ ->
      failwith "Unexpected resolved expression" 

let () =
  let map = StringMap.empty in 

  let map = 
    StringMap.add "x" "x.0" map 
  in 

  let map =
    StringMap.add "y" "y.1" map 
  in 

  let expression =
    Ast.Binary
      (Ast.Multiply, 
       Ast.Var "x", 
       Ast.Var "y")
  in 

  let resolved = 
    resolve_exp expression map 
  in 

  match resolved with 
  | Ast.Binary
      (Ast.Multiply,
       Ast.Var "x.0",
       Ast.Var "y.1") ->
       print_endline "Correct binary expression resolution" 
    
  | _ -> 
      failwith "Unexpected resolved binary expression" 


