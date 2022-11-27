import std/[times, strutils, sugar, json, os, options, strformat, logging, typetraits]
import norm/[pragmas, pragmasutils, model]
import prologue
import ../utils/macroUtils
import ./fieldUtils/[fieldTypes, selectFieldUtils, fileFieldUtils, fieldConversions]
import ../constants

export fieldTypes
export fileFieldUtils


proc extractFields*[T: Model](model: T): seq[FormField] =
  ## Converts the fields on a model into a sequence of `FormField<fieldUtils/fieldTypes.html#FormField>`_. 
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
          let formValue: string = handleFileFormData(ctx, name, fileSubdir)
          result.setField(name, formValue)

        else:
          let formValue = formValueStr.get().toModelValue(typeOf(dummyValue))
          result.setField(name, formValue)
