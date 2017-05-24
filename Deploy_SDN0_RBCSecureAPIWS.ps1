    Import-Module "WebAdministration"
    Import-Module bitstransfer
    #=====================================================================================
    # Deploy web service binaries to application folder
    # $protocol - HTTP / HTTPS
    # $service  - 
    # $networkCred - Adminstrator network credential for copying application binaries for deployment
    # $server - The server where the application binary needs to be deployed
    #=====================================================================================
    
	#$WebVirtualDirectoryPath = $PhysicalDirectoryPath +"\" + $TargetProjectName
	#write-host $PhysicalDirectoryPath -foreground "DarkGray" -backgroundcolor "White"
	function DeployService([string]$protocol,[string]$service,$networkCred,[string]$server,$credential)
    {
		$sourceFolder = ".\" + $SourceProjectName
        $destinationFolder = "\\" + $server +"\F$\tierWebservices"
		$WebVirtualDirectoryPath1 = $PhysicalDirectoryPath +"\" + $TargetProjectName
		$WebVirtualDirectoryPath2 = $PhysicalDirectoryPath +"\" + $TargetProjectName

		Write-Host "Source Folder 		= " $sourceFolder
        Write-Host "Destination Folder  = " $WebVirtualDirectoryPath 
		Write-Host "testing = " $WebVirtualDirectoryPath $PhysicalDirectoryPath $TargetProjectName	
        $user = $networkCred.Domain +"\" + $networkCred.UserName
            
            try
            {       
                #Write-Host "==> Mapping network folder $destinationFolder" -foreground "Green"
                #net use $destinationFolder $networkCred.Password /USER:$user
            
                Write-Host "==> Copying files to server" $server -foreground "Green"
				
				if($ReqWebSite -eq "Default Web Site")
				{
                Robocopy.exe "$sourceFolder" "$WebVirtualDirectoryPath1" /E /MT:10
				}
				else
				{
				Robocopy.exe "$sourceFolder" "$WebVirtualDirectoryPath2" /E /MT:10
				}
		
		
				write-host "error code is $lastexitcode "

                #Copy-Item $sourceFolder -Destination (New-Item "$WebVirtualDirectoryPath" -Type container -Force) -Recurse -Force -verbose
				if(($lastexitcode -ge 0) -and ($lastexitcode -le 15))               
                {
                Write-Host "Copy-Success"
                }                
                else 
                {
                write-host "Copy-Fail"
				exit 999
                }				
                #Write-Host "==> Removing mapped network folder $destinationFolder" -foreground "Green"
                #net use $destinationFolder /delete
            }
            catch
            {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Host  "==> Error, exiting ... : $_.Exception.Message" -foreground "Red"
                Write-Host 
                exit 1
            }
        
				#write-host  "==> Encrypting Connection Strings" -foreground "Green"
				#
				#Invoke-Command -credential $credential -ComputerName $server -ArgumentList $destinationFolder -ScriptBlock {
				#param($destFolder)
				#
				#C:\Windows\Microsoft.NET\Framework64\v2.0.50727\aspnet_regiis.exe -pef "connectionStrings" $destFolder
				#}
                #if(-not $?)               
                #{
                #Write-Host "Encryption-Configuration-Fail"
                #}                
                #
                #
                #else 
                #{
                write-host "Encryption-Configuration-Success"
                #}
    }
		
    #=====================================================================================
    # Deploy web service "Settings" file
    # $networkCred - Adminstrator network credential for copying application binaries for deployment
    #=====================================================================================
    function CreateAppPoolAndWebSite([string]$protocolName,[string]$ServiceName,$networkCred,[string]$server,$credential)
    {
     	  #ConfigureAppPool $protocol,$service,$networkCred,$server,$credential
		  #Enter-PSSession -ComputerName $server -Credential $credential
		  pwd
		   
		  Write-Host "==> Application Pool Creation Started" $server -foreground "DarkGreen"
		  Write-Host "==> Importing Module" $server -foreground "DarkGreen"
		
		  Import-Module ServerManager

		  Add-WindowsFeature Web-Scripting-Tools
		  Import-Module WebAdministration  
		  $iisAppPoolName = $ServiceAppPool
		  $iisAppPoolName = $iisAppPoolName -replace "Service", ""
		  $OriginalAppPoolName = $iisAppPoolName
		  $iisAppPoolDotNetVersion = "v4.0"
		  $iisAppPoolName = "IIS:\AppPools\" + $iisAppPoolName
		  
		  Write-Host $ReqWebSite -foreground "DarkGreen"
		  $ReqWebSiteName = "IIS:\Sites\" + $ReqWebSite
		  $bindings = "@"+"{"+"protocol"+"="+"http"+";"+"bindingInformation"+"="+":"+$port+":"+"}"
		  
		  Write-Host $ReqWebSiteName -foreground "DarkGreen"
		  Write-Host "==> OriginalAppPoolName =" $OriginalAppPoolName -foreground "DarkGreen"
		  Write-Host "==> iisAppPoolDotNetVersion =" $iisAppPoolDotNetVersion -foreground "DarkGreen"
		  Write-Host "==> iisAppPoolName =" $iisAppPoolName -foreground "DarkGreen"
		  Write-Host "==> ServiceName =" $ServiceName -foreground "DarkGreen"
		  Write-Host $bindings = "@"+"{"+"protocol"+"="+"http"+";"+"bindingInformation"+"="+":"+$port+":"+"}"
		  
		  #create the website
		  if (!(Test-Path $ReqWebSiteName -pathType container))
			{
			Write-Host Create Required WebSite
			#Write-Host ==> "IIS:\Sites\"$ReqWebSite -physicalPath "$PhysicalDirectoryPath" -bindings @{protocol="http";bindingInformation=":$port:"} ==>
			New-Item "IIS:\Sites\$ReqWebSite" -physicalPath "$PhysicalDirectoryPath\$ReqWebSite" -bindings $bindings
			#New-Item "IIS:\Sites\DevOpsDemoSite" -physicalPath "F:\tierWebservices\DevOpsDemoSite" -bindings @{protocol="http";bindingInformation=":$port:"}
			}
			
		  if (!(Test-Path $iisAppPoolName -pathType container))
			{
			  #create the app pool
			  
			  Write-host "==>  Enter service id and password for $server" -foreground "Green"
			  
			  $SecurePassword=Convertto-SecureString -String $networkCred.Password -AsPlainText -force 
			  $SvcIdcredential=New-object System.Management.Automation.PSCredential $networkCred.UserName,$SecurePassword
			  #$SvcIdcredential = Get-Credential -Credential $null
			  $SvcIdnetworkCred = $SvcIdcredential.GetNetworkCredential()
			  $userName = $networkCred.Domain + "\" + $SvcIdnetworkCred.UserName
			  $password = $SvcIdnetworkCred.Password
			  
			  write-host "UserName with Domain = " $userName
			  
			  $appPool = New-Item $iisAppPoolName   
			  Write-Host "==> App Pool Created" $server -foreground "DarkGreen"
			  Write-Host "==> Configuring App Pool" $server -foreground "DarkGreen"
			  $appPool = Get-Item $iisAppPoolName  
			  $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
			  #$appPool | Set-ItemProperty -Name "managedPipelineMode" -Value $ApppoolPipelineMode
			  $appPool | Set-ItemProperty -Name "processModel.idleTimeout" -value ( [TimeSpan]::FromMinutes(0))
			  $appPool | Set-ItemProperty -Name "recycling.periodicRestart.time" -value ( [TimeSpan]::FromMinutes(0)) 
			  $appPool | Set-ItemProperty -Name "recycling.logEventOnRecycle" -value  255
			  $appPool | Set-ItemProperty -Name "processModel.identityType" -value 3
			  $appPool | Set-ItemProperty -Name "processModel.userName" -value  $userName
			  $appPool | Set-ItemProperty -Name processmodel.password -value  $password
			  Write-Host "==> $appPool =" $appPool -foreground "DarkGreen"
			  Write-Host "==> App Pool Configured"  -foreground "DarkGreen"
			}
			
		  $websitename = $ServiceName
		  
		  write-host "Protocol =" $protocolName
		  
		  if($protocolName -eq "http")
		  {	  
				  Write-Host !!!!!!!!!!!!!!!!!!!!!!!!!$ReqWebSite -foreground "DarkGreen"
				  
				  $httpwebsitpath = "IIS:\Sites\" + $ReqWebSite + "\" + $websitename
				  $httpCount = ((Get-WebApplication -Site  "$ReqWebSite" -Name $websitename  )  |  Measure-Object).Count
				  if($httpCount -eq 1)
				  {
				   Write-Host "==> $websitename App already exist" -foreground "DarkGreen"
				  }
				  else
				  {
				   
                   Write-Host "==> Start the creation of new web application $websitename <=="
				   
				   Write-Host "==> Create Web Application $websitename -PhysicalPath $PhysicalDirectoryPath\$TargetProjectName $WebVirtualDirectoryPath <=="
				   
				   if($ReqWebSite -eq "Default Web Site")
				   {
                   #New-WebApplication -Name "$websitename" -Applicationpool $OriginalAppPoolName -physicalPath $WebVirtualDirectoryPath -Site '$ReqWebSite'
				   New-WebApplication -Name "$websitename" -physicalPath "$PhysicalDirectoryPath\$TargetProjectName" -Site $ReqWebSite
				   #ConvertTo-WebApplication -PSPath "IIS:\Sites\$ReqWebSite\$TargetProjectName"
				   
				   }
				   else
				   {
				   Write-Host New-WebApplication -Name "$websitename" -physicalPath "$PhysicalDirectoryPath\$TargetProjectName" -Site $ReqWebSite
				   New-WebApplication -Name "$websitename" -physicalPath "$PhysicalDirectoryPath\$TargetProjectName" -Site $ReqWebSite
				   }
				   Write-Host "==> Set the Apppool & Physical Path Credentials <=="
				   #Set-ItemProperty $httpwebsitpath -name applicationPool -value $OriginalAppPoolName
				   #Set-ItemProperty $httpwebsitpath -Name virtualDirectoryDefaults.userName -value  $userName
				   #Set-ItemProperty $httpwebsitpath -Name virtualDirectoryDefaults.password -value  $password
				   }
				   
				   Set-ItemProperty "$httpwebsitpath" -name applicationPool -value $OriginalAppPoolName
				    
				if($ReqWebSite -eq "Default Web Site")
				   {
				   
					Set-ItemProperty "$httpwebsitpath" -Name physicalPath -Value "$PhysicalDirectoryPath\$TargetProjectName"
				   }
				   else
				   {
				   
					Set-ItemProperty "$httpwebsitpath" -Name physicalPath -Value "$PhysicalDirectoryPath\$TargetProjectName"
				   }
				   
				#Set-ItemProperty "$httpwebsitpath" -Name physicalPath -Value "$PhysicalDirectoryPath\$TargetProjectName"
				Write-Host "==> Starting Apppool $ServiceAppPool <=="
				Start-WebAppPool -Name "$ServiceAppPool"
		  }
		  
		  
		  if(-not $?)               
          {
                Write-Host "Apppool-Configuration-Fail"
          }                


          else 
          {
                write-host "Apppool-Configuration-Success"
          }
		  
		  Write-Host "==>  App Pool Created" $server -foreground "DarkGreen"  
		  Write-Host "==> Success "  -foreground "DarkGreen"
    }
       	
    #=====================================================================================
    #                        Main Execution Entry Point
    #=====================================================================================
    Write-host "`t`t`t`t"
    Write-host "Started:: VFC0 WebServicesInstallation" -foreground Black -background White
    Write-host
    Write-host Loading deployment service configuration details - "DeployWebServices_UCD.xml". 
	
	$root=split-path -parent $MyInvocation.MyCommand.Definition
	write-host "Root Path = " $root -foreground Black -background White
	$xml = [xml](get-content $root\Deploy_SDN0_RBCSecureAPIWS.xml)
	 
	 #=====================================================================================
	 # Step 1. Get Server details 
	 #===================================================================================== 
	  $server = $env:computername
	  Write-host $server
	 #===================================================================================== 
	 
	 #=====================================================================================
	 # Step 2. User network credential details
	 #===================================================================================== 
	 
	  $tmpDomain=$xml.RBCSecureAPIWS.AppPoolIdentityCredentials.Domain
	  $Domain=$tmpDomain
	  $Username=$xml.RBCSecureAPIWS.AppPoolIdentityCredentials.Username
	  $Password=$xml.RBCSecureAPIWS.AppPoolIdentityCredentials.Password
	  
	  $iisreset = $xml.RBCSecureAPIWS.IISRESET
	  	  
	  Write-Host $tmpDomain
	  Write-Host $Domain
	  Write-Host $Username
	  Write-Host $Password
	  
	  $MyUsernameDomain=""
	  Write-Host $Domain
	   IF([string]::IsNullOrEmpty($Domain)){    
		$MyUsernameDomain=$Username  
		Write-Host "No Domain detail provided..."              
	   } else {          
		$MyUsernameDomain=$Domain + "\" + $Username 
		Write-Host "Concatenation with Domain\Username ...."
	   }
	  Write-Host $MyUsernameDomain
	 
	  $SecurePassword=Convertto-SecureString -String $Password -AsPlainText -force 
	  $Credential=New-object System.Management.Automation.PSCredential $MyUsernameDomain,$SecurePassword
	  $networkCred = $Credential.GetNetworkCredential()
	  
	  Write-Host $networkCred.Domain
	  Write-Host $networkCred.Username
	  Write-Host $networkCred.Password
	 #===================================================================================== 
	 
	 #=====================================================================================
	 # Step 3. SSL Options [Default - "SSL and Non SSL Deployment"] 
	 #===================================================================================== 
	  write-host "*********** SSL Options ************"
	  write-host `t "SSL and Non SSL Deployment"`t[1]
	  write-host
	  
	  $SSLEnable = "3"  
	  
	  if ($SSLEnable -notmatch "3")
	  {
	   write-host "Something wrong with SSL and Non SSL Deployment Options ************"
	   exit 1   
	  }
	  
	  $availableProtocols = "HTTP"
	  Switch($SSLEnable) 
	  {
	   1 {
		$protocolList = $availableProtocols | Where-Object { $_ -eq "HTTPS" }    
	   }
	   2 {
		$protocolList = $availableProtocols | Where-Object { $_ -eq "HTTP" }
	   }
	   3 {
		$protocolList = $availableProtocols
	   }
	  }
	 #===================================================================================== 
	 
	 #=====================================================================================
	 # Step 4. Load Services details at runtime : 1. New - Creat AppPool then Deploy service; 
	 #                                            2. Existing - Deploy Service only 
	 #===================================================================================== 
	  write-host
	  
		$services = $xml.RBCSecureAPIWS.ServiceToInstall

		[int]$servicesCount = $services.childnodes.count
		write-host "count = " $servicesCount
	  Try
	  {
	  
		$service = $null
		
		foreach ($serviceAttribute in $services.ChildNodes) 
		{
			$service = $serviceAttribute.Name
			$ServiceAppPool = $serviceAttribute.Apppool
			$ApppoolPipelineMode = $serviceAttribute.PipelineMode
			$ReqWebSite = $serviceAttribute.ReqWebSite
			$port = $serviceAttribute.port
			$DeploymentFlag = $serviceAttribute.Deploy
			
			$SourceProjectName = $serviceAttribute.SourceProjectName
			$TargetProjectName = $serviceAttribute.TargetProjectName
			$PhysicalDirectoryPath = $serviceAttribute.PhysicalDirectoryPath
			
			write-host $PhysicalDirectoryPath -foreground "DarkGray" -backgroundcolor "White"
			write-host " ==> Service Name = "$service " *********** AppPoolStatus = "$AppPoolStatus   "********* Deployment Flag = " $DeploymentFlag  -freground "DarkGray" -backgroundcolor "White"
			
			
			
			if ($DeploymentFlag.ToLower() -eq "yes")
			{
			
			if(Test-Path IIS:\AppPools\$ServiceAppPool)
				{
					write-host "Apppool $ServiceAppPool is already exists" -foreground "DarkGray" -backgroundcolor "White"
					#Check the Apppool Status
					If((get-WebAppPoolState -name $ServiceAppPool).Value -eq "Stopped")
					{
						write-host "Apppool $ServiceAppPool is already Stopped" -foreground "DarkGray" -backgroundcolor "White"
					}
					else
					{
						write-host "Stopping the AppPool $ServiceAppPool" -foreground "DarkGray" -backgroundcolor "White"
						Stop-WebAppPool -Name "$ServiceAppPool"
						
						#$currentRetry = 0;
						#$success = $false;
						#do{
						#	$status = (get-WebAppPoolState -name $ServiceAppPool).Value
						#	write-host "$status" -foreground "DarkGray" -backgroundcolor "White"
						#	if ($status -eq "Stopped"){
						#		 
						#			$success = $true;
						#			write-host "$success" -foreground "DarkGray" -backgroundcolor "White"
						#		}
						#		Start-Sleep -s 10
						#		$currentRetry = $currentRetry + 1;
						#		write-host "Waiting to stop Apppool $ServiceAppPool, current retry is $currentRetry" -foreground "DarkGray" -backgroundcolor "White"
						#	}
						#while (!$success -and $currentRetry -le 30)
						##while (!$success)
						
						do
						{
							Write-Host (Get-WebAppPoolState -name $ServiceAppPool).Value
							Start-Sleep -Seconds 5
						}
						until ( (Get-WebAppPoolState -name $ServiceAppPool).Value -eq "Stopped" )
						If((get-WebAppPoolState -name $ServiceAppPool).Value -eq "Stopped")
						{
							write-host "Apppool $ServiceAppPool is Stopped" -foreground "DarkGray" -backgroundcolor "White"
						}
					}
					
				}
				else
				{
					write-host "Apppol $ServiceAppPool is not installed" -foreground "DarkGray" -backgroundcolor "White"
				}
			
			ForEach($protocol in $protocolList) 
			
					{
					
					
						DeployService $protocol $service $networkCred $server $credential 

						#if ($AppPoolStatus.ToLower() -eq "new")
						#{
							CreateAppPoolAndWebSite $protocol $service $networkCred $server $credential 
						#}							
					}
					
					if ($iisreset.ToLower() -eq "yes")
						{
							Invoke-Command -credential $credential -ComputerName $server -ScriptBlock {
									iisreset
							}
						}
			}
			write-host "Done installing on server $server" -foreground "DarkGray" -backgroundcolor "White"
			write-host
		}
	  }	
	  catch
	  {
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
		Write-Host  "==> Error, exiting ... : $_.Exception.Message" -foreground "Red"
		Write-Host 
		exit 1
	  }
	  Finally
	  {
		$ServersCompleted | ForEach {
							write-host "   $_ .. Done"
						}
		write-host
	  }
