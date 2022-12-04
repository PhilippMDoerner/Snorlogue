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
    Given a server with snorlogue and a registered Model with 1 database entry
    When deleting a Model via POST request by using "request-type" "delete" in FormData
    Then it should delete entry from database
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)
    conn.close()

    Creature.expectModelCount(1)
    
    #When
    var data: MultipartData = newMultipartData({
      "request-type": "delete",
      "id": $model.id
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(200)
    Creature.expectModelCount(0)



  test """
    Given a server with snorlogue and a registered Model with 1 database entry
    When deleting a Model via POST request by using "request-type" "delete" in FormData and leave out "id" field
    Then it should return HTTP500 and not delete any entry
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)
    conn.close()

    Creature.expectModelCount(1)

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "delete",
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(500)
    Creature.expectModelCount(1)

  test """
    Given a server with snorlogue and a registered Model with 1 database entry
    When deleting a Model via POST request by using "request-type" "delete" in FormData and provide invalid "id" field as empty string
    Then it should return HTTP500 and not delete any entry
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)
    conn.close()

    Creature.expectModelCount(1)

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "delete",
      "id": ""
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(500)
    Creature.expectModelCount(1)

  test """
    Given a server with snorlogue and a registered Model with 1 database entry
    When deleting a Model via POST request by using "request-type" "delete" in FormData and provide invalid "id" field as nonexistant id string
    Then it should return HTTP200 but not delete any entry
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)
    conn.close()

    Creature.expectModelCount(1)

    #When
    let nonExistentId = model.id + 1
    var data: MultipartData = newMultipartData({
      "request-type": "delete",
      "id": $nonExistentId
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(200)
    Creature.expectModelCount(1)

  test """
    Given a server with snorlogue and a registered Model
    When delete a Model via POST request by using "request-type" "delete" in FormData and not allowing redirects
    Then it should make it visible that after model deletion you get redirected by returning HTTP301
  """:
    #Given
    var client = newHttpClient(maxRedirects = 0)

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "delete",
      "id": $model.id
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(301)


  test """
    Given a server with snorlogue and a registered Model with 1 database entry
    When deleting a Model via POST request by using "request-type" "delete" in FormData and superfluous fields
    Then it should return HTTP200 and delete entry as normal, ignoring superfluous field
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)
    conn.close()

    Creature.expectModelCount(1)

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "delete",
      "id": $model.id,
      "superfluous-field": "irrelevant"
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(200)
    Creature.expectModelCount(0)


  test """
    Given a server with snorlogue and a registered Model with 1 database entry
    When deleting a Model via POST request by using invalid "request-type" as empty string in FormData
    Then it should return HTTP500 and not delete entry
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)
    conn.close()

    Creature.expectModelCount(1)

    #When
    var data: MultipartData = newMultipartData({
      "request-type": "",
      "id": $model.id,
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(500)
    Creature.expectModelCount(1)

  test """
    Given a server with snorlogue and a registered Model with 1 database entry
    When deleting a Model via POST and missing "request-type" field
    Then it should return HTTP500 and not delete entry
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)
    conn.close()

    Creature.expectModelCount(1)

    #When
    var data: MultipartData = newMultipartData({
      "id": $model.id,
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(500)
    Creature.expectModelCount(1)


stopServer()