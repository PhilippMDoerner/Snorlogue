import std/[macros, sequtils]
import norm/model

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

# template unroll*(iter, name0, body0: untyped): untyped =
#   macro unrollImpl(name, body) =
#     result = newStmtList()
#     for a in iter:
#       result.add(newBlockStmt(newStmtList(
#         newConstStmt(name, newLit(a)),
#         copy body
#       )))
#   unrollImpl(name0, body0)