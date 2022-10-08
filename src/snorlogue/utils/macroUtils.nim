import std/macros

macro getField*[T: object | ref object](obj: T, fieldName: static string): untyped =
  nnkDotExpr.newTree(obj, ident(fieldName))

macro getField*[T: object | ref object](someType: typedesc[T], fieldName: static string): untyped =
  nnkDotExpr.newTree(someType, ident(fieldName))

template setField*[T: object | ref object](obj: var T, fieldName: static string, value: untyped) =
  obj.getField(fieldName) = value

proc hasField*[T: object | ref object](obj: T, fieldName: static string): bool {.compileTime.} =
  result = compiles(obj.getField(fieldName))

proc hasField*[T: object | ref object](t: typedesc[T], fieldName: static string): bool {.compileTime.} =
  result = compiles(T().getField(fieldName))