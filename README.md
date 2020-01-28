## Table of Contents
* [Introduction](#Introduction)
* [Requirements](#Requirements)
* [Revision History](#Revision-History)

<a name="Introduction"></a>
## Introduction
This is a sample project for a user management with mappView. It uses the B&R library ArUser to access and modify user rights. There is an extended sample with RFID reader support available as separate [**branch**](https://github.com/stephan1827/mappView-User/tree/RFID).

![](Logical/mappView/Resources/Media/screenshot.png)

The passwords for the users in this demo is the user name all lower case. Also see [**How to import the user management into an existing project.**](Logical/mappUser/HowToImport.pdf) Download the latest release from [**here.**](https://github.com/stephan1827/mappView-User/releases/latest) Detailed information are available in the [**Wiki**](https://github.com/stephan1827/mappView-User/wiki).

<a name="Requirements"></a>
## Requirements
* Automation Studio 4.5
* mappView 5.7.1
* Automation Runtime D4.52

Recommended task class is #8 with a 10ms cycle time.

<a name="Revision-History"></a>
## Revision History

#### Version 0.7
- Clear password field when user is created, password is changed, login or logout
- Removed user anonymous from user list
- Increased length of status message
