## Introduction
This is sample project for user managment with mappView. It uses the B&R library to access and modify user rights.

![I'm a relative reference to a repository file](https://github.com/stephan1827/mappView-User/blob/master/Logical/mappView/Resources/Media/screenshot.png)

The passwords for the users in this demo is the user name all lower case.

## Requirements
* Automation Studio 4.5
* mappView 5.6
* Automation Runtime A.5

## Description
The sample consists of two main components. The sample page to manage all important settings for users and the task that drives the ArUser library. The following functions are currently supported.

* Create and delete user
* Change password
* Import export user information
* Assign and remove roles from users

The task and mappView visualazation use an interface to communicate that can also be used to trigger functions external. The structure looks as follows:

ArUser
* CMD -> Used to trigger commands like create user, change password, ...
* PAR -> Parameters like user name, file path to export data, ...
* DAT -> User data and roles as well as some status information
* VIS -> Data specific for the visualization
* ERR -> Information about errors

## Limitations
* The sample is not yet multi client capable
* Roles can not be created or deleted. This is due to the fact that the permission for roles can not be changed on the fly.

## Revision History

#### Version 0.1
First public release
