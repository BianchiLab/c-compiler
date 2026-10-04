type operand =
  | Imm of int
  | Reg of reg
  | Pseudo of string 
  | Stack of int 

and reg  = 
  | AX  
  | DX 
  | R10
  | R11  

type unary_operator = 
  | Neg 
  | Not 

type binary_operator = 
  | Add 
  | Sub
  | Mul 

type condition_code = 
  | E 
  | NE 
  | G 
  | GE 
  | L 
  | LE 


type instruction =
  | Mov of operand * operand
  | Unary of unary_operator * operand 
  | Binary of binary_operator * operand * operand 
  | Cmp of operand * operand 
  | Set of condition_code * operand 
  | Jump of string 
  | JumpIf of condition_code * string 
  | Label of string
  | Idiv of operand 
  | Cdq 
  | AllocateStack of int 
  | Ret

type function_definition =
  | Function of string * instruction list

type program =
  | Program of function_definition