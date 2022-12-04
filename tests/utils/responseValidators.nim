import std/[unittest, httpclient, strutils, logging, times, options, strformat]

template expectHttpCode*(response: Response, expectedResponseCode: int) =
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

template expectModelCount*(modelType: typed, expectedModelCount: int) =
  let con = getServerDbConn()
  check con.count(modelType) == expectedModelCount
  con.close()




