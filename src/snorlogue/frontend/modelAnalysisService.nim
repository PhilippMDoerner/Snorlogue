import norm/[pragmas, model]
import std/[macros, tables, typetraits, strutils, strformat]

## A collection of procs related to analysing Model-types at compile time or extracting Metadata from them.
## Mostly necessary because you can't story a list of types or the like anywhere. This all data needed
## later must be extracted immediately when the Model is provided.

type ModelMetaData* = object
  name*: string
  table*: string
  url*: string

proc getForeignKeyFields*[T: Model](modelType: typedesc[T]): seq[string] {.compileTime.} =
  ## Extracts the names of all foreign key fields from a model.
  for name, value in T()[].fieldPairs:
    if value.hasCustomPragma(fk):
      result.add(name)

proc extractMetaData*[T: Model](
  urlPrefix: static string,
  modelType: typedesc[T]
): ModelMetaData {.compileTime.} =
  ModelMetaData(
    name: $T,
    url: fmt"{generateUrlStub(urlPrefix, Page.LIST, T)}/",
    table: T.table().strip(chars = {'\"'})
  )

proc checkForModelFields*[T: Model](modelType: typedesc[T]) {.compileTime.} =
  ## Compiletime check if a given `modelType` contains any nested model fields.
  ## These can not be allowed, as this would mean supporting the creation of multiple model-entries in a database from one POST request, which is currently out of scope for this package.
  for field, value in T()[].fieldPairs:
    when field is Model:
      {.error: "You can not use Snorlogue with models that directly link to other models. Use norm's FK pragma instead".}

proc validateModel*[T: Model](model: typedesc[T]) {.compileTime.} =
  ## Compiletime check if the given model fulfills all requirements for being used with this package.
  checkRo(T) # Ensures that the model is not read-only
  checkForModelFields(T)
