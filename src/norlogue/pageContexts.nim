import norm/model
import std/[strformat, strutils]
import formUtils

type Page* = enum
  CREATE = "create"
  DELETE = "delete"
  DETAIL = "detail"
  LIST = "list"
  OVERVIEW = "overview"

type PageContext = object of RootObj
  overviewUrl*: string

type ModelListContext*[T] = object of PageContext
  modelName*: string
  models*: seq[T]
  formUrl*: string
  deleteUrlStub*: string
  createUrl*: string
  detailUrlStub*: string

type ModelDetailContext*[T] = object of PageContext
  modelName*: string
  model*: T
  fields*: seq[ModelField]
  deleteUrl*: string
  updateUrl*: string

proc generateUrlStub*[T: Model](action: Page, model: typedesc[T]): string =
  result = case action:
  of Page.OVERVIEW:
    "/overview"
  else:
    fmt"{$action}/{($model).toLower()}"  

proc initListContext*[T](models: seq[T]): ModelListContext[T] =
  result = ModelListContext[T](
    modelName: $T,
    models: models,
    createUrl: generateUrlStub(Page.CREATE, T),
    deleteUrLStub: generateUrlStub(Page.DELETE, T),
    detailUrlStub: generateUrlStub(Page.DETAIL, T),
    overviewUrl: generateUrlStub(Page.OVERVIEW, T)
  )

proc initDetailContext*[T: Model](model: T): ModelDetailContext[T] =
  var fields: seq[ModelField] = @[]
  for name, value in model[].fieldPairs:
    fields.add(convertToModelField(value, name))

  ModelDetailContext[T](
    modelName: $T,
    model: model,
    fields: fields,
    deleteUrl: fmt"{generateUrlStub(Page.DELETE, T)}/{model.id}",
    updateUrl: fmt"{($T).toLower()}/{model.id}",
    overviewUrl: generateUrlStub(Page.OVERVIEW, T)
  )