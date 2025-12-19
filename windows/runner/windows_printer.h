#ifndef RUNNER_WINDOWS_PRINTER_H_
#define RUNNER_WINDOWS_PRINTER_H_

#include <string>
#include <vector>
#include <windows.h>

class WindowsPrinter {
 public:
  WindowsPrinter();
  virtual ~WindowsPrinter();

  // Returns a list of installed printer names.
  std::vector<std::string> GetPrinters();

  // Sends raw bytes to the specified printer using the Win32 Spooler API.
  // Returns true on success, false on failure.
  std::string PrintRaw(const std::string& printer_name, const std::vector<uint8_t>& data);

 private:
  // Helper to get formatted error message
  std::string GetLastErrorAsString();
};

#endif  // RUNNER_WINDOWS_PRINTER_H_
