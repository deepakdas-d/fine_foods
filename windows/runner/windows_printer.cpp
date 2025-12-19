#include "windows_printer.h"

#include <iostream>
#include <vector>
#include <windows.h>
#include <winspool.h>

WindowsPrinter::WindowsPrinter() {}

WindowsPrinter::~WindowsPrinter() {}

std::vector<std::string> WindowsPrinter::GetPrinters()
{
    std::vector<std::string> printers;
    DWORD needed = 0;
    DWORD returned = 0;

    EnumPrintersW(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, NULL, 4, NULL, 0, &needed, &returned);

    if (needed == 0)
    {
        return printers;
    }

    std::vector<BYTE> buffer(needed);
    PRINTER_INFO_4W *printer_info = reinterpret_cast<PRINTER_INFO_4W *>(buffer.data());

    if (EnumPrintersW(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, NULL, 4, buffer.data(), needed, &needed, &returned))
    {
        for (DWORD i = 0; i < returned; ++i)
        {
            if (printer_info[i].pPrinterName != NULL)
            {
                std::wstring wname = printer_info[i].pPrinterName;
                int size_needed = WideCharToMultiByte(CP_UTF8, 0, wname.c_str(), -1, NULL, 0, NULL, NULL);
                std::string name(size_needed, 0);
                WideCharToMultiByte(CP_UTF8, 0, wname.c_str(), -1, &name[0], size_needed, NULL, NULL);
                name.pop_back(); // remove null terminator
                printers.push_back(name);
            }
        }
    }
    return printers;
}

std::string WindowsPrinter::PrintRaw(const std::string &printer_name, const std::vector<uint8_t> &data)
{
    HANDLE hPrinter = NULL;
    DWORD dwJob = 0;
    DWORD dwBytesWritten = 0;

    std::cerr << "[WindowsPrinter.Native] Starting print job to printer: " << printer_name
              << " with " << data.size() << " bytes of data" << std::endl;

    // Convert UTF-8 to UTF-16
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, printer_name.c_str(), -1, NULL, 0);
    if (size_needed == 0)
    {
        std::string err = "[WindowsPrinter.Native] Failed to convert printer name: " + GetLastErrorAsString();
        std::cerr << err << std::endl;
        return err;
    }
    std::wstring wprinter_name(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, printer_name.c_str(), -1, &wprinter_name[0], size_needed);

    // Open printer
    if (!OpenPrinterW(const_cast<LPWSTR>(wprinter_name.c_str()), &hPrinter, NULL))
    {
        std::string err = "[WindowsPrinter.Native] OpenPrinter failed: " + GetLastErrorAsString();
        std::cerr << err << std::endl;
        return err;
    }
    std::cerr << "[WindowsPrinter.Native] OpenPrinter succeeded - Native connection established" << std::endl;

    // DOC_INFO with RAW for Generic/Text Only + ESC/POS thermal
    DOC_INFO_1W DocInfo;
    DocInfo.pDocName = L"Flutter Raw ESC/POS Print Job";
    DocInfo.pOutputFile = NULL;
    DocInfo.pDatatype = L"RAW"; // Changed to "RAW" for Generic/Text Only driver

    // Start document
    dwJob = StartDocPrinterW(hPrinter, 1, (LPBYTE)&DocInfo);
    if (dwJob == 0)
    {
        std::string err = "[WindowsPrinter.Native] StartDocPrinter failed: " + GetLastErrorAsString();
        std::cerr << err << std::endl;
        ClosePrinter(hPrinter);
        return err;
    }
    std::cerr << "[WindowsPrinter.Native] StartDocPrinter succeeded (Job ID: " << dwJob << ")" << std::endl;

    // Start page
    if (!StartPagePrinter(hPrinter))
    {
        std::string err = "[WindowsPrinter.Native] StartPagePrinter failed: " + GetLastErrorAsString();
        std::cerr << err << std::endl;
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return err;
    }
    std::cerr << "[WindowsPrinter.Native] StartPagePrinter succeeded" << std::endl;

    // Write data
    if (!WritePrinter(hPrinter, (LPVOID)data.data(), (DWORD)data.size(), &dwBytesWritten))
    {
        std::string err = "[WindowsPrinter.Native] WritePrinter failed: " + GetLastErrorAsString();
        std::cerr << err << std::endl;
        EndPagePrinter(hPrinter);
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return err;
    }
    std::cerr << "[WindowsPrinter.Native] WritePrinter succeeded - Wrote " << dwBytesWritten << " bytes" << std::endl;

    if (dwBytesWritten != data.size())
    {
        std::string err = "[WindowsPrinter.Native] Incomplete write: " + std::to_string(dwBytesWritten) + " of " + std::to_string(data.size()) + " bytes";
        std::cerr << err << std::endl;
        EndPagePrinter(hPrinter);
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return err;
    }

    // End page
    if (!EndPagePrinter(hPrinter))
    {
        std::string err = "[WindowsPrinter.Native] EndPagePrinter failed: " + GetLastErrorAsString();
        std::cerr << err << std::endl;
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return err;
    }
    std::cerr << "[WindowsPrinter.Native] EndPagePrinter succeeded" << std::endl;

    // End document
    if (!EndDocPrinter(hPrinter))
    {
        std::string err = "[WindowsPrinter.Native] EndDocPrinter failed: " + GetLastErrorAsString();
        std::cerr << err << std::endl;
        ClosePrinter(hPrinter);
        return err;
    }
    std::cerr << "[WindowsPrinter.Native] EndDocPrinter succeeded" << std::endl;

    ClosePrinter(hPrinter);
    std::cerr << "[WindowsPrinter.Native] Print job completed successfully - Printer working" << std::endl;
    return ""; // Success
}

std::string WindowsPrinter::GetLastErrorAsString()
{
    DWORD errorID = ::GetLastError();
    if (errorID == 0)
        return "No error";

    LPWSTR messageBuffer = nullptr;
    size_t size = FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                                 NULL, errorID, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPWSTR)&messageBuffer, 0, NULL);

    std::wstring wmessage(messageBuffer, size);
    LocalFree(messageBuffer);

    int utf8_size = WideCharToMultiByte(CP_UTF8, 0, wmessage.c_str(), -1, NULL, 0, NULL, NULL);
    std::string message(utf8_size, 0);
    WideCharToMultiByte(CP_UTF8, 0, wmessage.c_str(), -1, &message[0], utf8_size, NULL, NULL);
    message.pop_back(); // remove null
    return message;
}