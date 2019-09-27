<?xml version="1.0" encoding="utf-8"?>
<?AutomationStudio Version=4.5.3.86 SP?>
<SwConfiguration CpuAddress="SL1" xmlns="http://br-automation.co.at/AS/SwConfiguration">
  <TaskClass Name="Cyclic#1" />
  <TaskClass Name="Cyclic#2" />
  <TaskClass Name="Cyclic#3" />
  <TaskClass Name="Cyclic#4" />
  <TaskClass Name="Cyclic#5" />
  <TaskClass Name="Cyclic#6" />
  <TaskClass Name="Cyclic#7" />
  <TaskClass Name="Cyclic#8">
    <Task Name="UserManage" Source="mappUser.UserManagement.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="RFIDdevice" Source="mappUser.RFIDdevice.prg" Memory="UserROM" Language="IEC" Debugging="true" />
  </TaskClass>
  <Libraries>
    <LibraryObject Name="runtime" Source="Libraries.runtime.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="standard" Source="Libraries.standard.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="dvframe" Source="Libraries.dvframe.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="sys_lib" Source="Libraries.sys_lib.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsUSB" Source="Libraries.AsUSB.lby" Memory="UserROM" Language="binary" Debugging="true" />
  </Libraries>
</SwConfiguration>