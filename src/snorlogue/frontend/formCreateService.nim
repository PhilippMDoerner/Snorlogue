import std/[times, sugar, options, strformat, sequtils, algorithm, typetraits]
import norm/[pragmas, pragmasutils, model]
import prologue
import ./fieldUtils/[fieldTypes]
import ../filePathType
import ../constants
import ../genericRepository

export fieldTypes
export filePathType


func toFormField*(value: Option[string], fieldName: string): FormField = 
  ## Converts a string field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, kind: FormFieldKind.STRING, strVal: value)

func toFormField*(value: Option[int64], fieldName: string): FormField = 
  ## Converts a int64 field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, kind: FormFieldKind.INT, iVal: value)

func toFormField*(value: Option[int], fieldName: string): FormField = 
  ## Converts a int field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  let mappedValue = value.map(val => val.int64)
  toFormField(mappedValue, fieldName)

func toFormField*(value: Option[int32], fieldName: string): FormField = 
  ## Converts a int32 field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  let mappedValue = value.map(val => val.int64)
  toFormField(mappedValue, fieldName)
  
func toFormField*(value: Option[Natural], fieldName: string): FormField = 
  ## Converts a int field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  let mappedValue = value.map(val => val.int64)
  toFormField(mappedValue, fieldName)

func toFormField*(value: Option[float64], fieldName: string): FormField = 
  ## Converts a float64 field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, kind: FormFieldKind.FLOAT, fVal: value)

func toFormField*(value: Option[float32], fieldName: string): FormField = 
  ## Converts a float32 field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  let mappedValue = value.map(val => val.float64)
  toFormField(mappedValue, fieldName)

func toFormField*(value: Option[bool], fieldName: string): FormField = 
  ## Converts a bool field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, kind: FormFieldKind.BOOL, bVal: value)

func toFormField*(value: Option[DateTime], fieldName: string): FormField = 
  ## Converts a DateTime field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  let mappedValue: Option[string] = value.map(val => val.format(DATETIME_LOCAL_FORMAT))
  FormField(name: fieldName, kind: FormFieldKind.DATE, dtVal: mappedValue)

func toFormField*(value: Option[FilePath], fieldName: string): FormField =
  ## Converts a FilePath field on Model into `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata 
  FormField(name: fieldName, kind: FormFieldKind.FILE, fileVal: value)

func toIntSelectField(value: Option[int64], fieldName: string, options: var seq[IntOption]): FormField =
  options.sort((opt1, opt2: IntOption) => cmp(opt1.name, opt2.name))
  
  result.name = fieldName
  result.kind = FormFieldKind.INTSELECT
  result.intSeqVal = value
  result.intOptions = options

# Disabled as a compiler bug causes this proc to be chosen also for string and int types instead of their appropriate overloads
# func toFormField*[T: enum or range](value: Option[T], fieldName: string): FormField =
#   ## Converts an enum or range field on Model into a select 
#   ## `FormField<fieldTypes.html#FormField>`_ with int values.
#   ## 
#   ## Note: This can not be split into 2 separate procs, as the compiler will
#   ## immediately complain about ambiguity issues for the `TaintedString` type.
#   var options: seq[IntOption] = @[]
#   var formFieldValue: Option[int64] = none(int64)
#   when T is enum:
#     for enumValue in T:
#       options.add(IntOption(name: $enumValue, value: enumValue.int))
    
#     # This must be within when statement as otherwise it throws:
#     # `type mismatch: got 'TaintedString' for 'val' but expected 'int64'`
#     formFieldValue = value.map(val => val.int64)

#   elif T is range:
#     const rangeName = T.name
#     for rangeVal in T.low..T.high:
#       options.add(IntOption(name: fmt"{rangeName} {rangeVal}", value: rangeVal.int))

#     formFieldValue = value.map(val => val.int64)

#   toIntSelectField(formFieldValue, fieldName, options)

func toFormField*[T](value: T, fieldName: string): FormField = 
  ## Helper proc to enable converting non-optional fields into 
  ## `FormField<fieldUtils/fieldTypes.html#FormField>`_ metadata
  when T is DateTime:
    if value.isInitialized():
      toFormField(some value, fieldName)
    else:
      toFormField(none DateTime, fieldName)
  else:
    toFormField[T](some value, fieldName)

proc toForeignKeyField*[T: Model](value: Option[int64], fieldName: static string, foreignKeyModelType: typedesc[T]): FormField =
  ## Helper proc to convert a foreign key field on a Model into a select 
  ## `FormField<fieldTypes.html#FormField>`_ with int value.
  let fkEntries = listAll(T)
  let fkOptions = fkEntries.mapIt(IntOption(name: $it, value: it.id))

  toIntSelectField(value, fieldName, fkOptions)

proc toForeignKeyField*[T: Model](value: int64, fieldName: static string, foreignKeyModelType: typedesc[T]): FormField =
  ## Helper proc to convert a non-optional foreign key field on a Model into a 
  ## select `FormField<fieldTypes.html#FormField>`_ with int value.
  toForeignKeyField(some value, fieldName, T)

proc extractFields*[T: Model](model: T): seq[FormField] =
  ## Converts the fields on a model into a sequence of `FormField<fieldUtils/fieldTypes.html#FormField>`_. 
  mixin toFormField
  
  result = @[]
  for name, value in model[].fieldPairs:
    const isFkField = pragmasutils.hasCustomPragma(value, fk) # Required due to ambiguiity between pragmasutils.hasCustomPragma and macros.hasCustomPragma

    var formField: FormField
    when isFkField:
      formField = toSelectFormField(value, name, value.getCustomPragmaVal(fk)) # Last Param is a Model type

    else:
      formField = toFormField(value, name)
    
    const isRequiredField = value isnot Option
    formField.isRequired = isRequiredField
    result.add(formField)