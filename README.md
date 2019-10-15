## Table of Contents
* [Introduction](#Introduction)
* [Requirements](#Requirements)
* [Description](#Description)
* [Limitations](#Limitations)
* [Revision History](#Revision-History)

<a name="Introduction"></a>
## Introduction
This is a sample project for a user managment with mappView. It uses the B&R library ArUser to access and modify user rights. There is an extended sample with RFID reader support available as separat [**branch**](https://github.com/stephan1827/mappView-User/tree/RFID).

![](Logical/mappView/Resources/Media/screenshot.png)

The passwords for the users in this demo is the user name all lower case. Also see [**How to import the user management into an existing project.**](Logical/mappUser/HowToImport.pdf) Download the latest release from [**here.**](https://github.com/stephan1827/mappView-User/archive/V0.3.zip)

<a name="Requirements"></a>
## Requirements
* Automation Studio 4.5
* mappView 5.6
* Automation Runtime D4.52

Recommended task class is #8 with a 10ms cycle time.

<a name="Description"></a>
## Description
The sample consists of two main components. The sample page is used to display all important settings for users and roles. The task UserManagement drives the user managamnet and uses the ArUser library in the background. The following functions are currently supported.

* Create, rename and delete user
* Assign and remove roles from users
* Change password
* Import export user information


The sample supports up to 3 concurrent client connections. While the task itself can only execute one command at a time the commands are executed so fast that this should not be an issue. The refresh command may take longer but the response data is distributed to all seesions. The task and mappView visualization use an interface to communicate that can also be used to trigger functions external. The structure looks as follows:

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
  * ListRefresh
  * ErrorReset
* PAR -> Parameters like user name, file path to export data, ...
  * FilePath -> This is where import and export files are stored. Note that this is the absolute path and not a file device as it would be used for many other functions. Use "F:/" for the user partition.
  * UserName -> The user name affected by a command
  * UserNameNew -> The new user name used when renaming a user
  * UserRole -> The user role used with the assign and remove command
  * Password -> Password used for user create and password change
  * PasswordRepeat -> Must match the password in prvious variable 'Password'
  * VisuSlotID -> This is the session ID for the current command. This is used to identify where to send response messages.
* DAT -> User data and roles as well as some status information
  * Users -> A list with all users in the system
    * Name -> Name of user
    * Roles -> Roles assigned with user
  * Roles -> A list with all roles in the system
  * Status -> Shows the result for the last command
  * UserActive -> This is a list of users that are currently logged in
* VIS -> Data specific for the visualization. The structure is an array, one for each client session
  * ListUsers -> Data provider of list box for all users
  * ListUsersIndex -> Index of user list box for all users
  * ListUserValue -> Selected user name
  * ListUserRole -> Data provider of list box for selected user roles
  * ListUserRoleIndex -> Index of user list box for selected user roles
  * ListRoles -> Data provider of list box for all roles
  * ListRolesIndex -> Index of role list box for all roles
  * RoleDeleteEnabled -> Enables/Disables the button to delete a role
  * UserDeleteEnabled -> Enables/Disables the button to delete or rename a user
  * ShowMessageBoxOK -> Show a message box when command was successful
  * ShowMessageBoxError -> Show a message box when command was not successful
* ERR -> Information about errors
  * No -> Error number
  * State -> State where the error occurred
  * Text -> Error text

<a name="Limitations"></a>
## Limitations
* Roles cannot be created or deleted. This is because the permission for roles cannot be changed on the fly.

<a name="Revision-History"></a>
## Revision History

#### Version 0.5
- Multi client support
- Changed error structure

#### Version 0.4
- Software structure change to work with future expansion
- Make sure passwords match before user is created

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
