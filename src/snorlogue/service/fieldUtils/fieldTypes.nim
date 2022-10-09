import std/[options]

type Filename* = distinct string

type IntOption* = object
  name*: string
  value*: int64

type StringOption* = object
  name*: string
  value*: string

type FormFieldKind* = enum
  STRING
  INT
  FLOAT
  DATE
  BOOL
  INTSELECT
  STRSELECT
  FILE

type FormField* = object
  name*: string
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
    fileVal*: Option[Filename]
