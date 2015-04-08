

# Declaring Variables
iso_url           = "\\\\10.60.18.181\\sqlserver\\SQLServer2012SP1-FullSlipstream-ENU-x64.iso"
iso_path          = "C:\\Temp\\SQLServer2012SP1-FullSlipstream-ENU-x64.iso"
sql_config_file_url   = "\\\\10.60.18.181\\sqlserver\\SQL_Configurationfile.ini"
sql_config_file_path  = "C:\\Temp\\SQL_Configurationfile.ini"
sql_svc_act       = "Administrator"
sql_svc_pass      = "Administrator123"
sql_sysadmins     = "Administrator"
sql_agent_svc_act = "NT AUTHORITY\\Network Service"
# sql_product_key		=	"" add

# Creating a Temporary Directory to work from.
directory "C:\\Temp\\" do
	rights :full_control, "#{sql_svc_act}"
	inherits true
	action :create
end

# Download the SQL Server 2012 Standard ISO from a Web Share.

powershell_script 'Download SQL Server 2012 STD ISO' do
	code <<-EOH
		$Client = New-Object System.Net.WebClient
		$Client.DownloadFile("#{iso_url}", "#{iso_path}")
		EOH
	guard_interpreter :powershell_script
	not_if { File.exists?(iso_path)}
end

# Download the SQL Server 2012 Custom Configuration File from a Web Share.
powershell_script 'Download SQL Server 2012 Custom Configuration File' do
	code <<-EOH
		$Client = New-Object System.Net.WebClient
		$Client.DownloadFile("#{sql_config_file_url}", "#{sql_config_file_path}")
		EOH
	guard_interpreter :powershell_script
	not_if { File.exists?(sql_config_file_path)}
end

# Mounting the SQL Server 2012 SP1 Standard ISO.
powershell_script 'Mount SQL Server 2012 STD ISO' do
	code  <<-EOH
		Mount-DiskImage -ImagePath "#{iso_url}"
        if ($? -eq $True)
		{
			echo "SQL Server 2012 STD ISO was mounted Successfully." > C:\\temp\\SQL_Server_2012_STD_ISO_Mounted_Successfully.txt
			exit 0;
		}

		if ($? -eq $False)
        {
			echo "The SQL Server 2012 STD ISO Failed was unable to be mounted." > C:\\temp\\SQL_Server_2012_STD_ISO_Mount_Failed.txt
			exit 2;
        }
		EOH
	guard_interpreter :powershell_script
	not_if '($SQL_Server_ISO_Drive_Letter = (gwmi -Class Win32_LogicalDisk | Where-Object {$_.VolumeName -eq "SQLServer"}).VolumeName -eq "SQLServer")'
end

# Installing SQL Server 2012 Standard.
powershell_script 'Install SQL Server 2012 STD' do
	code <<-EOH
		$SQL_Server_ISO_Drive_Letter = (gwmi -Class Win32_LogicalDisk | Where-Object {$_.VolumeName -eq "SQLServer"}).DeviceID
		cd $SQL_Server_ISO_Drive_Letter\\
		$Install_SQL = ./Setup.exe /ConfigurationFile="#{sql_config_file_path}"
		$Install_SQL > C:\\Temp\\SQL_Server_2012_STD_Install_Results.txt
		$Install_SQL > C:\\temp\\SQL_Server_2012_STD_Install_Results.txt
		EOH
	guard_interpreter :powershell_script
	not_if '((gwmi -class win32_service | Where-Object {$_.Name -eq "MSSQLSERVER"}).Name -eq "MSSQLSERVER")'
end

# Dismounting the SQL Server 2012 STD ISO.
powershell_script 'Delete SQL Server 2012 STD ISO' do
	code <<-EOH
		Dismount-DiskImage -ImagePath "#{iso_path}"
		EOH
	guard_interpreter :powershell_script
	only_if { File.exists?(iso_path)}
end


# Removing the SQL Server 2012 STD ISO from the Temp Directory.
powershell_script 'Delete SQL Server 2012 STD ISO' do
	code <<-EOH
		[System.IO.File]::Delete("#{iso_path}")
		EOH
	guard_interpreter :powershell_script
	only_if { File.exists?(iso_path)}
end

# Removing the SQL Server 2012 Custom Configuration File from the Temp Directory.
powershell_script 'Delete SQL Server 2012 Custom Configuration File' do
	code <<-EOH
		[System.IO.File]::Delete("#{sql_config_file_path}")
		EOH
	guard_interpreter :powershell_script
	only_if { File.exists?(sql_config_file_path)}
end
