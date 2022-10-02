import std/[times, strutils, sugar, options, strformat, logging, typetraits]
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
  of STRING: strVal*: Option[string]
  of FLOAT: fVal*: Option[float64]
  of INT: iVal*: Option[int64]
  of DATE: dtVal*: Option[DateTime]
  of BOOL: bVal*: Option[bool]

# Convert: Model value --> Form Field Data

proc toModelField*(value: Option[string], fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.STRING, strVal: value)

proc toModelField*(value: Option[int] | Option[int32] | Option[int64], fieldName: string): ModelField = 
  let mappedValue = value.map(val => val.int64)
  ModelField(name: fieldName, kind: ModelFieldKind.INT, iVal: mappedValue)

proc toModelField*(value: Option[float] | Option[float32] | Option[float64], fieldName: string): ModelField = 
  let mappedValue = value.map(val => val.float64)
  ModelField(name: fieldName, kind: ModelFieldKind.FLOAT, fVal: mappedValue)

proc toModelField*(value: Option[bool], fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.BOOL, bVal: value)

proc toModelField*(value: Option[Datetime], fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.DATE, dtVal: value)

proc toModelField*[T](value: T, fieldName: string): ModelField = 
  toModelField(some value, fieldName)

# Convert: string from HTML form --> Model value
func convert*(formValue: string, T: typedesc[SomeInteger]): T = parseInt(formValue).T

func convert*(formValue: string, T: typedesc[SomeFloat]): T = parseFloat(formValue).T

func convert*(formValue: string, T: typedesc[string]): T = formValue

func convert*(formValue: string, T: typedesc[bool]): T = parseBool(formValue)

proc convert*(formValue: string, T: typedesc[DateTime]): T = parse(formValue)

proc convert*[T](formValue: string, O: typedesc[Option[T]]): O = some formValue.convert(T)

proc parseFormData*[T: Model](ctx: Context, model: typedesc[T], skipIdField: static bool = false): T =
  result = T()
  for name, dummyValue in T()[].fieldPairs:
    let formValueStr: Option[string] = ctx.getFormParamsOption(name)
    echo name
    echo formValueStr
    
    if formValueStr.isNone():
      when dummyValue is Option:
        result.setField(name, none(genericParams(dummyValue.type()).get(0)))
      else: 
        const modelName = $T
        const fieldName = name
        debug(fmt"Sent request is missing '{fieldName}' field of type '{modelName}'")
    
    else:
      const isIdField = name == "id"
      when isIdField and skipIdField:
        discard #Do nothing

      else:
        mixin to
        let formValue = formValueStr.get().convert(typeOf(dummyValue))
        result.setField(name, formValue)