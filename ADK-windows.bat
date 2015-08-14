REM PE TOOLS(DISM, IMAGEX) FROM ADK: Windows Assessment and Deployment Kit
REM DISM
REM 1
REM ��ȡwim��Ϣ
    DISM /get-wiminfo /wimfile:install.wim
	
REM 2
REM ���ؾ���
    DISM /mount-wim /wimfile:install.wim /index:1 /mountdir:d:\test
	
REM 3
REM ��װ����
	DISM /image:d:\test /add-driver /driver:k:\oem1.inf
	
REM 4
REM �鿴����
	DISM /image:d:\test /get-drivers
	
REM 5
REM ж�ؾ��񲢱���
	DISM /unmount-wim /mountdir:d:\test /commit

REM 6
REM д���Ʒ���к�
	call DISM /Image:w: /Set-ProductKey:XXXX-XXXX-XXXX-XXXX-XXXX

REM 7
REM ɾ������
	DISM /image:d:\test /Remove-Driver /driver:k:\oem1.inf_path

	
REM ***************************************************
REM IMAGEX
REM 1
REM �ϲ�wim
	imagex /export install.swm * /ref d:\*.swm new.wim
	
REM 2
REM ���wim
	imagex /split install.wim xx.swm 4096
	

REM ***********************************	
REM CREATE PE
REM DOWNLOAD PE TOOLS IN WINDOWS ADK
REM COPY
	ADK\Windows Preinstallation Environment>copype.cmd amd64 d:\amd64
REM INSTALL TO USB OR ISO
	ADK\Windows Preinstallation Environment>MakeWinPEMedia.cmd /ufd /f d:\amd64 k:
	ADK\Windows Preinstallation Environment>MakeWinPEMedia.cmd /iso /f d:\amd64 d:\amd64pe.iso
REM INSTALL PE & BOOT FROM DISK
REM 1
REM COPY PE
	COPYPE amd64 d:\winpe

REM 2
REM PREPARE MEDIA
	diskpart
	list disk
	select <disk number>
	clean
	rem === Create the Windows PE partition.===
	create partition primary size=2000
	format quick fs=fat32 label="Windows PE"
	assign letter=P
	active
	rem === Create a data partition.===
	create partition primary
	format fs=ntfs quick label="Other files"
	assign letter=0
	list vol
	exit
	
REM 3
REM INSTALL TO MEDIA
	DISM /Apply-Image /ImageFile:"d:\amd64\media\sources\boot.wim" /Index:1 /ApplyDir:P:\
REM APPLY IMAGES
	DISM /Apply-Image /ImageFile:"d:\install.swm" /SWMFile:install*.swm /Index:1 /ApplyDir:w:\ /Compact /ScratchDir:"W:\recycler\scratch"
	
REM ��ԭ�������
	DISM /Image:"imagePath" /cleanup-image /RevertPendingActions
REM ��ԭ����
	DISM /Image:"imagePath" /Cleanup-image /RestoreHealth
REM 4
REM SET BOOT FILE
	BCDboot P:\Windows /s P: /f ALL
	
	
REM ***********************************
REM ��������ű�
REM �޸� Startnet.cmd �ű���Windows\System32\Startnet.cmd)
REM Ҫ��ü��弴�û�����֧�֣�Ӧ����wpeinit
REM Wpeinit ����־��Ϣ����� windows\system32\wpeinit.log
REM Wpeinit cmd
	Wpeinit -unattend:"unattend-pe.xml"
	
REM ����Զ���Ӧ��
REM ���� Winpeshl.ini �ļ�������Ӧ�ó���
	[LaunchApp]
	AppPath = %SYSTEMDRIVE%\Fabrikam\shell.exe
	[LaunchApps]
	%SYSTEMDRIVE%\Fabrikam\app1.exe
	%SYSTEMDRIVE%\Fabrikam\app1.exe, /s "c:\program files\app3"
REM ˳��ִ�У�֧������Ӧ�ã�����֧�ֳ����ű�����

