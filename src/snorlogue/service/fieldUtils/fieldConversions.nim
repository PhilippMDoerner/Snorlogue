import std/[times, strutils, sugar, json, os, options, strformat, logging, typetraits]
import norm/[pragmas, pragmasutils, model]
import prologue
import ../../constants
import ../../utils/macroUtils
import ./fieldTypes
import ./selectFieldUtils
import ./fileFieldUtils

export fieldTypes
export fileFieldUtils


## Provides 2 sets of overloadable core functions for formService 
## 1) `toFormField`: convert fields on norm Models to metadata used to render HTML form fields 
## 2) `toModelValue`: convert string values from HTML form data received via HTTP request into values for the corresponding norm model field


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

