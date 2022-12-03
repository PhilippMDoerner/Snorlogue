<h1> 
    SNORLOGUE IS NOT YET FINISHED AND THUS NOT YET AVAILABLE <br>
    THE TEXT BELOW IS MERELY IN PREPARATION
</h1>

[![github pages](https://github.com/PhilippMDoerner/Snorlogue/actions/workflows/docs.yml/badge.svg)](https://github.com/PhilippMDoerner/Snorlogue/actions/workflows/docs.yml)

# Snorlogue 
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