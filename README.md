## Table of Contents
* [Introduction](#Introduction)
* [Requirements](#Requirements)
* [Revision History](#Revision-History)

<a name="Introduction"></a>
## Introduction
This is a sample project for a user management with mappView. It uses the B&R library ArUser to access and modify user rights. There are 4 versions in total available. Version 1 can be used with mappView version < 5.17 where no widgets are available for user managament. Starting with mapp version 5.17 there are additional widgets available for user managament and these are used in version 2. Both versions are also available with support for RFID reader.

| RFID | Version 1 (mapp < 5.17)| Version 2 (mapp > 5= 5.17)|
|---|---|---|
| No|![](Logical/mappView/Resources/Media/screenshot.png) | [![Link](https://github.com/br-automation-com/mappView-User/blob/V2_main/Logical/mappView/Resources/Media/screenshot.png)](https://github.com/br-automation-com/mappView-User/tree/V2_main) |
| Yes|[![Link](https://github.com/br-automation-com/mappView-User/blob/V1_RFID/Logical/mappView/Resources/Media/screenshot.png)](https://github.com/br-automation-com/mappView-User/tree/V1_RFID) | [![Link](https://github.com/br-automation-com/mappView-User/blob/V2_RFID/Logical/mappView/Resources/Media/screenshot.png)](https://github.com/br-automation-com/mappView-User/tree/V2_RFID) |



The passwords for the users in this demo is the user name all lower case. Also see [**How to import the user management into an existing project.**](Logical/mappUser/HowToImport.pdf) Detailed information are available in the [**Wiki**](https://github.com/stephan1827/mappView-User/wiki). This sample can run in simualtion mode (http://127.0.0.1:81/).

<a name="Requirements"></a>
## Requirements
* Automation Studio 4.5
* mappView 5.7.1
* Automation Runtime D4.52

Recommended task class is #8 with a 10ms cycle time.

<a name="Revision-History"></a>
## Revision History

#### Version 1.1
- Fixed export path not connected to ArUser.PAR.FilePath in mappView
