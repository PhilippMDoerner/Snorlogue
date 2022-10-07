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

proc checkForModelFields*[T: Model](modelType: typedesc[T]) {.compileTime.} =
  for field, value in T()[].fieldPairs:
    when field is Model:
      {.error: "You can not use Snorlogue with models that directly link to other models. Use norm's FK pragma instead".}

proc validateModel*[T: Model](model: typedesc[T]) {.compileTime.} =
  checkRo(T)
  checkForModelFields(T)