import std/[times, strutils, sugar, json, os, options, strformat, logging, typetraits]
import norm/[pragmas, pragmasutils, model]
import prologue
import ../utils/macroUtils
import ./fieldUtils/[fieldTypes, selectFieldUtils, fileFieldUtils]
import ../constants

export fieldTypes
export fileFieldUtils


# Convert: Model value --> Form Field Data

func toFormField*(value: Option[string], fieldName: string): FormField = 
  ## Converts field data of string field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, kind: FormFieldKind.STRING, strVal: value)

func toFormField*(value: Option[int], fieldName: string): FormField = 
  ## Converts field data of int field on Model into FormField to generate HTML Form Fields 
  let mappedValue = value.map(val => val.int64)
  FormField(name: fieldName, kind: FormFieldKind.INT, iVal: mappedValue)

func toFormField*(value: Option[int32], fieldName: string): FormField = 
  ## Converts field data of int field on Model into FormField to generate HTML Form Fields 
  let mappedValue = value.map(val => val.int64)
  FormField(name: fieldName, kind: FormFieldKind.INT, iVal: mappedValue)

func toFormField*(value: Option[int64], fieldName: string): FormField = 
  ## Converts field data of int field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, kind: FormFieldKind.INT, iVal: value)

func toFormField*(value: Option[float] | Option[float32] | Option[float64], fieldName: string): FormField = 
  ## Converts field data of float field on Model into FormField to generate HTML Form Fields 
  let mappedValue = value.map(val => val.float64)
  FormField(name: fieldName, kind: FormFieldKind.FLOAT, fVal: mappedValue)

func toFormField*(value: Option[bool], fieldName: string): FormField = 
  ## Converts field data of bool field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, kind: FormFieldKind.BOOL, bVal: value)

func toFormField*(value: Option[DateTime], fieldName: string): FormField = 
  ## Converts field data of DateTime field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, kind: FormFieldKind.DATE, dtVal: value)

func toFormField*(value: Option[Filename], fieldName: string): FormField =
  ## Converts field data of Filename field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, kind: FormFieldKind.FILE, fileVal: value)

func toFormField*[T](value: T, fieldName: string): FormField = 
  ## Helper proc to enable converting non-optional fields into FormField
  toFormField[T](some value, fieldName)

proc extractFields*[T: Model](model: T): seq[FormField] =
  ## Extracts the metadata of all fields on a model and turns it into seq[FormFIeld] 
  ## which are used to generate HTML form fields. 
  mixin toFormField
  
  result = @[]
  for name, value in model[].fieldPairs:
    const isFkField = value.hasCustomPragma(fk)
    const isEnumField = value is enum
    when isFkField:
      result.add(toSelectFormField(value, name, value.getCustomPragmaVal(fk))) # Last Param is a Model type

    elif isEnumField:
      result.add(toSelectFormField(value, name))

    else:
      result.add(toFormField(value, name))



# Convert: string from HTML form --> Model value
func toModelValue*(formValue: string, T: typedesc[SomeInteger]): T = parseInt(formValue).T

func toModelValue*(formValue: string, T: typedesc[SomeFloat]): T = parseFloat(formValue).T

func toModelValue*(formValue: string, T: typedesc[string]): T = formValue

func toModelValue*(formValue: string, T: typedesc[bool]): T = parseBool(formValue)

func toModelValue*(formValue: string, T: typedesc[DateTime]): T = parse(formValue)

func toModelValue*(formValue: string, T: typedesc[Filename]): T = formValue.Filename

func toModelValue*[T](formValue: string, O: typedesc[Option[T]]): O = 
  let hasValue = formValue != ""
  result = if hasValue: some formValue.toModelValue(T) else: none(T)

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
          let formValue = formValueStr.get().toModelValue(typeOf(dummyValue))
          result.setField(name, formValue)
