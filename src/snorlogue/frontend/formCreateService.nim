import std/[times, sugar, json, options]
import norm/[pragmas, pragmasutils, model]
import prologue
import ./fieldUtils/[fieldTypes, selectFieldUtils]
import ../filePathType
import ../constants

export fieldTypes
export filePathType


func toFormField*(value: Option[string], fieldName: string, isRequired: bool): FormField = 
  ## Converts a string field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.STRING, strVal: value)

func toFormField*(value: Option[int64], fieldName: string, isRequired: bool): FormField = 
  ## Converts a int field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.INT, iVal: value)

func toFormField*(value: Option[int], fieldName: string, isRequired: bool): FormField = 
  ## Converts a int field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  let mappedValue = value.map(val => val.int64)
  toFormField(mappedValue, fieldName, isRequired)

func toFormField*(value: Option[int32], fieldName: string, isRequired: bool): FormField = 
  ## Converts a int field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  let mappedValue = value.map(val => val.int64)
  toFormField(mappedValue, fieldName, isRequired)
  
func toFormField*(value: Option[Natural], fieldName: string, isRequired: bool): FormField = 
  ## Converts a int field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  let mappedValue = value.map(val => val.int64)
  toFormField(mappedValue, fieldName, isRequired)

func toFormField*(value: Option[float64], fieldName: string, isRequired: bool): FormField = 
  ## Converts a float field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.FLOAT, fVal: value)

func toFormField*(value: Option[float32], fieldName: string, isRequired: bool): FormField = 
  ## Converts a float field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  let mappedValue = value.map(val => val.float64)
  toFormField(mappedValue, fieldName, isRequired)

func toFormField*(value: Option[bool], fieldName: string, isRequired: bool): FormField = 
  ## Converts a bool field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.BOOL, bVal: value)

func toFormField*(value: Option[DateTime], fieldName: string, isRequired: bool): FormField = 
  ## Converts a DateTime field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.DATE, dtVal: value.map(val => val.format(DATETIME_LOCAL_FORMAT)))

func toFormField*(value: Option[FilePath], fieldName: string, isRequired: bool): FormField =
  ## Converts a FilePath field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.FILE, fileVal: value)

func toFormField*[T](value: T, fieldName: string, isRequired: bool): FormField = 
  ## Helper proc to enable converting non-optional fields into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata
  toFormField[T](some value, fieldName, isRequired)


## SELECT FIELDS
func toFormField*(value: Option[SomeInteger], fieldName: string, isRequired: bool, options: seq[IntOption]): FormField =
  ## Converts an integer field into select `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata with int values
  let mappedValue = value.map(val => val.int64)
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.INTSELECT, intOptions: options, intSeqVal: mappedValue)

func toFormField*(value: Option[string], fieldName: string, isRequired: bool, options: seq[StringOption]): FormField =
  ## Converts a string field into select `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata with string values
  FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.STRSELECT, strOptions: options, strSeqVal: value)



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