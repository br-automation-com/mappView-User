## Table of Contents
* [Introduction](#Introduction)
* [Requirements](#Requirements)
* [Description](#Description)
* [Limitations](#Limitations)
* [Revision History](#Revision-History)

<a name="Introduction"></a>
## Introduction
This is a sample project for a user managment with mappView. It uses the B&R library ArUser to access and modify user rights.

![](Logical/mappView/Resources/Media/screenshot.png)

The passwords for the users in this demo is the user name all lower case. Also see [**How to import the user management into an existing project.**](Logical/UserManagement/HowToImport.pdf) Download the latest release from [**here.**](https://github.com/stephan1827/mappView-User/archive/V0.3.zip)

<a name="Requirements"></a>
## Requirements
* Automation Studio 4.5
* mappView 5.6
* Automation Runtime D4.52

Recommended task class is #8 with a 10ms cycle time.

<a name="Description"></a>
## Description
The sample consists of two main components. The sample page is used to display all important settings for users and roles. The task UserManagement drives the user managamnet and uses the ArUser library in the backgrounbd. The following functions are currently supported.

* Create, rename and delete user
* Assign and remove roles from users
* Change password
* Import export user information


The task and mappView visualization use an interface to communicate that can also be used to trigger functions external. The structure looks as follows:

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
  * RoleDeleteEnabled -> Enables/Disables the button to delete a role
  * UserDeleteEnabled -> Enables/Disables the button to delete or rename a user
  * ShowMessageBoxOK -> Show a message box when command was successfull
  * ShowMessageBoxError -> Show a message box when command was not successfull
* ERR -> Information about errors
  * Number -> Error number
  * State -> State where the error occured

<a name="Limitations"></a>
## Limitations
* The sample is not yet multi client capable
* Roles cannot be created or deleted. This is because the permission for roles cannot be changed on the fly.

<a name="Revision-History"></a>
## Revision History

#### Version 0.3
- Automatically set password when new user is created
- Erase password field when user logs out
- New command to rename user

#### Version 0.2
- Make sure last user cannot be deleted
- Make sure last user cannot delete himself
- Make sure last user cannot be deleted
- Added group box with login
- Added message boxes for success and failed commands
- Visual tweaks and bug fixes

#### Version 0.1
First public release
