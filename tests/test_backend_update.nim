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
    When updating a Model via POST request by using "request-type" "put" in FormData
    Then it should update model in the database
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)

    Creature.expectModelCount(1)

    #When
    const newModelName = "A new name for the model"
    var data: MultipartData = newMultipartData({
      "request-type": "put",
      "id": $model.id,
      "name": newModelName ,
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
    check allCreatures[0].name == newModelName
    check allCreatures[0].id == model.id

    conn.close()

  test """
    Given a server with snorlogue and a registered Model with 1 database entry
    When updating a Model via POST request by using "request-type" "put" in FormData
    Then it should update model in the database
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)

    Creature.expectModelCount(1)

    #When
    const newModelName = "A new name for the model"
    var data: MultipartData = newMultipartData({
      "request-type": "put",
      "id": $model.id,
      "name": newModelName ,
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
    check allCreatures[0].name == newModelName
    check allCreatures[0].id == model.id

    conn.close()

  test """
    Given a server with snorlogue, a registered Model with 1 database entry
    When updating a Model via POST request by using "request-type" "put" in FormData and missing mandatory model-field "id" in formData
    Then it should return HTTP500 and not update any entry
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)

    Creature.expectModelCount(1)

    #When
    const newModelName = "A new name for the model"
    var data: MultipartData = newMultipartData({
      "request-type": "put",
      "name": newModelName ,
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

    var allCreatures = @[model]
    conn.selectAll(allCreatures)
    check allCreatures.len() == 1
    check allCreatures[0].name == model.name
    check allCreatures[0].id == model.id

    conn.close()

  test """
    Given a server with snorlogue, a registered Model with 1 database entry
    When updating a Model via POST request by using "request-type" "put" in FormData and missing mandatory model-field "count" in formData
    Then it should return HTTP500 and not update any entry
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)

    Creature.expectModelCount(1)

    #When
    const newModelName = "A new name for the model"
    var data: MultipartData = newMultipartData({
      "request-type": "put",
      "id": $model.id,
      "name": newModelName ,
      "description": model.description.get(),
      "family": $(model.family.int) ,
      "birthDate": "2022-01-01T00:00",
      "evilness": $model.evilness,
      "evilness2": $model.evilness2,
      "evilness3": $model.evilness3,
      "count2": $model.count2,
      "count3": $model.count3,
      "isCool": $model.isCool
    })

    let url = fmt"{TEST_SERVER_DOMAIN}/admin/creature/"
    let response = client.post(url, multipart=data)

    #Then
    response.expectHttpCode(500)

    var allCreatures = @[model]
    conn.selectAll(allCreatures)
    check allCreatures.len() == 1
    check allCreatures[0].count == model.count
    check allCreatures[0].id == model.id

    conn.close()

  test """
    Given a server with snorlogue and a registered Model
    When updating a Model via POST request by using "request-type" "put" in FormData and not allowing redirects
    Then it should make it visible that after model update you get redirected by returning HTTP301
  """:
    #Given
    var client = newHttpClient(maxRedirects = 0)

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)
    conn.close()

    Creature.expectModelCount(1)

    #When
    const newModelName = "A new name for the model"
    var data: MultipartData = newMultipartData({
      "request-type": "post",
      "id": $model.id,
      "name": newModelName,
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
    Given a server with snorlogue and a registered Model with 1 database entry
    When updating a Model via POST request by using "request-type" "put" in FormData and FormData contains a superfluous additional field like "superfluous-field"
    Then it should update model in the database
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)

    Creature.expectModelCount(1)

    #When
    const newModelName = "A new name for the model"
    const superfluousValue =  "I will not show up anywhere"
    var data: MultipartData = newMultipartData({
      "request-type": "put",
      "id": $model.id,
      "superfluous field": superfluousValue,
      "name": newModelName ,
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
    check allCreatures[0].name == newModelName
    check allCreatures[0].id == model.id

    for fieldName, value in allCreatures[0][].fieldPairs:
      check superfluousValue notin value.repr

    conn.close()

  test """
    Given a server with snorlogue and a registered Model with 1 database entry
    When updating a Model via POST request by using invalid "request-type" as empty string in FormData
    Then it should return HTTP 500 and not update entry
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)

    Creature.expectModelCount(1)

    #When
    const newModelName = "A new name for the model"
    var data: MultipartData = newMultipartData({
      "request-type": "",
      "id": $model.id,
      "name": newModelName ,
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

    var allCreatures = @[model]
    conn.selectAll(allCreatures)
    check allCreatures.len() == 1
    check allCreatures[0].name == model.name
    check allCreatures[0].id == model.id

    conn.close()

  test """
    Given a server with snorlogue and a registered Model with 1 database entry
    When updating a Model via POST request by using not providing "request-type" in FormData
    Then it should return HTTP 500 and not update entry
  """:
    #Given
    var client = newHttpClient()

    var model = getDummyCreature()
    let conn = getServerDbConn()
    conn.createTables(model)
    conn.insert(model)

    Creature.expectModelCount(1)

    #When
    const newModelName = "A new name for the model"
    var data: MultipartData = newMultipartData({
      "request-type": "",
      "id": $model.id,
      "name": newModelName ,
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

    var allCreatures = @[model]
    conn.selectAll(allCreatures)
    check allCreatures.len() == 1
    check allCreatures[0].name == model.name
    check allCreatures[0].id == model.id

    conn.close()


stopServer()