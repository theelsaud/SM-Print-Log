#include <sourcemod>

char g_sLogPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name	=	"[SM] Print Log",
	author	=	"FIVE",
	version	=	"1.0.1",
	url		=	"https://hlmod.ru"
};

public void OnPluginStart()
{
    BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs");

    RegAdminCmd("sm_printlog", cmd_plog, ADMFLAG_ROOT, "sm_printlog <path to log> <count of last lines>");
    RegAdminCmd("sm_plog", cmd_plog, ADMFLAG_ROOT, "sm_plog <path to log> <count of last lines>");

    RegAdminCmd("sm_searchlog", cmd_slog, ADMFLAG_ROOT, "sm_searchlog <path to log> <key for search>");
    RegAdminCmd("sm_slog", cmd_slog, ADMFLAG_ROOT, "sm_slog <path to log> <key for search>");
}

Action cmd_slog(int iClient, int iArgs)
{
    if(iArgs == 0) // вывод списка доступных логов
    {
        PrintFilesOnDir(iClient, g_sLogPath, 0);
        return Plugin_Handled;
    }

    if(iArgs != 2) 
    {
        ReplyToCommand(iClient, "sm_slog <path to log> <key for search>");
        return Plugin_Handled;
    }

    char sBuf[2][PLATFORM_MAX_PATH];
    GetCmdArg(1, sBuf[0], sizeof(sBuf[]));
    GetCmdArg(2, sBuf[1], sizeof(sBuf[]));


    SearhInLog(iClient, sBuf[0], sBuf[1]);
    return Plugin_Handled;
}

Action cmd_plog(int iClient, int iArgs)
{
    if(iArgs == 0) // вывод списка доступных логов
    {
        PrintFilesOnDir(iClient, g_sLogPath, 0);
        return Plugin_Handled;
    }

    char szPath[PLATFORM_MAX_PATH];
    int iLines = 10;

    if(iArgs == 2)
    {
        GetCmdArg(2, szPath, sizeof(szPath));
        iLines = StringToInt(szPath);
    }

    GetCmdArg(1, szPath, sizeof(szPath));

    PrintLog(iClient, szPath, iLines);

    return Plugin_Handled;
}

void PrintFilesOnDir(int iClient, char[] sPath, int iStep)
{
    char sPathFull[PLATFORM_MAX_PATH], sFileName[64], sSteps[64];
    FileType iType;

    DirectoryListing dL = OpenDirectory(sPath);

    if(iStep > 0)
    {
        for(int i; i < iStep; i++)
        {
            Format(sSteps, sizeof(sSteps), "%s-", sSteps);
        }
    }

    while ( dL.GetNext(sFileName, sizeof(sFileName), iType) ) 
    {
        if(sFileName[0] == '.') continue;

        Format(sPathFull, sizeof sPathFull, "%s/%s", sPath, sFileName);
        switch(iType)
        {
            case FileType_Directory:
            {
                iStep++;
                ReplyToCommand(iClient, "> %s %s:", sSteps, sFileName);
                PrintFilesOnDir(iClient, sPathFull, iStep);
            }
            case FileType_File:
            {
                ReplyToCommand(iClient, "%s%s", sSteps, sFileName);
            }
        }
    } 
}

bool PrintLog(int iClient, char[] sPath, int iPrintLines = 10)
{
    char sFullPath[PLATFORM_MAX_PATH];
    Format(sFullPath, sizeof(sFullPath), "%s/%s", g_sLogPath, sPath);

    if(FileExists(sFullPath))
    {
        int iCountLines, iStartLine;

        File hFile = OpenFile(sFullPath, "r");

        while(!IsEndOfFile(hFile))
        {
            ReadFileLine(hFile, sFullPath, sizeof(sFullPath));
            iCountLines++;
        }

        FileSeek(hFile, SEEK_CUR, SEEK_SET);

        iStartLine = iCountLines - iPrintLines
        ReplyToCommand(iClient, "> Lines: %i (%i)", iCountLines, iStartLine);

        iCountLines = 0;

        while(!IsEndOfFile(hFile))
        {
            ReadFileLine(hFile, sFullPath, sizeof(sFullPath));
            iCountLines++;
            
            if(iCountLines > iStartLine)
            {
                ReplyToCommand(iClient, sFullPath);
            }
        }


        CloseHandle(hFile);
        

        return true;
    }

    ReplyToCommand(iClient, "File not found...");

    return false;
}

// Thanks L1MON for the idea :D
bool SearhInLog(int iClient, char[] sPath, char[] sSearchKey)
{
    char sFullPath[PLATFORM_MAX_PATH];
    Format(sFullPath, sizeof(sFullPath), "%s/%s", g_sLogPath, sPath);

    if(FileExists(sFullPath))
    {
        int iCountLines;

        File hFile = OpenFile(sFullPath, "r");

        while(!IsEndOfFile(hFile))
        {
            ReadFileLine(hFile, sFullPath, sizeof(sFullPath));
            if(StrContains(sFullPath, sSearchKey) != -1)
            {
                ReplyToCommand(iClient, sFullPath);
                iCountLines++;
            }
        }


        CloseHandle(hFile);

        if(iCountLines == 0) ReplyToCommand(iClient, "Not found %s on %s", sSearchKey, sPath);
        

        return true;
    }

    ReplyToCommand(iClient, "File not found...");

    return false;
}