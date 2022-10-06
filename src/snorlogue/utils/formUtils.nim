import std/[times, strutils, sugar, json, os, options, strformat, logging, typetraits, algorithm]
import norm/model
import prologue
import ./macroUtils
import ./fileFieldUtils
import ../constants

export fileFieldUtils

# Convert: Model value --> Form Field Data

func toFormField*(value: Option[string], fieldName: string): FormField = 
  FormField(name: fieldName, kind: FormFieldKind.STRING, strVal: value)

func toFormField*(value: Option[int] | Option[int32] | Option[int64], fieldName: string): FormField = 
  let mappedValue = value.map(val => val.int64)
  FormField(name: fieldName, kind: FormFieldKind.INT, iVal: mappedValue)

func toFormField*(value: Option[float] | Option[float32] | Option[float64], fieldName: string): FormField = 
  let mappedValue = value.map(val => val.float64)
  FormField(name: fieldName, kind: FormFieldKind.FLOAT, fVal: mappedValue)

func toFormField*(value: Option[bool], fieldName: string): FormField = 
  FormField(name: fieldName, kind: FormFieldKind.BOOL, bVal: value)

func toFormField*(value: Option[Datetime], fieldName: string): FormField = 
  FormField(name: fieldName, kind: FormFieldKind.DATE, dtVal: value)

func toFormField*(value: Option[Filename], fieldName: string): FormField =
  FormField(name: fieldName, kind: FormFieldKind.FILE, fileVal: value)

func toFormField*[T](value: T, fieldName: string): FormField = 
  toFormField(some value, fieldName)

func toSelectFormField*(value: Option[int64], intOptions: seq[IntOption], fieldName: string): FormField =
  var options = intOptions
  options.sort((opt1, opt2: IntOption) => cmp(opt1.name, opt2.name))

  result = FormField(name: fieldName, kind: FormFieldKind.INTSELECT, intSeqVal: value, intOptions: options)

func toSelectFormField*(value: int64, intOptions: seq[IntOption], fieldName: string): FormField = 
  toSelectFormField(some value, intOptions, fieldName)

func toSelectFormField*(value: Option[string], stringOptions: seq[StringOption], fieldName: string): FormField =
  var options = stringOptions
  options.sort((opt1, opt2: StringOption) => cmp(opt1.name, opt2.name))

  result = FormField(name: fieldName, kind: FormFieldKind.STRSELECT, strSeqVal: value, strOptions: options)

func toSelectFormField*(value: string, stringOptions: seq[StringOption], fieldName: string): FormField = 
  toSelectFormField(some value, stringOptions, fieldName)

func toSelectFormField*[T: enum](value: T, fieldName: string): FormField =
  var enumOptions: seq[IntOption] = @[]
  for enumValue in T:
    enumOptions.add(IntOption(name: $enumValue, value: enumValue.int))

  toSelectFormField(value.int, enumOptions, fieldName)


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