type unary_operator =
  | Complement
  | Negate
  | Not

type binary_operator = 
  | Add 
  | Substract
  | Multiply
  | Divide 
  | Remainder
  | Equal
  | NotEqual
  | LessThan
  | LessOrEqual
  | GreaterThan
  | GreaterOrEqual

type value =
  | Constant of int
  | Var of string

type instruction =
  | Return of value
  | Unary of unary_operator * value * value
  | Binary of binary_operator * value * value * value 
  | Copy of value * value 
  | Jump of string 
  | JumpIfZero of value * string
  | JumpIfNotZero of value * string 
  | Label of string 

type function_definition = Function of string * instruction list

type program = Program of function_definition

(* -------------------------------------------------- *)
(* Temporary variable generation                      *)
(* -------------------------------------------------- *)

let temporary_counter = ref 0

let make_temporary () =
  let name = Printf.sprintf "tmp.%d" !temporary_counter in
  temporary_counter := !temporary_counter + 1;
  name

let label_counter = ref 0 

let make_label prefix = 
  let name = Printf.sprintf "%s%d" prefix !label_counter in 
  label_counter := !label_counter + 1;
  name 

(* -------------------------------------------------- *)
(* Pass 1: AST -> Tacky                        *)
(* -------------------------------------------------- *)

let convert_unary_operator op =
  match op with
  | Complement -> Assembly.Not
  | Negate -> Assembly.Neg 
  | Not -> 
      failwith "Logical Not handled separately" 

let convert_binary_operator op = 
  match op with 
  | Add -> Assembly.Add 
  | Substract -> Assembly.Sub 
  | Multiply -> Assembly.Mul
  | Divide ->
      failwith "Division handled separately"
  | Remainder ->
      failwith "Remainder handled separately"
  | Equal
  | NotEqual
  | LessThan 
  | LessOrEqual
  | GreaterThan
  | GreaterOrEqual ->
      failwith "Comparison handled separately" 

  let convert_condition_code op = 
    match op with 
    | Equal -> Assembly.E 
    | NotEqual -> Assembly.NE
    | LessThan -> Assembly.L 
    | LessOrEqual -> Assembly.LE 
    | GreaterThan -> Assembly.G
    | GreaterOrEqual -> Assembly.GE 
    | Add 
    | Substract
    | Multiply
    | Divide 
    | Remainder ->
        failwith "Not a comparison operator"
  

let convert_ast_unary_operator op =
  match op with 
  | Ast.Complement -> Complement
  | Ast.Negate -> Negate 
  | Ast.Not -> Not 

let convert_binop op = 
  match op with 
  | Ast.Add -> Add
  | Ast.Substract -> Substract
  | Ast.Multiply -> Multiply
  | Ast.Divide -> Divide 
  | Ast.Remainder -> Remainder
  | Ast.Equal -> Equal
  | Ast.NotEqual -> NotEqual
  | Ast.LessThan -> LessThan
  | Ast.LessOrEqual -> LessOrEqual
  | Ast.GreaterThan -> GreaterThan
  | Ast.GreaterOrEqual -> GreaterOrEqual
  | Ast.And 
  | Ast.Or -> 
      failwith "Logical Operators handled separately" 


let rec emit_tacky_exp exp instructions =
  match exp with

  | Ast.Constant n ->
      (Constant n, instructions)

  | Ast.Unary (op, e) ->
      let (src, instructions) =
        emit_tacky_exp e instructions
      in

      let dst =
        Var (make_temporary ())
      in

      let op =
        convert_ast_unary_operator op
      in

      let instructions =
        instructions @ [Unary (op, src, dst)]
      in

      (dst, instructions)


  | Ast.Binary (Ast.And, e1, e2) -> 
      let (v1, instructions) = 
        emit_tacky_exp e1 instructions 
      in 

      let false_label = 
        make_label "and_false" 
      in 

      let end_label = 
        make_label "and_end"
      in 

      let dst =
        Var (make_temporary())
      in 

      let instructions =
        instructions @ [
          JumpIfZero (v1, false_label)
        ]
      in 

      let(v2, instructions) =
        emit_tacky_exp e2 instructions
      in 

      let instructions = 
        instructions @ [
          JumpIfZero (v2, false_label);
          Copy (Constant 1, dst);
          Jump end_label; 
          Label false_label; 
          Copy (Constant 0, dst); 
          Label end_label
        ]
      in 

      (dst, instructions)

    | Ast.Binary (Ast.Or, e1, e2) -> 
        let (v1, instructions) = 
          emit_tacky_exp e1 instructions 
        in 

        let true_label = 
          make_label "or_true"

        in 

        let end_label = 
          make_label "or_end"
        in 

        let dst = 
          Var (make_temporary ())
        in 

        let instructions = 
          instructions @ [
            JumpIfNotZero (v1, true_label)
          ]
        in 

        let (v2, instructions) = 
          emit_tacky_exp e2 instructions 
        in 

        let instructions = 
          instructions @ [
            JumpIfNotZero (v2, true_label);
            Copy (Constant 0, dst);
            Jump end_label;
            Label true_label; 
            Copy (Constant 1, dst); 
            Label end_label
          ]
        in 

        (dst, instructions)

    | Ast.Binary (op, e1, e2) ->
        let (v1, instructions) = 
          emit_tacky_exp e1 instructions
        in 

        let (v2, instructions) = 
          emit_tacky_exp e2 instructions 
        in 

        let dst = 
          Var (make_temporary ())
        in 

        let op = 
          convert_binop op
        in 

        let instructions = 
          instructions @ [Binary (op, v1, v2, dst)]
        in 

        (dst, instructions)





