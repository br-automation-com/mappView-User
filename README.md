## Introduction
This is sample project for user managment with mappView. It uses the B&R library to access and modify user rights.

![I'm a relative reference to a repository file](https://github.com/stephan1827/mappView-User/blob/master/Logical/mappView/Resources/Media/screenshot.png)

The passwords for the users in this demo is the user name all lower case. Also see [**How to import the user management into an existing project** :orange_book:](https://github.com/stephan1827/mappView-User/blob/master/Logical/UserManagement/HowToImport.pdf)

## Requirements
* Automation Studio 4.5
* mappView 5.6
* Automation Runtime D4.52

Recommended task class is #8 with a 10ms cycle time.

## Description
The sample consists of two main components. The sample page to manage all important settings for users and the task that drives the ArUser library. The following functions are currently supported.

* Create, rename and delete user
* Assign and remove roles from users
* Change password
* Import export user information


The task and mappView visualazation use an interface to communicate that can also be used to trigger functions external. The structure looks as follows:

ArUser
* CMD -> Used to trigger commands like create user, change password, ... A command is triggered by setting it to true, when the command is finished the task will reset the command. This indicates that the command is finished. Do not change any parameters or set another command until the previous command is finished.
  * UserCreate
  * UserDelete
  * UserRename
  * PasswordChange
  * RoleAssign
  * RoleRemove
  * Import
  * Export
* PAR -> Parameters like user name, file path to export data, ...
  * FilePath -> This is where import and export files are stored
  * UserName -> The user name affected by a command
  * UserNameNew -> The new user name used when renaming a user
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
  * UserDeleteEnabled -> Enables/Disables button to delete or rename a user
  * ShowMessageBoxOK -> Show message box when command was successfull
  * ShowMessageBoxError -> Show message box when command was not successfull
* ERR -> Information about errors
  * Number -> Error number
  * State -> State where the error occured

## Limitations
* The sample is not yet multi client capable
* Roles can not be created or deleted. This is due to the fact that the permission for roles can not be changed on the fly.

## Revision History

#### Version 0.3
- Automatically set password when new user is created
- Erase password field when user logs out
- New command to rename user

#### Version 0.2
- Make sure last user can not be deleted
- Make sure last user can not delete himself
- Make sure last user can not be deleted
- Added group box with login
- Added message boxes for success and failed commands
- Visual tweaks and bugfixes

#### Version 0.1
First public release
