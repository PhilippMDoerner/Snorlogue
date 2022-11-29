import std/[times, strutils, json, os, options, strformat, logging, typetraits]
import norm/[pragmasutils, model]
import prologue
import ../macroUtils
import ../filePathType
import ../constants

export filePathType

## Parses form data from HTTP requests to model data via the overloadable `toModelValue` proc.

func toModelValue*(formValue: string, T: typedesc[SomeInteger]): T = 
  ## Converts an HTML form value in string format to an integer 
  parseInt(formValue).T

func toModelValue*(formValue: string, T: typedesc[SomeFloat]): T = 
  ## Converts an HTML form value in string format to a float 
  parseFloat(formValue).T

func toModelValue*(formValue: string, T: typedesc[string]): T = 
  ## Converts an HTML form value in string format to a string
  ## This essentially does nothing and exists just to handle strings.
  formValue

func toModelValue*(formValue: string, T: typedesc[bool]): T = 
  ## Converts an HTML form value in string format to a boolean
  parseBool(formValue)

proc toModelValue*(formValue: string, T: typedesc[DateTime]): T = 
  ## Converts an HTML form value in string format to a DateTime instance
  parse(formValue, DATETIME_LOCAL_FORMAT)

func toModelValue*[T: enum](formValue: string, O: typedesc[T]): T = 
  ## Converts an HTML form value in string format to an int value or a distinct int type
  (parseInt(formValue)).T

func toModelValue*[T](formValue: string, O: typedesc[Option[T]]): O = 
  ## Converts an HTML form value in string format to an an optional value.
  ## Empty strings get counted as non-existant values. 
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
  ## Stores a file from an HTTP request in the MEDIA_ROOT directory and returns the filepath.
  let mediaDirectory = ctx.getSettings(MEDIA_ROOT_SETTING).getStr(DEFAULT_MEDIA_ROOT)

  let fullFilePath = ctx.saveFile(fileFieldName, mediaDirectory, subdir)
  result = fullFilePath.FilePath

proc parseFormData*[T: Model](ctx: Context, model: typedesc[T], skipIdField: static bool = false): T =
  ## Parses form data from an HTTP request body in `ctx` into a model instance of the 
  ## specified `model` type.
  ## Allows skipping setting the id field when the formData can not contain an id, e.g. when a model 
  ## gets created.
  result = T()
  for name, dummyValue in T()[].fieldPairs:
    let formValueStr: Option[string] = ctx.getFormParamsOption(name)
    
    if formValueStr.isNone():
      when dummyValue is Option:
        # Model Field can be nil (is Optional) and Form value is nil --> set to none
        result.setField(name, none(genericParams(dummyValue.type()).get(0)))
      
      else: 
        # Model Field must not be nil (is not Optional) and Form value is nil --> Error
        const modelName = $T
        const fieldName = name
        debug(fmt"Sent request is missing the '{fieldName}' field from the model type '{modelName}'")
    
    else:
      # Model Field is id Field and id field shall not be filled (e.g. because there is no id during creation)
      const isIdField = name == "id"
      when isIdField and skipIdField:
        discard #Do nothing

      # Model Field is any other Field and must not be nil (is not Optional) and Form value is not nil --> Parse form value into field
      else:
        const isFileField = typeOf(dummyValue) is FilePath
        # Model Field is FileField: Handle File first
        when isFileField:
          const hasSubDirectory = hasCustomPragma(dummyValue, subdir)
          const fileSubdir: Option[string] = when hasSubDirectory: some(getCustomPragmaVal(dummyValue, subdir)) else: none(string)
          let formValue: FilePath = handleFileFormData(ctx, name, fileSubdir)
          result.setField(name, formValue)

        else:
          let formValue = formValueStr.get().toModelValue(typeOf(dummyValue))
          result.setField(name, formValue)
