@echo off
CLS

ECHO ===============================================================
ECHO This script helps automate the creation of the config.txt file
ECHO used by the Cyber Assessment Tool (CAT). Whenever changes are
ECHO needed for the file, you can either edit the variables within
ECHO the file or you can use this script again to create it.
ECHO ===============================================================
pause

:BaseName
ECHO Type in the name of your base:
SET /P Base=

ECHO ===============================================================
ECHO You inputted: %Base% . Is this correct?
ECHO 1 = Yes
ECHO 2 = No
ECHO ===============================================================
SET /P BaseCheck=

ECHO.%BaseCheck% | findstr -v "1 2">nul &&(
    GOTO :BaseName
)
IF %BaseCheck%==2 (
    GOTO :BaseName
)

:SystemNames
CLS
ECHO ===============================================================
ECHO Type in the first common system you will be assessing:
ECHO (i.e. VIPER/CAPRE)
SET /P System1=

ECHO Type in the second common system you will be assessing:
SET /P System2=

ECHO Type in the third common system you will be assessing:
SET /P System3=

ECHO Type in the fourth common system you will be assessing:
SET /P System4=

ECHO Type in the fifth common system you will be assessing:
SET /P System5=

ECHO ===============================================================
ECHO You inputted:
ECHO %System1%
ECHO %System2%
ECHO %System3%
ECHO %System4%
ECHO %System5%
ECHO Is this correct?
ECHO 1 = Yes
ECHO 2 = No
ECHO ===============================================================
SET /P SystemCheck=

ECHO.%SystemCheck% | findstr -v "1 2">nul &&(
    GOTO :SystemNames
)
IF %SystemCheck%==2 (
    GOTO :SystemNames
)

:LocationNames
CLS
ECHO ===============================================================
ECHO Type in the first common location you will be assessing:
ECHO (i.e. Building 34)
SET /P Location1=

ECHO Type in the second common location you will be assessing:
SET /P Location2=

ECHO Type in the third common location you will be assessing:
SET /P Location3=

ECHO Type in the fourth common location you will be assessing:
SET /P Location4=

ECHO Type in the fifth common location you will be assessing:
SET /P Location5=

ECHO ===============================================================
ECHO You inputted:
ECHO %Location1%
ECHO %Location2%
ECHO %Location3%
ECHO %Location4%
ECHO %Location5%
ECHO Is this correct?
ECHO 1 = Yes
ECHO 2 = No
ECHO ===============================================================
SET /P LocationCheck=

ECHO.%LocationCheck% | findstr -v "1 2">nul &&(
    GOTO :LocationNames
)
IF %LocationCheck%==2 (
    GOTO :LocationNames
)

ECHO _BaseName=%Base% > "Tool/config.txt"
ECHO _System1=%System1% >> Tool/config.txt
ECHO _System2=%System2% >> Tool/config.txt
ECHO _System3=%System3% >> Tool/config.txt
ECHO _System4=%System4% >> Tool/config.txt
ECHO _System5=%System5% >> Tool/config.txt
ECHO _Location1=%Location1% >> Tool/config.txt
ECHO _Location2=%Location2% >> Tool/config.txt
ECHO _Location3=%Location3% >> Tool/config.txt
ECHO _Location4=%Location4% >> Tool/config.txt
ECHO _Location5=%Location5% >> Tool/config.txt

ECHO config.txt has been created!