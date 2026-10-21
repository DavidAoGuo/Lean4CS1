inductive PropLogic where
  | T
  | False
  | and (left right : PropLogic) : PropLogic
