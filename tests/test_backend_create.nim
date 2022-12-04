import std/[unittest, strformat, httpclient, logging, options, strutils]
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
    Then it should put model into database
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

    var allCreatures = @[model]
    conn.selectAll(allCreatures)
    check allCreatures.len() == 1
    check allCreatures[0].name == model.name
    check allCreatures[0].id > 0

    conn.close()



  test """
    Given a server with snorlogue and a registered Model
    When creating a Model via POST request with optional model-field "description" being empty strings in FormData
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
    When creating a Model via POST request and not allowing redirects
    Then it should make it visible that after model creation you get redirected by returning HTTP301
  """:
    #Given
    var client = newHttpClient(maxRedirects = 0)

    let model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.close()

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
    response.expectHttpCode(301)



  test """
    Given a server with snorlogue and a registered Model
    When creating a Model via POST request with non-optional model-field "name" being empty strings in FormData
    Then it should create the model with empty string as the value for that field.
  """:
    #Given
    var client = newHttpClient()

    let model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "post",
      "name": "",
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

    var allCreatures = @[model]
    conn.selectAll(allCreatures)
    check allCreatures.len() == 1
    check allCreatures[0].name == ""

    conn.close()


  test """
    Given a server with snorlogue and a registered Model
    When creating a Model via POST request with non-optional model-field "name" missing from FormData
    Then it should return HTTP500
  """:
    #Given
    var client = newHttpClient()

    let model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.close()

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "post",
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
    response.expectHttpCode(500)



  test """
    Given a server with snorlogue and a registered Model
    When creating a Model via POST request with non-optional request-field "request-type" missing from FormData
    Then it should return HTTP500
  """:
    #Given
    var client = newHttpClient()

    let model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.close()

    #When
    var data: MultipartData = newMultipartData({
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
    response.expectHttpCode(500)



  test """
    Given a server with snorlogue and a registered Model
    When creating a Model via POST request with non-optional request-field "request-type" having empty string as value from FormData
    Then it should return HTTP500
  """:
    #Given
    var client = newHttpClient()

    let model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.close()

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "",
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
    response.expectHttpCode(500)


  test """
    Given a server with snorlogue and a registered Model
    When creating a Model via POST request and FormData contains a superfluous additional field like "superfluous-field"
    Then it should store model in the database and ignore superfluous field
  """:
    #Given
    var client = newHttpClient()

    let model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)

    #When
    const superfluousValue =  "I will not show up anywhere"
    var data: MultipartData = newMultipartData({
      "request-type": "post",
      "superfluous-field": superfluousValue,
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

    var allCreatures = @[model]
    conn.selectAll(allCreatures)
    check allCreatures.len() == 1
    check allCreatures[0].name == model.name
    check allCreatures[0].id > 0

    for fieldName, value in allCreatures[0][].fieldPairs:
      check superfluousValue notin value.repr

    conn.close()

stopServer()