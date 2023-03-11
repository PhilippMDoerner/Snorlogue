[![github pages](https://github.com/PhilippMDoerner/Snorlogue/actions/workflows/docs.yml/badge.svg)](https://github.com/PhilippMDoerner/Snorlogue/actions/workflows/docs.yml)
[![Run Tests](https://github.com/PhilippMDoerner/Snorlogue/actions/workflows/tests.yml/badge.svg)](https://github.com/PhilippMDoerner/Snorlogue/actions/workflows/tests.yml)

# Snorlogue 
#### _Easy to use, allows you to snooze_
**Snorlogue** is a prologue extension, that provides a set of simple CRUD routes to administrate your database.
It makes use of [norm models](https://github.com/moigagoo/norm) to figure out which columns a given table has and how to best represent them.

- [Documentation](https://philippmdoerner.github.io/Snorlogue/bookCompiled/) (built with [nimibook](https://github.com/pietroppeter/nimibook))
- [API index](https://philippmdoerner.github.io/Snorlogue/)

## Installation
Install Snorlogue with [Nimble](https://github.com/nim-lang/nimble):

    $ nimble install -y snorlogue

Add Snorlogue to your .nimble file:

    requires "snorlogue"

Finally, copy the resources folder from the snorlogue package into your project directory. It contains the HTML templates for the various admin pages. This will likely not be necessary in future versions of Snorlogue.
    
    cp -r <NIMBLE_DIRECTORY>/pkgs/snorlogue-X.X.X/snorlogue/resources <YOUR_PROJECT_DIRECTORY>/src


## Feature-Scope Overview
Snorlogue provides the following pages:
- **Table Overview** - Shows all registered Model-types and their corresponding SQL tables
- **SQL** - Enables direct interaction with the database. Only allows DML-SQL, not DDL-SQL.
- **About** - Displays configs and routes of your prologue application in general
- **Model Table Overview** - Shows all entries of a given Model in a paginated list
- **Model CRUD pages** - Pages enabling Create/Update/Delete interaction with individual Model entries

## Example Screenshots
### Table Overview Page
![Table overview of all tables in example](https://i.imgur.com/YiEumKz.png "Table overview of all tables in example")

### SQL Page
![Page to directly interact with the database](https://i.imgur.com/ImWfufp.png "Page to directly interact with the database")

### About Application Page
![Main Settings of the application and all registered Routes](https://i.imgur.com/IeOPZwW.png "Main Settings of the application and all registered Routes")


### Model Table Overview Page
![List view of specific table in example](https://i.imgur.com/jSIDADh.png "List view of specific table in example")

### Create Model Page
![Create Form for a specific model in example](https://i.imgur.com/ElycVrY.png "Create Form for a specific model in example")

### Update Model Page
![Update Form for a specific model in example](https://i.imgur.com/QffpYHn.png "Update Form for a specific model in example")

## Running Tests
Clone the repository. Make sure you have docker and docker-compose installed (this is necessary as all tests run in a container) and a running internet connection.

    $ nimble sqliteTests        # Runs the entire test-suite using an sqlite database
    $ nimble postgresTests      # Runs the entire test-suite using a postgres database container