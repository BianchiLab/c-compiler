let () = 
  let tokens =
    Lexer.tokenize 
      "int main(void) { int x = 5; return x; }" 
  in

  let ast = 
    Parser.parse_program tokens 
  in 

  match ast with 
  | Ast.Program 
      (Ast.Function
        ("main", 
          [
            Ast.D
              (Ast.Declaration
                ("x", Some (Ast.Constant 5))); 

            Ast.S 
              (Ast.Return (Ast.Var "x")); 
          ])) -> 
      print_endline "Correct program AST"
    
  | _ -> 
      failwith "Unexpected program AST" 

