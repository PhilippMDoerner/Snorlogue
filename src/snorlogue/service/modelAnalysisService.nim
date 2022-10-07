import norm/[pragmas, model]
import std/[macros, tables, typetraits, strutils]

type ModelMetaData* = object
  name*: string
  table*: string

proc getForeignKeyFields*[T: Model](modelType: typedesc[T]): seq[string] {.compileTime.} =
  for name, value in T()[].fieldPairs:
    if value.hasCustomPragma(fk):
      result.add(name)

proc extractMetaData*[T: Model](modelType: typedesc[T]): ModelMetaData {.compileTime.}=
  ModelMetaData(
    name: $T,
    table: T.table().strip(chars = {'\"'})
  )