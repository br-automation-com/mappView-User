## Table of Contents
* [Introduction](#Introduction)
* [Requirements](#Requirements)
* [Revision History](#Revision-History)

<a name="Introduction"></a>
## Introduction
This is an extension to the sample project for the user managment with mappView. It uses the B&R RFID reader to identify and login users automatically. For details about the standard example see the [**master**](https://github.com/stephan1827/mappView-User) branch.

![](Logical/mappView/Resources/Media/screenshot.png)

The passwords for the users in this demo is the user name all lower case. Also see [**How to import the user management into an existing project.**](Logical/UserManagement/HowToImport.pdf) Download the latest release from [**here.**](https://github.com/stephan1827/mappView-User/archive/V0.3.zip)

<a name="Requirements"></a>
## Requirements
* Automation Studio 4.5
* mappView 5.7.1
* Automation Runtime D4.52
* RFID Reader 5E9010.29

Recommended task class is #8 with a 10ms cycle time.


<a name="Revision-History"></a>
## Revision History

#### Version 0.6
- Added message box before deleting user
- Changed constant to avoid conflict with other samples
- Fixed user selection after create and rename
- Updated mappView to 5.7.1
- Code optimizations

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
