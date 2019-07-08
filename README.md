## Introduction
This is sample project for user managment with mappView. It uses the B&R library to access and modify user rights.

![I'm a relative reference to a repository file](https://github.com/stephan1827/mappView-User/blob/master/Logical/mappView/Resources/Media/screenshot.png)

The passwords for the users in this demo is the user name all lower case.

## Requirements
* Automation Studio 4.5
* mappView 5.6
* Automation Runtime D4.52

## Description
The sample consists of two main components. The sample page to manage all important settings for users and the task that drives the ArUser library. The following functions are currently supported.

* Create and delete user
* Change password
* Import export user information
* Assign and remove roles from users

The task and mappView visualazation use an interface to communicate that can also be used to trigger functions external. The structure looks as follows:

ArUser
* CMD -> Used to trigger commands like create user, change password, ...
  * UserCreate
  * UserDelete
  * PasswordChange
  * RoleAssign
  * RoleRemove
  * Import
  * Export
* PAR -> Parameters like user name, file path to export data, ...
  * FilePath -> This is where import and export files are stored
  * UserName -> The user name affected by a command
  * UserRole -> The user role used with the assign and remove command
  * Password -> Password used for user create and password change
  * PasswordRepeat -> Must match the password in prvious variable 'Password'
* DAT -> User data and roles as well as some status information
  * Users -> A list with all users in the system
    * Name -> Name of user
    * Roles -> Roles assigned with user
  * Roles -> A list with all roles in the system
  * Status -> Shows the last command result or error message
  * UserActive -> This is the user that is currently logged in
* VIS -> Data specific for the visualization
  * ListUsers -> Data provider for list box
  * ListUsersIndex -> Index for user list box
  * ListRoles -> Data provider for list box
  * ListRolesIndex -> Index for role list box
  * RoleDeleteEnabled -> Enables/Disables button to delete a role
  * UserDeleteEnabled -> Enables/Disables button to delete a user
  * ShowMessageBoxOK -> Show message box when command was successfull
  * ShowMessageBoxOK -> Show message box when command was not successfull
* ERR -> Information about errors
  * Number -> Error number
  * State -> State where the error occured

## Limitations
* The sample is not yet multi client capable
* Roles can not be created or deleted. This is due to the fact that the permission for roles can not be changed on the fly.

## Revision History

#### Version 0.1
First public release
