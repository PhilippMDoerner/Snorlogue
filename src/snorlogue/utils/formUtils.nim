import std/[times, strutils, sugar, json, os, options, strformat, logging, typetraits, algorithm]
import norm/model
import prologue
import ./macroUtils
import ./fileFieldUtils
import ../constants

export fileFieldUtils

type ModelFieldKind* = enum
  STRING
  INT
  FLOAT
  DATE
  BOOL
  INTSELECT
  FILE

type ModelField* = object
  name*: string
  case kind*: ModelFieldKind
  of STRING: 
    strVal*: Option[string]
  of FLOAT: 
    fVal*: Option[float64]
  of INT: 
    iVal*: Option[int64]
  of DATE: 
    dtVal*: Option[DateTime]
  of BOOL: 
    bVal*: Option[bool]
  of INTSELECT: 
    seqVal*: Option[int64]
    options*: seq[ForeignKeyValue]
  of FILE:
    fileVal*: Option[Filename]

# Convert: Model value --> Form Field Data

func toModelField*(value: Option[string], fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.STRING, strVal: value)

func toModelField*(value: Option[int] | Option[int32] | Option[int64], fieldName: string): ModelField = 
  let mappedValue = value.map(val => val.int64)
  ModelField(name: fieldName, kind: ModelFieldKind.INT, iVal: mappedValue)

func toModelField*(value: Option[float] | Option[float32] | Option[float64], fieldName: string): ModelField = 
  let mappedValue = value.map(val => val.float64)
  ModelField(name: fieldName, kind: ModelFieldKind.FLOAT, fVal: mappedValue)

func toModelField*(value: Option[bool], fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.BOOL, bVal: value)

func toModelField*(value: Option[Datetime], fieldName: string): ModelField = 
  ModelField(name: fieldName, kind: ModelFieldKind.DATE, dtVal: value)

func toModelField*(value: Option[Filename], fieldName: string): ModelField =
  ModelField(name: fieldName, kind: ModelFieldKind.FILE, fileVal: value)

func toModelField*[T](value: T, fieldName: string): ModelField = 
  toModelField(some value, fieldName)

func toFkModelField*(value: Option[int64], fkOptions: seq[ForeignKeyValue], fieldName: string): ModelField =
  var options = fkOptions
  options.sort((opt1, opt2: ForeignKeyValue) => cmp(opt1.name, opt2.name))

  result = ModelField(name: fieldName, kind: ModelFieldKind.INTSELECT, seqVal: value, options: options)

func toFkModelField*(value: int64, fkOptions: seq[ForeignKeyValue], fieldName: string): ModelField = 
  toFkModelField(some value, fkOptions, fieldName)

# Convert: string from HTML form --> Model value
func convert*(formValue: string, T: typedesc[SomeInteger]): T = parseInt(formValue).T

func convert*(formValue: string, T: typedesc[SomeFloat]): T = parseFloat(formValue).T

func convert*(formValue: string, T: typedesc[string]): T = formValue

func convert*(formValue: string, T: typedesc[bool]): T = parseBool(formValue)

func convert*(formValue: string, T: typedesc[DateTime]): T = parse(formValue)

func convert*(formValue: string, T: typedesc[Filename]): T = formValue.Filename

func convert*[T](formValue: string, O: typedesc[Option[T]]): O = 
  let hasValue = formValue != ""
  result = if hasValue: some formValue.convert(T) else: none(T)

proc handleFileFormData(ctx: Context, fileFieldName: string): Filename =
  ## Handles files sent via HTTP requests. Stores the file and returns the filepath.
  let file = ctx.getUploadFile(fileFieldName)
  let mediaRoot = ctx.getSettings(MEDIA_ROOT_SETTING).getStr(DEFAULT_MEDIA_ROOT)
  if not dirExists(mediaRoot):
   raise newException(IOError, fmt"The media directory '{mediaRoot}' does not exist or is not accessible. Configure one with the setting '{MEDIA_ROOT_SETTING}' or create it/make it accessible.")
  
  file.save(mediaRoot)

  let filepath = fmt"{mediaRoot}/{file.filename}"
  result = filepath.Filename

proc parseFormData*[T: Model](ctx: Context, model: typedesc[T], skipIdField: static bool = false): T =
  ## Parses the form data into a model instance
  result = T()
  for name, dummyValue in T()[].fieldPairs:
    let formValueStr: Option[string] = ctx.getFormParamsOption(name)
    
    if formValueStr.isNone():
      when dummyValue is Option:
        # Model Field is Optional File Field and Form has no value --> set to none
        result.setField(name, none(genericParams(dummyValue.type()).get(0)))
      
      else: 
        # Model Field is not Optional File Field and Form has no value --> Error
        const modelName = $T
        const fieldName = name
        debug(fmt"Sent request is missing '{fieldName}' field of type '{modelName}'")
    
    else:
      # Model Field is id Field and id field shall not be filled (e.g. because there is no id during creation)
      const isIdField = name == "id"
      when isIdField and skipIdField:
        discard #Do nothing

      # Model Field is Normal Field and Form has value --> Parse into field
      else:
        const isFileField = typeOf(dummyValue) is Filename
        when isFileField:
          let formValue = handleFileFormData(ctx, name)
          result.setField(name, formValue)
        else:
          let formValue = formValueStr.get().convert(typeOf(dummyValue))
          result.setField(name, formValue)