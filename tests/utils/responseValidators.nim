import std/[strformat, unittest, httpclient, logging, strutils]

proc expectHttpCode*(response: Response, expectedResponseCode: int) =
  let willValidate = response.code() == expectedResponseCode.HttpCode
  check response.code() == expectedResponseCode.HttpCode

  if not willValidate:
    debug response.body()

proc expectBodyContent*(response: Response, expectedContent: openArray[string]) =
  for str in expectedContent:
    check str in response.body()
