//get reg value 
static DWORD getRegValue(LPCTSTR keyName, LPCTSTR keyValue, LPVOID regValue, LPDWORD len)
{	
	HKEY hKey;
	DWORD ret = RegOpenKeyEx(HKEY_LOCAL_MACHINE,keyName,0,KEY_READ,&hKey);
	if( ERROR_SUCCESS !=  ret)
	{
		return ret;
	}

	//query value
	ret = RegQueryValueEx(hKey,keyValue,NULL,NULL,(BYTE*)regValue,len);
	RegCloseKey(hKey);
	return ret;
}

//get reg key list 
static DWORD getRegList(LPCTSTR keyName, CString& keyList, LPDWORD keyCount)
{
	DWORD ret = 0;
	HKEY hKey;
	ret = RegOpenKeyEx( HKEY_LOCAL_MACHINE, keyName, 0, KEY_READ, &hKey);
	if (ERROR_SUCCESS != ret)
	{
		return ret;
	}

	keyList.Empty();
	DWORD num = 0;
	TCHAR temp[512];
	DWORD retLen = 512;
	for (int i =0; ; i++)
	{
		retLen = 512;
		memset(temp, 0, 512*( sizeof(TCHAR) ));
		ret = RegEnumKeyEx(hKey, i, temp, &retLen, NULL, NULL, NULL, NULL); 
		if (ret != ERROR_SUCCESS)
		{
			break;
		}
		num++;
		keyList.Append(temp);
		keyList.Append(";");
	}

	RegCloseKey(hKey);
	*keyCount = num;
	return (num > 0) ? 0 : ret;
}

//CRegKey
{
	CRegKey mKey;
	CString strPath;
	strPath = "SOFTWARE/TEST";
	if ( mKey.Open(HKEY_LOCAL_MACHINE, strPath) != ERROR_SUCCESS){
		//do something
	}
	mKey.Close();
}

//set mfc background
{
	CPaintDC dc(this);
	
	CRect rect;
	GetClientRect(&rect);
	
	CBitmap m_bmp;
	m_bmp.LoadBitmap(IDB_BITMAP);
	
	BITMAP bmp;
	m_bmp.GetBitmap(&bmp);
	CDC dcMem;
	dcMem.CreateCompatibleDC(&dc);
	dcMem.SElectObject(&m_bmp);
	dc.StretchBlt(0, 0, rect.Width(), rect.Height(), &dcMem, 0, 0, bmp.bmWidth, bmp.bmHeight, SRCCOPY);
}

//run shell cmd infinite
static void eshell(LPCSTR cmd)
{
	SHELLEXECUTEINFO shExecInfo;
	memset(&shExecInfo, 0, sizeof(shExecInfo));
	shExecInfo.cbSize = sizeof(SHELLEXECUTEINFO);
	shExecInfo.fMask = SEE_MASK_NOCLOSEPROCESS;
	shExecInfo.hwnd = NULL;
	shExecInfo.lpFile = cmd;
	shExecInfo.nShow = SW_SHOWNORMAL;

	ShellExecuteEx(&shExecInfo);
	WaitForSingleObject(shExecInfo.hProcess, INFINITE);
}

//set font
{
	CFont m_font;
	m_font.CreateFont(18, 0, 0, 0, FW_LIGHT, 0, 0, 0, 1, 0, 0, 0, 0, "宋体");
	CStatic cs;
	cs.SetFont(&m_font, 1);
}

//ftp
{
	CInternetSession* mInternetSession;
	CFtpConnection*   mFtpConnection;
	mInternetSession = new CInternetSession(
		AfxGetAppName(), 1, PRE_CONFIG_INTERNET_ACCESS);
		
	try {
		mFtpConnection = mInternetSession->
			GetFtpConnection("192.168.1.1", "user", "password", 21);
	} catch (CInternetException *pEx){
		TCHAR szError[1024] = { 0 };
		pEx->GetErrorMessage(szError, 1024);
	}
	mFtpConnection->close();

	//upload a file
	CInternetSession uploadSession;
	CFtpConnection* upConnect = NULL;
	try {
		upConnect = uploadSession.GetFtpConnection(
			"192.168.1.1", "user", "password", 21, INTERNET_FLAG_PASSIVE);

		CInternetFile* iFile = upConnect->OpenFile(
			"remotePath", GENERIC_WRITE, FTP_TRANSFER_TYPE_BINARY, 0);
		iFile->Write("hello", 5);
		iFile->Flush();
		iFile->Close();
	} catch (CInternetException *pEx){
		;
	}

}

//ip dns address
//ip.dnsexist.com


