# Copyright 2024 HCL America
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

write-host "======== Step: Requesting and Exporting compliance XML from ASE ========"
# Get the scanName and jobIdASE from scanName_var.txt and jobId_var.txt file
$scanName=(Get-Content .\scanName_var.txt);
# ASE Authetication
$sessionId=$(Invoke-WebRequest -Method "POST" -Headers @{"Accept"="application/json"} -ContentType 'application/json' -Body "{`"keyId`": `"$aseApiKeyId`",`"keySecret`": `"$aseApiKeySecret`"}" -Uri "https://$aseHostname`:9443/ase/api/keylogin/apikeylogin" -SkipCertificateCheck | Select-Object -Expand Content | ConvertFrom-Json | select -ExpandProperty sessionId);
# Get the aseAppId from ASE
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession;
$session.Cookies.Add((New-Object System.Net.Cookie("asc_session_id", "$sessionId", "/", "$aseHostname")));
$aseAppId=$(Invoke-WebRequest -WebSession $session -Headers @{"Asc_xsrf_token"="$sessionId"} -Uri "https://$aseHostname`:9443/ase/api/applications/search?searchTerm=$aseAppName" -SkipCertificateCheck | ConvertFrom-Json).id;
# Request report generation based on scanName and status New, Fixed, Reopened, InProgress, Open and Passed. Ignoring status Noise.

$reportId=$(Invoke-WebRequest -Method "POST" -WebSession $session -Headers @{"asc_xsrf_token"="$sessionId" ; "Accept"="application/json"} -ContentType "application/json" -Body "{`"regulationTemplate`":`"$complianceCheck`",`"layout`":{`"reportOptionLayoutCoverPage`":{`"companyLogo`":`"`",`"additionalLogo`":`"`",`"includeDate`":true,`"includeReportType`":true,`"reportTitle`":`"Application Report`",`"description`":`"This report includes important security information about your application.`"},`"reportOptionLayoutBody`":{`"header`":`"`",`"footer`":`"`"},`"includeTableOfContents`":true},`"reportFileType`":`"XML`",`"issueIdsAndQueries`":[`"scanname=$scanName,status=new,discoverymethod=sast,status=inprogress,status=open,severity=critical`",`"scanname=$scanName,status=new,discoverymethod=sast,status=inprogress,status=open,severity=high`",`"scanname=$scanName,status=new,discoverymethod=sast,status=inprogress,status=open,severity=medium`",`"scanname=$scanName,status=new,discoverymethod=sast,status=inprogress,status=open,severity=low`"]}" -Uri "https://$aseHostname`:9443/ase/api/issues/reports/industrystandard?appId=$aseAppId" -SkipCertificateCheck | Select-Object -Expand Content | Select-String -Pattern "Report id: (Report\d+)" | % {$_.Matches.Groups[1].Value});

write-host "$reportId"
# Check report status generation
$reportStatus=$((Invoke-WebRequest -WebSession $session -Headers @{"Asc_xsrf_token"="$sessionId"} -Uri "https://$aseHostname`:9443/ase/api/issues/reports/$reportId/status" -SkipCertificateCheck).content | ConvertFrom-Json).reportJobState
write-host "$reportStatus"
# Wait report generation finished
while ($reportStatusCode -ne 201){
  $reportStatusCode=$(Invoke-WebRequest -WebSession $session -Headers @{"Asc_xsrf_token"="$sessionId"} -Uri "https://$aseHostname`:9443/ase/api/issues/reports/$reportId/status" -SkipCertificateCheck).statusCode
  write-host "Report being generated";
  sleep 60;
}

sleep 60;
# Request download report file zipped
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession;
$session.Cookies.Add((New-Object System.Net.Cookie("asc_session_id", "$sessionId", "/", "$aseHostname")));
Invoke-WebRequest -WebSession $session -Headers @{"Asc_xsrf_token"="$sessionId"} -Uri "https://$aseHostname`:9443/ase/api/issues/reports/$reportId" -SkipCertificateCheck -OutFile scan_report_pdf.zip -PassThru | Out-Null;

Expand-Archive .\scan_report_pdf.zip -DestinationPath .\ -Force
sleep 10
$file=$(Get-Item -Path *Report.xml);
[XML]$xml = Get-Content $file;
write-host "There are"$xml.'xml-report'.'scan-summary'.'total-issues-in-scan'"issues on "$complianceCheck" compliance report."
write-host "The scan name $scanName was exported from Appscan Enterprise."

Invoke-WebRequest -WebSession $session -Headers @{"Asc_xsrf_token"="$sessionId"} -Uri "https://$aseHostname`:9443/ase/api/logout" -SkipCertificateCheck | Out-Null
