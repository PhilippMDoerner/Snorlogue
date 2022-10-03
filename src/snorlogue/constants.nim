import norm/model
import std/strutils

const ID_PARAM* = "id"
const PAGE_PARAM* = "page"
const DEFAULT_PAGE_SIZE* = 50

type SortDirection* = enum
  ASC, DESC

type ModelMetaData* = object
  name*: string
  table*: string

proc extractMetaData*[T: Model](modelType: typedesc[T]): ModelMetaData {.compileTime.}=
  ModelMetaData(
    name: $T,
    table: T.table().strip(chars = {'\"'})
  )

type ForeignKeyValue* = object
  name*: string
  value*: int64