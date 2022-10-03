import norm/model
import std/[os, strutils, strformat]

const ID_PARAM* = "id"
const PAGE_PARAM* = "page"
const DEFAULT_PAGE_SIZE* = 50
const MEDIA_ROOT_SETTING* = "media-root"
let DEFAULT_MEDIA_ROOT* = fmt"{getCurrentDir()}/media"

proc `$`*[T: Model](model: T): string = fmt"{$T} #{model.id}"


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

#proc `$`*[T: Model](model: T): string = fmt"{$T} #{model.id}"