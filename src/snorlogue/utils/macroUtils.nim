import std/macros

macro getField*[T: object | ref object](obj: T, fieldName: static string): untyped =
  ## Accesses the field on an object instance by generating the code `obj.fieldName`
  nnkDotExpr.newTree(obj, ident(fieldName))

macro getField*[T: object | ref object](someType: typedesc[T], fieldName: static string): untyped =
  ## Accesses the field on an object type at by generating the code `obj.fieldName`
  nnkDotExpr.newTree(someType, ident(fieldName))

template setField*[T: object | ref object](obj: var T, fieldName: static string, value: untyped) =
  ## Sets the field on an object type to the specified value by generating the code `obj.fieldName = value`
  obj.getField(fieldName) = value

proc hasField*[T: object | ref object](obj: T, fieldName: static string): bool {.compileTime.} =
  ## Checks at compileTime whether the given object instance has a field with the name `fieldName`
  result = compiles(obj.getField(fieldName))

proc hasField*[T: object | ref object](t: typedesc[T], fieldName: static string): bool {.compileTime.} =
  ## Checks at compileTime whether the given object type has a field with the name `fieldName`
  result = compiles(T().getField(fieldName))