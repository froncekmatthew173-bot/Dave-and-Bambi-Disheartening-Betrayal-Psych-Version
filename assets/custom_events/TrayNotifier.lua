local ffi = require('ffi')
local bit = require('bit')
local shell32 = ffi.load('shell32')

ffi.cdef([[
    typedef int BOOL;
    typedef unsigned int DWORD;
    typedef unsigned int UINT;
    typedef intptr_t HANDLE;
    typedef intptr_t HWND;
    typedef intptr_t HICON;
    typedef intptr_t HINSTANCE;
    typedef struct { int Data[4]; } GUID;
    typedef struct {
        DWORD cbSize;
        HWND hWnd;
        UINT uID;
        UINT uFlags;
        UINT uCallbackMessage;
        HICON hIcon;
        char szTip[128];
        DWORD dwState;
        DWORD dwStateMask;
        char szInfo[256];
        union { UINT uTimeout; UINT uVersion; };
        char szInfoTitle[64];
        DWORD dwInfoFlags;
        GUID guidItem;
        HICON hBalloonIcon;
    } NOTIFYICONDATAA;
    
    BOOL Shell_NotifyIconA(int dwMessage, NOTIFYICONDATAA *lpData);
    HICON LoadIconA(HINSTANCE hInstance, intptr_t IconCode);
    BOOL DestroyIcon(HICON hIcon);
    HWND GetConsoleWindow();
]])

local ICON_CODES = {
    APPLICATION = 32512,   -- Default application icon
    ERROR = 32513,         -- Standard error icon (exclamation mark inside a circle)
    HAND = 32513,          -- Same as ERROR
    QUESTION = 32514,      -- Question mark icon
    WARNING = 32515,       -- Warning triangle icon
    EXCLAMATION = 32515,   -- Same as WARNING
    ASTERISK = 32516,      -- Information icon (i inside a circle)
    INFO = 32516,          -- Same as ASTERISK
    WINLOGO = 32517,       -- Windows logo icon
    SHIELD = 32518         -- Security shield icon (introduced in Windows XP SP2)
}

local TrayNotifier = {
    icon_handles = {},
    notify_data = ffi.new("NOTIFYICONDATAA")
}

function TrayNotifier:initialize()
    self.notify_data.cbSize = ffi.sizeof(self.notify_data)
    self.notify_data.hWnd = ffi.C.GetConsoleWindow()
    self.notify_data.uVersion = 4
end

function TrayNotifier:load_icon(icon_type)
    local icon_code = ICON_CODES[icon_type] or ICON_CODES.INFO
    local icon_handle = ffi.C.LoadIconA(ffi.cast("HINSTANCE", 0), icon_code)
    if icon_handle == ffi.NULL then
        error("Failed to load icon: " .. icon_type)
    end
    return icon_handle
end

function TrayNotifier:refresh_icons(icon_type)
    if self.icon_handles.tray then ffi.C.DestroyIcon(self.icon_handles.tray) end
    self.icon_handles.tray = self:load_icon(icon_type)
    
    self.notify_data.uFlags = bit.bor(0x00000001, 0x00000002)  -- NIF_MESSAGE | NIF_ICON
    self.notify_data.hIcon = self.icon_handles.tray

    shell32.Shell_NotifyIconA(0, self.notify_data)  -- NIM_ADD
end

function TrayNotifier:notify(title, message, icon_type, duration)
    self:refresh_icons(icon_type)
    
    self.notify_data.uFlags = bit.bor(0x00000001, 0x00000002, 0x00000010)  -- NIF_MESSAGE | NIF_ICON | NIF_INFO
    self.notify_data.dwInfoFlags = bit.bor(0x00000004, 0x00000020)  -- NIIF_USER | NIIF_LARGE_ICON
    self.notify_data.uTimeout = duration or 3000
    
    ffi.copy(self.notify_data.szInfoTitle, title or "Rhythm Alert", 64)
    ffi.copy(self.notify_data.szInfo, message or "Default Message", 256)

    shell32.Shell_NotifyIconA(1, self.notify_data)  -- NIM_MODIFY
end

function TrayNotifier:destroy()
    shell32.Shell_NotifyIconA(2, self.notify_data)  -- NIM_DELETE
    if self.icon_handles.tray then ffi.C.DestroyIcon(self.icon_handles.tray) end
    self.icon_handles = {}
end

function onCreate()
    TrayNotifier:initialize()
    TrayNotifier:refresh_icons('default')
end

function onEvent(eventName, value1, value2)
    if eventName == 'TrayNotifier' then
        -- Parse: "Message Text|5000" and "Title|INFO"
        local msgData = split(value1, ',')
        local titleData = split(value2, ',')
        
        -- Show tray notification
        TrayNotifier:notify(
            titleData[1] or 'Anticheat.dll',  -- Default title if not provided
            msgData[1] or 'Potential threat detected: expunged.dat', -- Default message if not provided
            titleData[2] or 'WARNING',          -- Default icon type if not provided
            tonumber(msgData[2]) or 5000     -- Default duration if not provided
        )
    end
end

function onDestroy()
    TrayNotifier:destroy()
end

-- Utility: Split a string by a delimiter
function split(input, sep)
    local t = {}
    for str in string.gmatch(input, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end