import std/[unittest, strformat, httpclient, logging, options]
import ./utils/[constants, serverSetup, databaseSetup, responseValidators]
import ./utils/testModels/[creature]

addHandler(newConsoleLogger(levelThreshold = lvlDebug))

startServer()

suite "Testing POST Endpoint":
  setup:
    setupDatabase()

  teardown:
    resetDatabase()

  test """
    Given a server with snorlogue and a registered Model
    When creating a Model via POST request
    Then it should return created model and put model into database
  """:
    #Given
    var client = newHttpClient()

    let model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "post",
      "name": model.name,
      "description": model.description.get(),
      "family": $(model.family.int) ,
      "birthDate": "2022-01-01T00:00",
      "evilness": $model.evilness,
      "evilness2": $model.evilness2,
      "evilness3": $model.evilness3,
      "count": $model.count,
      "count2": $model.count2,
      "count3": $model.count3,
      "isCool": $model.isCool
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(200)
    echo response.body()
    var allCreatures = @[model]
    conn.selectAll(allCreatures)
    check allCreatures.len() == 1
    check allCreatures[0].name == model.name
    check allCreatures[0].id > 0

    conn.close()

  test """
    Given a server with snorlogue and a registered Model
    When creating a Model via POST request with optional fields being empty strings in FormData
    Then it should store models with optional fields being 'none'
  """:
    #Given
    var client = newHttpClient()

    let model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "post",
      "name": model.name,
      "description": "",
      "family": $(model.family.int) ,
      "birthDate": "2022-01-01T00:00",
      "evilness": $model.evilness,
      "evilness2": $model.evilness2,
      "evilness3": $model.evilness3,
      "count": $model.count,
      "count2": $model.count2,
      "count3": $model.count3,
      "isCool": $model.isCool
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(200)

    var allCreatures = @[model]
    conn.selectAll(allCreatures)
    check allCreatures.len() == 1
    check allCreatures[0].description.isNone()

    conn.close()

  test """
    Given a server with snorlogue and a registered Model
    When creating a Model via POST request with non-optional fields being empty strings in FormData
    Then it should return HTTP400
  """:
    #Given
    var client = newHttpClient()

    let model = getDummyCreature()

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "post",
      "name": model.name,
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(500)


stopServer()