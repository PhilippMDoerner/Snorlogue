import std/[unittest, httpclient, strutils, logging, times, options, strformat]

proc expectHttpCode*(response: Response, expectedResponseCode: int) =
  check response.code() == expectedResponseCode.HttpCode

proc expectBodyContent*(response: Response, expectedContent: openArray[string]) =
  let body = response.body()

  for str in expectedContent:
    let passesCheck = str in body
    if not passesCheck:
      let isShortResponse = body.len() < 3000
      let container = if isShortResponse: body else: "response"
      debug fmt"Could not find '{str}' in {container}"

    assert passesCheck

proc expectBodyContent*[T: ref object](response: Response, expectedContent: T) =
  var expectedStrings: seq[string] = @[]
  for fieldName, fieldValue in expectedContent[].fieldPairs:
    expectedStrings.add fieldName
    when fieldValue isnot Option and fieldValue isnot DateTime and fieldValue isnot SomeFloat:
      expectedStrings.add $fieldValue

  response.expectBodyContent(expectedStrings)