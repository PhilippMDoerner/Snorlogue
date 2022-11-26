import norm/model
import std/strutils

type ModelMetaData* = object
  name*: string
  table*: string

proc extractMetaData*[T: Model](modelType: typedesc[T]): ModelMetaData {.compileTime.} =
  ModelMetaData(
    name: $T,
    table: T.table().strip(chars = {'\"'})
  )