let emit_tacky_statement statement =
  match statement with 
  | Ast.Return exp -> 
      let (value, instructions) = 
        emit_tacky_exp exp []
      in 

      instructions @ [Return value]


let emit_tacky_function function_definition = 
  match function_definition with 
  | Ast.Function (name, statement) -> 
      let instructions = 
        emit_tacky_statement statement
      in 
      Function (name, instructions)

let emit_tacky_program program = 
  match program with 
  | Ast.Program function_definition -> 
      Program (emit_tacky_function function_definition)

let convert_value value =
  match value with
  | Constant n -> Assembly.Imm n
  | Var name -> Assembly.Pseudo name

let convert_instruction instruction =
  match instruction with
  
  | Return value ->
    [ Assembly.Mov (convert_value value, Assembly.Reg Assembly.AX); Assembly.Ret ]
  
  | Unary (Not, src, dst) ->
     let src = convert_value src in 
     let dst = convert_value dst in 
     [
      Assembly.Cmp (Assembly.Imm 0, src); 
      Assembly.Mov (Assembly.Imm 0, dst);
      Assembly.Set (Assembly.E, dst)
     ]

  | Unary (op, src, dst) ->
    let src = convert_value src in
    let dst = convert_value dst in
    let op = convert_unary_operator op in
    [ 
      Assembly.Mov (src, dst); 
      Assembly.Unary (op, dst) 
    ]
  
  | Binary
      ((Equal
        | NotEqual
        | LessThan
        | LessOrEqual
        | GreaterThan
        | GreaterOrEqual) as op, 
        src1, 
        src2, 
        dst) ->

        let src1 = convert_value src1 in
        let src2 = convert_value src2 in 
        let dst = convert_value  dst  in 
        let condition = convert_condition_code op in

        [
          Assembly.Mov (src1, dst);
          Assembly.Cmp (src2, dst);
          Assembly.Mov (Assembly.Imm 0, dst);
          Assembly.Set (condition, dst); 
        ]

  | Binary (op, src1, src2, dst) ->
      let src1 = convert_value src1 in 
      let src2 = convert_value src2 in 
      let dst = convert_value dst in 
      let op = convert_binary_operator op in 
      [
        Assembly.Mov (src1, dst); 
        Assembly.Binary (op, src2, dst)
      ]
  
  | Copy (src, dst) ->
      [
        Assembly.Mov 
          (convert_value src, convert_value dst)
      ]
  
  | Jump label -> 
      [ Assembly.Jump label ]
  
  | JumpIfZero (value, label) ->
      [
        Assembly.Cmp (Assembly.Imm 0, convert_value value); 
        Assembly.JumpIf (Assembly.E, label)
      ]

  | JumpIfNotZero (value, label) ->
      [
        Assembly.Cmp (Assembly.Imm 0, convert_value value); 
        Assembly.JumpIf (Assembly.NE, label)
      ]

  | Label name -> 
      [
        Assembly.Label name 
      ]

let convert_function (Function (name, instructions)) =
  let assembly_instructions =
    List.flatten (List.map convert_instruction instructions)
  in
  Assembly.Function (name, assembly_instructions)

let convert_program (Program function_definition) =
  Assembly.Program (convert_function function_definition)

(* -------------------------------------------------- *)
(* Pass 2: Pseudo -> Stack                            *)
(* -------------------------------------------------- *)

