import std/[options]
import ../../filePathType

## Provides all types related to `FormField`

type IntOption* = object
  ## A single option of a select `FormField<#FormField>`_ with int values
  name*: string
  value*: int64

type StringOption* = object
  ## A single option of a select `FormField<#FormField>`_ with string values
  name*: string
  value*: string

type FormFieldKind* = enum
  ## The types of various HTML Form fields that can be generated to represent the fields on a norm model.
  STRING
  INT
  FLOAT
  DATE
  BOOL
  INTSELECT
  STRSELECT
  FILE

type FormField* = object
  ## The data used to render a HTML Form Field.
  ## Any nim type must be converted into a `FormField` instance via
  ## `toFormField<../formService.html#toFormField%2COption[bool]%2Cstring%2Cbool>`_ procs.  
  name*: string
  isRequired*: bool
  case kind*: FormFieldKind
  of STRING: 
    strVal*: Option[string]
  of FLOAT: 
    fVal*: Option[float64]
  of INT: 
    iVal*: Option[int64]
  of DATE: 
    dtVal*: Option[string]
  of BOOL: 
    bVal*: Option[bool]
  of INTSELECT: 
    intSeqVal*: Option[int64]
    intOptions*: seq[IntOption]
  of STRSELECT:
    strSeqVal*: Option[string]
    strOptions*: seq[StringOption]
  of FILE:
    fileVal*: Option[FilePath]
