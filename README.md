# SuperCAT
This is a README file to provide instructions on how to operate the SuperCat tool.  This tool will only support Windows 7 and Window 10

NOTE:  This is tool is to be used to assit Automatic Test System (ATS) PMO ISSM and Mission Defense Teams to Identify Assests, Detect abnormalities, and Protect Assets relating to Ground Support Equipment(GSE) 

NOTE:  If given a Pre-Coordinated Action (PCA) to conduct a mission from ATS PMO ISSM, this does not constitute authorization to make changes to the GSE.  

NOTE:  If anomolies are detected that would constitute an incident IAW with T.O. 33-1-38 report them accordingly to ATS PMO ISSM.



**********************************
*Preperation of the SuperCat Tool*
**********************************

After you have downloaded the SuperCat Tool you will need to populate the other tools onto the disc to ensure you have the latest versions.

For the Anti-Virus Definition Files to be updated get the latest DAT file for DOD Patch Repository under the ESS Collection. https://patches.csd.disa.mil/CollectionInfo.aspx?id=863&bc=394_1_15_asc

This file will be placed in the [folder] 

For the latest SCAP Compliance Checker (SCC) you can obtain that tool on DoD Cyber Exchange.  https://cyber.mil/stigs/scap/

This file will be placed in the [folder]

Once the scripts and files have been placed on the DVD, you can complete the burning process of the DVD to take to the System(s) under test.


*********************************
*****  Configuration   **********
*********************************

NOTE:  This can be accomplished before getting to System(s) under test if you have information already.

There are two ways to preconfigure the script to populate the location fields.

1.  You can run the setup-powershell script and type in the information as you are prompted (Easiest)

2. Locate the config.txt or config.json file and populate the fields from there.

BaseName is the base where you are located.
System is are the system names (ex. VIPER1, VIPER2, VIPER3)
Location is either the Unit, Building, ToolCrib be as descriptive as you need to find in the event you need to track down equipment again.



***********************************
*****    Run SuperCAT       *******
***********************************

NOTE:  Some items may need to be ran with admin credentials.  If this is the case then when bringing up powershell, right click and select Run as Administrator.

Once you have populated the config.json file or ran the setup-powershell script you can proceed to Run SuperCAT

Select the SuperCAT script to run.

The first menu to appear will allow you to select specific item to run or you can run all of them.

After you have selected your option it will begin the process.  There will be a prompt that tells you where it is in the process.  Please wait till you see the Done before attempting to eject the DVD.



************************************
***    Results and Info       ******
************************************

Once it is completed the DVD will contain CSV files with the necessary information for each system.








