# SuperCAT
This is a README file to provide instructions on how to operate the SuperCat tool.
This tool currently supports Windows 7 and Window 10


[![Pester](https://github.com/lordneeko/SuperCAT/actions/workflows/PesterTest.yml/badge.svg)](https://github.com/lordneeko/SuperCAT/actions/workflows/PesterTest.yml)
[![PSScriptAnalyzer](https://github.com/SuperCATDevelopers/SuperCAT/actions/workflows/PSScriptAnalyzer.yml/badge.svg?branch=main)](https://github.com/SuperCATDevelopers/SuperCAT/actions/workflows/PSScriptAnalyzer.yml)

**********************************
*SuperCat Concept of Operation*
**********************************
The primary function of the SuperCAT tool is to scan offline systems to gather
metadata and audit logs on those systems.  In particular, SuperCAT has been
designed to execute solely from a CD/DVD disc so that the configuration baseline
of the scanned system is not affected. SuperCAT's command execute from the disc
and write back to the disc.  Although Windows will load the PowerShell scripts
(and executables) into memory while running, no files are expected to remain
resident on the system after the test completes.  Once the scan is complete, the
user should use the built in CD/DVD burner utilizies to write the added files
back to the disc and "finalize" the disc using a manner in accordance with
prescribed policies.

**********************************
*Preparation of the SuperCat Tool*
**********************************

After you have downloaded the SuperCat Tool you will need to populate the other
tools onto the disc to ensure you have the latest versions.

For the Anti-Virus Definition Files to be updated get the latest DAT file for
DOD Patch Repository under the ESS Collection.
https://patches.csd.disa.mil/CollectionInfo.aspx?id=863&bc=394_1_15_asc
* DAT files are places in the .\Tool\Scripts\McAfeeAV_v2\DAT\ folder

SuperCAT normally relies on the McAfee VirusScan Command Line scanner (VSCL) to operate.
* DOD Users may obtain a copy of this at the [DOD Patch Repository](https://patches.csd.disa.mil) by searching for VSCL Windows.
* Non-DOD, for information on obtaining this from McAfee is located here: https://kc.mcafee.com/corporate/index?page=content&id=KB5114.
* 64-bit VSCL is placed in the .\Tool\Scripts\McAfeeAV_v2\w64 folder.
* 32-bit VSCL is placed in the .\Tool\Scripts\McAfeeAV_v2\w32 folder.
** Note: Currently, a 32-bit scanner has not been identified. DOD Patch Repo no
longer provides the 32 bit scanner.

For the latest SCAP Compliance Checker (SCC) you can obtain that
tool on DoD Cyber Exchange.  https://cyber.mil/stigs/scap/
* Place SCC files within the .\Tool\Scripts\SCAP directory.

For users which want to scan older systems, you must download and install SCAP
content for those systems to the SCC by following the User's Manual provided
within the SCC download.  For those scanning current systems (e.g. Windows 10),
SCC already contains the latest SCAP content.

Once the scripts and files have been placed on the CD/DVD, you can complete the
burning process of the CD/DVD to take to the System(s) under test. Be sure when
adding the tool to the disc, that you do not "finalize" the session to ensure
that when the tests are executed Windows can add the files back to the disc.


****************************************
*****  Configuration :: Optional   *****
****************************************

NOTE:  This can be accomplished before getting to System(s) under test if you
have information already.

NOTE:  This step is NOT recommended when using one system per disk as it copies
drive IDs as well.

Configuration information from a pre-existing SuperCAT installation may be
duplicated to a new disk bycopying .\Tool\config.xml file to.\Tool\config.xml
on the new disk.



***********************************************
*****      Run SuperCAT :: Interactive    *****
***********************************************

NOTE:  Some items may need to be ran with admin credentials.  If this is the case
then when bringing up powershell, right click and select Run as Administrator.

Once you have optionally copied config.xml, you can proceed to run SuperCAT

Right click the SuperCAT script and run as Administrator to run.

The first menu to appear will allow you to select specific item to run or you
can run all of them.

After you have selected your option it will begin the process.  There will be a
prompt that tells you where it is in the process. It is recommended that the user
"finalize" the disc before attempting to eject the DVD.

**Note: Depending on the security requirements of the System Owner, you may
need to use a separate disc each time you scan a system to avoid the chance of
intermingling data or transferring malware.**

**********************************************************
*****      Run SuperCAT :: CommandLine :: Optional   *****
**********************************************************

NOTE: SuperCAT must have been run in interactive mode previously on this device.

In order to run SuperCAT in CommandLine mode:
 1. Open up Windows Explore
 2. Select the SuperCAT disk
 3. Navigate to the Tools folder
 4. Click File
 5. Hover over the arrow by Open Powershell
 6. Select Open Powershell as Administrator.

.\SuperCAT.ps1 [-Help] [-List]
.\SuperCAT.ps1 [-Help] [-List] -Time TIME -Options OPTION[,Option...]

Parameters:
  -Help     Display this message.
  -List     Display only execution options
  -Options  Select one or more execution options. Please
            only input numbers and commas (i.e. 1,25,6).
            Requires -Time
  -Time     Set the system time in UTC. To skip, write
            "trust". Please enter the date in the format
            YYYY-MM-DDTHH:MM:SS (i.e. 2020-01-31T13:39:00)

Execution Options:
	0 = Update Antivirus (Requires Pre-Approved Actions)
	1 = Collect Computer Information
	2 = Initialize Antivirus Scan
	3 = Collect Antivirus Logs
	4 = Initialize SCAP
	5 = Collect Windows Event Logs
	6 = All Tasks (No Antivirus Updating, Auto exits)
	7 = Exit Program

************************************
***    Results and Info       ******
************************************

Once it is completed the CD/DVD will contain files with the extracted information
for each system within the Outputs folder.


************************************
***   Event ID Analysis          ***
************************************

SuperCAT gets an extract of Windows Event logs and stores them as raw EVTX files.
These can be injested directly with logstash. In addition, within the
Tools\Scripts\QuicklookTools folder is a tool (FilterEventLogs.ps1) for parsing
the evtx files and converting them to csv files.  The user can supply a txt file
of EventIDs for which to filter the CSV and it will output an analysis file with
the EventIDs the user is interested in. The user can get a good list of EventIDs
to use for Incident Response, Threat Hunting, Forensics, etc at the following location:
https://github.com/TonyPhipps/SIEM/blob/ec2dde7ba7997bfb9a88acf27fbb1fde7e32d20c/Notable-Event-IDs.md
