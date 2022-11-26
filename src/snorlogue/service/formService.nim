import std/[times, strutils, sugar, json, os, options, strformat, logging, typetraits]
import norm/[pragmas, pragmasutils, model]
import prologue
import ../utils/macroUtils
import ./fieldUtils/[fieldTypes, selectFieldUtils, fileFieldUtils]
import ../constants

export fieldTypes
export fileFieldUtils


# Convert: Model value --> Form Field Data

func toFormField*(value: Option[string], fieldName: string, isRequired: bool): FormField = 
  ## Converts field data of string field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.STRING, strVal: value)

func toFormField*(value: Option[int64], fieldName: string, isRequired: bool): FormField = 
  ## Converts field data of int field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.INT, iVal: value)

func toFormField*(value: Option[int], fieldName: string, isRequired: bool): FormField = 
  ## Converts field data of int field on Model into FormField to generate HTML Form Fields 
  let mappedValue = value.map(val => val.int64)
  toFormField(mappedValue, fieldName, isRequired)

func toFormField*(value: Option[int32], fieldName: string, isRequired: bool): FormField = 
  ## Converts field data of int field on Model into FormField to generate HTML Form Fields 
  let mappedValue = value.map(val => val.int64)
  toFormField(mappedValue, fieldName, isRequired)
  
func toFormField*(value: Option[Natural], fieldName: string, isRequired: bool): FormField = 
  ## Converts field data of int field on Model into FormField to generate HTML Form Fields 
  let mappedValue = value.map(val => val.int64)
  toFormField(mappedValue, fieldName, isRequired)

func toFormField*(value: Option[float64], fieldName: string, isRequired: bool): FormField = 
  ## Converts field data of float field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.FLOAT, fVal: value)

func toFormField*(value: Option[float32], fieldName: string, isRequired: bool): FormField = 
  ## Converts field data of float field on Model into FormField to generate HTML Form Fields 
  let mappedValue = value.map(val => val.float64)
  toFormField(mappedValue, fieldName, isRequired)

func toFormField*(value: Option[bool], fieldName: string, isRequired: bool): FormField = 
  ## Converts field data of bool field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.BOOL, bVal: value)

func toFormField*(value: Option[DateTime], fieldName: string, isRequired: bool): FormField = 
  ## Converts field data of DateTime field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.DATE, dtVal: value.map(val => val.format(DATETIME_LOCAL_FORMAT)))

func toFormField*(value: Option[FilePath], fieldName: string, isRequired: bool): FormField =
  ## Converts field data of FilePath field on Model into FormField to generate HTML Form Fields 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.FILE, fileVal: value)

func toFormField*[T](value: T, fieldName: string, isRequired: bool): FormField = 
  ## Helper proc to enable converting non-optional fields into FormField
  toFormField[T](some value, fieldName, isRequired)


## SELECT FIELDS

func toFormField*(value: Option[SomeInteger], fieldName: string, isRequired: bool, options: seq[IntOption]): FormField =
  let mappedValue = value.map(val => val.int64)
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.INTSELECT, intOptions: options, intSeqVal: mappedValue)

func toFormField*(value: Option[string], fieldName: string, isRequired: bool, options: seq[StringOption]): FormField =
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.STRSELECT, strOptions: options, strSeqVal: value)

proc extractFields*[T: Model](model: T): seq[FormField] =
  ## Extracts the metadata of all fields on a model and turns it into seq[FormField] 
  ## which are used to generate HTML form fields. 
  mixin toFormField
  
  result = @[]
  for name, value in model[].fieldPairs:
    const isFkField = value.hasCustomPragma(fk)
    const isEnumField = value is enum
    const isRequiredField = value is not Option

    when isFkField:
      result.add(toSelectFormField(value, name, isRequiredField, value.getCustomPragmaVal(fk))) # Last Param is a Model type

    elif isEnumField:
      result.add(toSelectFormField(value, name, isRequiredField))

    else:
      result.add(toFormField(value, name, isRequiredField))



# Convert: string from HTML form --> Model value
func toModelValue*(formValue: string, T: typedesc[SomeInteger]): T = parseInt(formValue).T

func toModelValue*(formValue: string, T: typedesc[SomeFloat]): T = parseFloat(formValue).T

func toModelValue*(formValue: string, T: typedesc[string]): T = formValue

func toModelValue*(formValue: string, T: typedesc[bool]): T = parseBool(formValue)

proc toModelValue*(formValue: string, T: typedesc[DateTime]): T = parse(formValue, DATETIME_LOCAL_FORMAT)

func toModelValue*[T: enum](formValue: string, O: typedesc[T]): T = (parseInt(formValue)).T

func toModelValue*[T](formValue: string, O: typedesc[Option[T]]): O = 
  let hasValue = formValue != ""
  result = if hasValue: some formValue.toModelValue(T) else: none(T)


proc saveFile(ctx: Context, fileFieldName: string, mediaDirectory: string, subdir: Option[string]): string =
  let file = ctx.getUploadFile(fileFieldName)
  if not dirExists(mediaDirectory):
   raise newException(IOError, fmt"The media directory '{mediaDirectory}' does not exist or is not accessible. Configure one with the setting '{MEDIA_ROOT_SETTING}' or create it/make it accessible.")
  
  let isStoredInSubDirectory = subdir.isSome()
  let storageDirectory = if isStoredInSubDirectory: fmt"{mediaDirectory}/{subdir.get()}" else: fmt"{mediaDirectory}"

  if not dirExists(storageDirectory):
    createDir(storageDirectory)

  file.save(storageDirectory)
  let fullFilepath = fmt"{storageDirectory}/{file.fileName}"
  result = fullFilepath
  


proc handleFileFormData(ctx: Context, fileFieldName: string, subdir: Option[string]): FilePath =
  ## Handles files sent via HTTP requests. Stores the file and returns the filepath.
  let mediaDirectory = ctx.getSettings(MEDIA_ROOT_SETTING).getStr(DEFAULT_MEDIA_ROOT)

  let fullFilePath = ctx.saveFile(fileFieldName, mediaDirectory, subdir)
  result = fullFilePath.FilePath

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
        const isFileField = typeOf(dummyValue) is FilePath
        when isFileField:
          const hasSubDirectory = hasCustomPragma(dummyValue, subdir)
          const fileSubdir = when hasSubDirectory: some(getCustomPragmaVal(dummyValue, subdir)) else: none(string)
          let formValue = handleFileFormData(ctx, name, fileSubdir)
          result.setField(name, formValue)

        else:
          let formValue = formValueStr.get().toModelValue(typeOf(dummyValue))
          result.setField(name, formValue)
