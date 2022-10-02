import std/[times, strutils, options, strformat, logging]
import norm/model
import prologue
import ./macroUtils

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



func to*(formValue: string, T: typedesc[SomeInteger]): T = parseInt(formValue).T

func to*(formValue: string, T: typedesc[SomeFloat]): T = parseFloat(formValue).T

func to*(formValue: string, T: typedesc[string]): T = formValue

func to*(formValue: string, T: typedesc[bool]): T = parseBool(formValue)

proc to*(formValue: string, T: typedesc[DateTime]): T = parse(formValue)

proc to*[T](formValue: string, O: typedesc[Option[T]]): O = some formValue.to(T)

proc parseFormData*[T: Model](ctx: Context, model: typedesc[T], skipIdField: static bool = false): T =
  result = T()
  for name, dummyValue in T()[].fieldPairs:
    let formValueStr: Option[string] = ctx.getFormParamsOption(name)
    echo name
    echo formValueStr
    
    if formValueStr.isNone():
      when dummyValue is Option:
        result.setField(name, none(genericParams(sourceFieldValue.type()).get(0)))
      else: 
        const modelName = $T
        const fieldName = name
        debug(fmt"Sent request is missing '{fieldName}' field of type '{modelName}'")
    
    else:
      const isIdField = name == "id"
      when isIdField and skipIdField:
        discard #Do nothing

      else:
        let formValue = formValueStr.get().to(typeof(dummyValue))
        result.setField(name, formValue)