REM �����ʱ�洢���ݴ�ռ�,32/64/128/256/512��
	DISM /Set-ScratchSpace:128 /Image:"mountpoint"
	
REM �滻����ͼ��
REM �滻ͼƬ mount\windows\system32\winpe.jpg

REM ��ӿ�ѡ���
REM ��ӿ�ѡ������������.cab�ļ�����ͬʱ��ӿ�ѡ���������������԰���
	DISM /Add-Package /Image:"mountpoint" /PackagePath:"winpe-hta.cab"	
REM ��֤��ѡ����Ƿ�Ϊӳ���һ����(�鿴���������б�)
	DISM /Get-Packages /Image:"mount"
	
REM ��Ӷ�����
REM �鿴��ǰ����
	DISM /Image:"mountpoint" /Get-Intl
REM ɾ�����԰�
	DISM /Image:"mountpoint" /Remove-Package /PackagePath:"package.cab"
	Dism /Image:"mountpoint" /Remove-Package /PackageName:Microsoft.Windows.Calc.Demo~6595b6144ccf1df~x86~en~1.0.0.0
REM �г���ѡ���
	DISM /Get-Packages /Image:"mountpoint"
REM �����Ӧ���԰�����������Windows PE ���԰�
	DISM /Add-Package /Image:"mountpoint" /PackagePath:"lp.cab"  (����Windows PE ���԰�)
	DISM /Add-Package /Image:"mountpoint" /PackagePath:"winpe-hta_en-us.cab"
REM ��֤���԰�����������Windows PE ӳ��
	DISM /Get-Packages /Image:"mountpoint"
REM ���������ø���ΪҪʹ�õ�����
	DISM /Set-AllIntl:en-US /Image:"mountpoint"
REM ��Windows PE���л�����
	wpeutil setmuilanguage
REM window��װ��������Ӹ��µ���������
	drvload inf_path 
REM Ԥ��װӦ��
	Dism /Image:"mountpoint" /Add-ProvisionedAppxPackage /PackagePath:appxpackage /DependencyPackagePath:appxpackagedependency
REM ʹ��Ӧ���ļ�ɾ�����԰�
	<package action="remove">
		<assemblyIdentity name="Microsoft-Windows-LanguagePack-Package" version="6.0.5714.0" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="en-US" />
	</package>
	Dism /Image:C:\test\offline /Apply-Unattend:C:\test\answerfiles\myunattend.xml
	Dism /Commit-Image /MountDir:C:\test\offline
	
REM Wpeutil(ÿ��ֻ�ܽ���һ������)
	Wpeutil Shutdown
	Wpeutil SetMuiLanguage de-DE
	

REM ɾ������Ŀ¼�Ĳ���
REM ���°�װӳ��
	DISM /Remount-Image /MountDir:"mountpoint"
REM ж��ӳ�񣬲���������
	DISM /Unmount-Image /MOuntDir:"mountpoint" /discard
REM �������װ�ص�ӳ�����������Դ
	DISM /Cleanup-Mountpoints

REM ����������ģʽ
	powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
	
REM ����װӳ��
	Dism /Capture-Image /ImageFile:C:\myimage.wim /CaptureDir:c:\ /Compress:fast /CheckIntegrity /ImageName:"x86_Ultimate" /ImageDescription:"x86 Ultimate Compressed"

REM WINDOWS PE REFERENCES WEB
REM https://technet.microsoft.com/zh-cn/library/hh824980.aspx

REM UNATTENDED WINDOWS SETUP REFERENCE
REM https://technet.microsoft.com/en-us/library/ff699026.aspx

REM Sysprep REFERENCE
REM https://technet.microsoft.com/zh-cn/library/hh825209.aspx

REM Driver REFERENCE
REM https://msdn.microsoft.com/en-us/library/windows/hardware/ff554690(v=vs.85).aspx

REM ADK 10
REM https://msdn.microsoft.com/zh-cn/windows/hardware/dn913721.aspx
