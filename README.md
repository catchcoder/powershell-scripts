# Powershell scripts

## Create a Local Windows User for the RDSF Gateway connection

### Rename hostname to match service tag

```cmd
powershell -executionpolicy bypass .\renameComputer.ps1
```

## Create new user for RDSF connection

```cmd
powershell -executionpolicy bypass .\createrdsfsmbuser.ps1
```
