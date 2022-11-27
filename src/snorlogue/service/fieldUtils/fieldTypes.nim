import std/[options]

type FilePath* = distinct string ##
## A convenience type for norm models.
## To be used as type for model fields storing any sort of file.
## When a model with such a field is created, its file will automatically be stored in the 
## in the configured `MEDIA_ROOT<../../constants.html#MEDIA_ROOT_SETTING>`_ directory. Any attempts to fetch that file will also assume
## that it is being stored in the `MEDIA_ROOT` directory.
## 
## This field can use the `subdir<fileFieldUtils.html#subdir.t%2Cstring>`_ pragma to store files in a sub directory within `MEDIA_ROOT` instead.

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
