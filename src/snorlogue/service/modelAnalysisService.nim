import norm/[pragmas, model]
import std/[macros, tables, typetraits]

proc getForeignKeyFields*[T: Model](modelType: typedesc[T]): seq[string] {.compileTime.} =
  for name, value in T()[].fieldPairs:
    if value.hasCustomPragma(fk):
      result.add(name)