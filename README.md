## Table of Contents
* [Introduction](#Introduction)
* [Requirements](#Requirements)
* [Revision History](#Revision-History)

<a name="Introduction"></a>
## Introduction
This is a sample project for a user management with mappView. It uses the B&R library ArUser to export and import user data as well as the mappView user widget. There is an extended sample with RFID reader support available as separate [**branch**](https://github.com/br-automation-com/mappView-User/tree/V2_RFID).

![](Logical/mappView/Resources/Media/screenshot.png)

The passwords for the users in this demo is the user name all lower case. Also see [**How to import the user management into an existing project.**](Logical/mappUser/HowToImport.pdf) Detailed information are available in the [**Wiki**](https://github.com/stephan1827/mappView-User/wiki). This sample can run in simualtion mode (http://127.0.0.1:81/).

<a name="Requirements"></a>
## Requirements
* Automation Studio 4.10
* mappView 5.17
* Automation Runtime D4.91

Recommended task class is #8 with a 10ms cycle time.

<a name="Revision-History"></a>
## Revision History

#### Version 2.0
- First release with new user controls
