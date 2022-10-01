import std/[times]

type ModelFieldKind* = enum
  STRING
  INT
  FLOAT
  DATE
  BOOL

type ModelField* = object
  name*: string
  case kind*: ModelFieldKind
  of STRING: strVal*: string
  of FLOAT: fVal*: float64
  of INT: iVal*: int64
  of DATE: dtVal*: DateTime
  of BOOL: bVal*: bool

proc convertToModelField*(value: string, fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.STRING, strVal: value)

proc convertToModelField*(value: int | int32 | int64, fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.INT, iVal: value.int64)

proc convertToModelField*(value: float | float32 | float64, fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.FLOAT, fVal: value.float64)

proc convertToModelField*(value: bool, fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.BOOL, bVal: value)

proc convertToModelField*(value: Datetime, fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.DATE, dtVal: value)