let replace_pseudoregisters instructions =
  let offsets = Hashtbl.create 10 in
  let next_offset = ref (-4) in
  let convert_operand operand =
    match operand with

    | Assembly.Imm n -> Assembly.Imm n

    | Assembly.Reg r -> Assembly.Reg r

    | Assembly.Stack n -> Assembly.Stack n

    | Assembly.Pseudo name -> (
      match Hashtbl.find_opt offsets name with
      | Some offset -> 
          Assembly.Stack offset
      | None ->
        let offset = !next_offset in
        Hashtbl.add offsets name offset;
        next_offset := !next_offset - 4;
        Assembly.Stack offset)
  in

  let convert_instruction instruction =
    match instruction with

    | Assembly.Mov (src, dst) ->
      Assembly.Mov 
        (convert_operand src, convert_operand dst)
    
    | Assembly.Unary (op, operand) -> Assembly.Unary (op, convert_operand operand)
    
    | Assembly.Binary (op, src, dst) -> 
        Assembly.Binary
          (op, convert_operand src, convert_operand dst)

    | Assembly.Cmp (src, dst) ->
        Assembly.Cmp
          (convert_operand src, convert_operand dst)
        
    | Assembly.Set (condition, operand) ->
        Assembly.Set 
          (condition, convert_operand operand) 
      
    | Assembly.Jump label ->
        Assembly.Label label 

    | Assembly.JumpIf (condition, label) -> 
        Assembly.JumpIf (condition, label)
      
    | Assembly.Label label ->
        Assembly.Label label 

    | Assembly.Idiv operand ->
        Assembly.Idiv (convert_operand operand)

    | Assembly.Cdq ->
        Assembly.Cdq 

    | Assembly.AllocateStack n -> 
        Assembly.AllocateStack n
    
    | Assembly.Ret -> Assembly.Ret
  in

  let new_instructions = 
    List.map convert_instruction instructions 
    in

  (new_instructions, !next_offset + 4)



(* -------------------------------------------------- *)
(* Pass 3                          *)
(* -------------------------------------------------- *)

let fix_assembly instructions stack_size =
  let fix_instruction instruction =
    match instruction with

    (* Memory-to-memory move *)
    | Assembly.Mov (Assembly.Stack src, Assembly.Stack dst) ->
        [
          Assembly.Mov
            (Assembly.Stack src, Assembly.Reg Assembly.R10);

          Assembly.Mov
            (Assembly.Reg Assembly.R10, Assembly.Stack dst);
        ]


    (* Memory-to-memory binary operation *)
    | Assembly.Binary (op, Assembly.Stack src, Assembly.Stack dst) ->
        [
          Assembly.Mov
            (Assembly.Stack src, Assembly.Reg Assembly.R10);

          Assembly.Binary
            (op, Assembly.Reg Assembly.R10, Assembly.Stack dst);
        ]

    (* Memory-to-memory comparison *)
    | Assembly.Cmp (Assembly.Stack src, Assembly.Stack dst) ->
        [
          Assembly.Mov 
            (Assembly.Stack src, Assembly.Reg Assembly.R10);
          
          Assembly.Cmp 
            (Assembly.Reg Assembly.R10, Assembly.Stack dst); 
        ]

      (* Immediate as second comparison operand *)
      | Assembly.Cmp (src, Assembly.Imm n) ->
          [
            Assembly.Mov 
              (Assembly.Imm n, Assembly.Reg Assembly.R11);
            
            Assembly.Cmp 
              (src, Assembly.Reg Assembly.R11); 
          ]

    | instruction ->
        [instruction]
  in

  let fixed_instructions =
    List.flatten (List.map fix_instruction instructions)
  in

  Assembly.AllocateStack stack_size :: fixed_instructions
      

let () =
  let ast =
    Ast.Program
      (Ast.Function
        ("main",
         Ast.Return
           (Ast.Binary
             (Ast.Add,
              Ast.Constant 2,
              Ast.Binary
                (Ast.Multiply,
                 Ast.Constant 3,
                 Ast.Constant 4)))))
  in

  let tacky_program =
    emit_tacky_program ast
  in

  match tacky_program with
  | Program (Function (name, instructions)) ->
      Printf.printf "Function: %s\n" name;

      List.iter
        (fun instruction ->
          match instruction with

          | Binary (op, v1, v2, dst) ->
              let op_name =
                match op with
                | Add -> "Add"
                | Substract -> "Substract"
                | Multiply -> "Multiply"
                | Divide -> "Divide"
                | Remainder -> "Remainder"
              in

              let value_name value =
                match value with
                | Constant n -> string_of_int n
                | Var name -> name
              in

              Printf.printf
                "Binary(%s, %s, %s, %s)\n"
                op_name
                (value_name v1)
                (value_name v2)
                (value_name dst)

          | Return value ->
              let value_name =
                match value with
                | Constant n -> string_of_int n
                | Var name -> name
              in

              Printf.printf
                "Return(%s)\n"
                value_name

          | Unary _ ->
              Printf.printf "Unary(...)\n")
        instructions 