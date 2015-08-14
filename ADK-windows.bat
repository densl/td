REM PE TOOLS(DISM, IMAGEX) FROM ADK: Windows Assessment and Deployment Kit
REM DISM
REM 1
REM 获取wim信息
    DISM /get-wiminfo /wimfile:install.wim
	
REM 2
REM 加载镜像
    DISM /mount-wim /wimfile:install.wim /index:1 /mountdir:d:\test
	
REM 3
REM 安装驱动
	DISM /image:d:\test /add-driver /driver:k:\oem1.inf
	
REM 4
REM 查看驱动
	DISM /image:d:\test /get-drivers
	
REM 5
REM 卸载镜像并保存
	DISM /unmount-wim /mountdir:d:\test /commit

REM 6
REM 写入产品序列号
	call DISM /Image:w: /Set-ProductKey:XXXX-XXXX-XXXX-XXXX-XXXX

REM 7
REM 删除驱动
	DISM /image:d:\test /Remove-Driver /driver:k:\oem1.inf_path

	
REM ***************************************************
REM IMAGEX
REM 1
REM 合并wim
	imagex /export install.swm * /ref d:\*.swm new.wim
	
REM 2
REM 拆分wim
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
	
REM 还原挂起操作
	DISM /Image:"imagePath" /cleanup-image /RevertPendingActions
REM 还原镜像
	DISM /Image:"imagePath" /Cleanup-image /RestoreHealth
REM 4
REM SET BOOT FILE
	BCDboot P:\Windows /s P: /f ALL
	
	
REM ***********************************
REM 添加启动脚本
REM 修改 Startnet.cmd 脚本（Windows\System32\Startnet.cmd)
REM 要获得即插即用或网络支持，应调用wpeinit
REM Wpeinit 将日志消息输出到 windows\system32\wpeinit.log
REM Wpeinit cmd
	Wpeinit -unattend:"unattend-pe.xml"
	
REM 添加自定义应用
REM 创建 Winpeshl.ini 文件替代外壳应用程序
	[LaunchApp]
	AppPath = %SYSTEMDRIVE%\Fabrikam\shell.exe
	[LaunchApps]
	%SYSTEMDRIVE%\Fabrikam\app1.exe
	%SYSTEMDRIVE%\Fabrikam\app1.exe, /s "c:\program files\app3"
REM 顺序执行，支持运行应用，但不支持常见脚本命令

REM 添加临时存储（暂存空间,32/64/128/256/512）
	DISM /Set-ScratchSpace:128 /Image:"mountpoint"
	
REM 替换背景图像
REM 替换图片 mount\windows\system32\winpe.jpg

REM 添加可选组件
REM 添加可选组件（程序包或.cab文件，需同时添加可选组件及其关联的语言包）
	DISM /Add-Package /Image:"mountpoint" /PackagePath:"winpe-hta.cab"	
REM 验证可选组件是否为映像的一部分(查看程序包结果列表)
	DISM /Get-Packages /Image:"mount"
	
REM 添加多语言
REM 查看当前语言
	DISM /Image:"mountpoint" /Get-Intl
REM 删除语言包
	DISM /Image:"mountpoint" /Remove-Package /PackagePath:"package.cab"
	Dism /Image:"mountpoint" /Remove-Package /PackageName:Microsoft.Windows.Calc.Demo~6595b6144ccf1df~x86~en~1.0.0.0
REM 列出可选组件
	DISM /Get-Packages /Image:"mountpoint"
REM 添加相应语言包，包括基本Windows PE 语言包
	DISM /Add-Package /Image:"mountpoint" /PackagePath:"lp.cab"  (基本Windows PE 语言包)
	DISM /Add-Package /Image:"mountpoint" /PackagePath:"winpe-hta_en-us.cab"
REM 验证语言包（包括基本Windows PE 映像）
	DISM /Get-Packages /Image:"mountpoint"
REM 将区域设置更改为要使用的语言
	DISM /Set-AllIntl:en-US /Image:"mountpoint"
REM 在Windows PE中切换语言
	wpeutil setmuilanguage
REM window安装过程中添加更新的驱动程序
	drvload inf_path 
REM 预安装应用
	Dism /Image:"mountpoint" /Add-ProvisionedAppxPackage /PackagePath:appxpackage /DependencyPackagePath:appxpackagedependency
REM 使用应答文件删除语言包
	<package action="remove">
		<assemblyIdentity name="Microsoft-Windows-LanguagePack-Package" version="6.0.5714.0" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="en-US" />
	</package>
	Dism /Image:C:\test\offline /Apply-Unattend:C:\test\answerfiles\myunattend.xml
	Dism /Commit-Image /MountDir:C:\test\offline
	
REM Wpeutil(每行只能接受一个命令)
	Wpeutil Shutdown
	Wpeutil SetMuiLanguage de-DE
	

REM 删除工作目录的步骤
REM 重新安装映像
	DISM /Remount-Image /MountDir:"mountpoint"
REM 卸载映像，并放弃更改
	DISM /Unmount-Image /MOuntDir:"mountpoint" /discard
REM 清除与已装载的映像相关联的资源
	DISM /Cleanup-Mountpoints

REM 开启高性能模式
	powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
	
REM 捕获安装映像
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
