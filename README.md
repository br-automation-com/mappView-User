## Table of Contents
* [Introduction](#Introduction)
* [Requirements](#Requirements)
* [Description](#Description)
* [Limitations](#Limitations)
* [Revision History](#Revision-History)

<a name="Introduction"></a>
## Introduction
This is an extension to the sample project for the user managment with mappView. It uses the B&R RFID reader to identify and login users automatically. For details about the standard example see the [**master**](https://github.com/stephan1827/mappView-User) branch.

![](Logical/mappView/Resources/Media/screenshot.png)

Also see [**How to import the user management into an existing project.**](/Logical/mappUser/HowToImport.pdf) Download the latest release from [**here.**](https://github.com/stephan1827/mappView-User/archive/V0.4.zip)

<a name="Requirements"></a>
## Requirements
* Automation Studio 4.5
* mappView 5.6
* Automation Runtime D4.52
* RFID Reader 5E9010.29

Recommended task class is #8 with a 10ms cycle time.

<a name="Description"></a>
## Description
The task RFID controls the RFID reader connected via USB to the PLC. The reader will be automatically detected. When a token/key is presented to the reader, the token data is read and the user identified. The token data is also used as user password. This has the advantage that the user can login even if the reader is not available. The following functions are currently supported.

* Scan USB for RFID reader
* Assign token to user
* Remove token from user

The task and mappView visualization use an interface to communicate that can also be used to trigger functions external. 

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

### Assign a token to user
1.	Select the user to which the token should be assigned. If this is a new user create the user with an empty password first
2.	Present the token to the reader, a message box should indicate that this token is not assigned to any user yet

![](/Logical/mappView/Resources/Media/RFID2.png)

3.	Acknowledge the message box with OK
4.	Press the “Assign Token” button to connect the token and user

![](/Logical/mappView/Resources/Media/RFID1.png)

### Remove token from user
If the token is removed from a user the password will be set identically to the user name. Remember to change the password to something more advanced after removing the token from a user.

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
