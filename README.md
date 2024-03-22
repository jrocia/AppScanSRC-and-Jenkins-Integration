# AppScanSRC-and-Jenkins-Integration

- install a Jenkins agent and Powershell 7 in AppScan Source Server
- install Powershell Jenkins Plugin in Jenkins Server
- in Manage Jenkins >> Tools >> Powershell Installations >> Path to Powershell, change from powershell.exe to pwsh.exe
- allow firewall rules between Jenkins Server and Jenkins Agent in AppScan Source Server. 
- generate an API key pair in AppScan Enterprise.

After that you will need to add a powershell step in a Jenkins Pipeline and from the integration I wrote add the content jenkins_pwsh_script and change the content of that 3 variables  ($aseApiKeyId, $aseApiKeySecret and $aseHostname).

![image](https://github.com/jrocia/AppScanSRC-and-Jenkins-Integration/assets/69405400/12ac06ac-1392-43c8-9fca-1884ea41869b)
