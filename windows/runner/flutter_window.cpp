#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate()
{
  if (!Win32Window::OnCreate())
  {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view())
  {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Initialize Windows Printer
  printer_ = std::make_unique<WindowsPrinter>();

  // Register Method Channel
  printer_channel_ = std::make_unique<flutter::MethodChannel<>>(
      flutter_controller_->engine()->messenger(), "com.deepak.fine_foods/printer",
      &flutter::StandardMethodCodec::GetInstance());

  printer_channel_->SetMethodCallHandler(
      [&](const flutter::MethodCall<> &call,
          std::unique_ptr<flutter::MethodResult<>> result)
      {
        if (call.method_name() == "getPrinters")
        {
          try
          {
            std::vector<std::string> printers = printer_->GetPrinters();
            // Convert to Flutter list
            flutter::EncodableList printer_list;
            for (const auto &printer : printers)
            {
              printer_list.push_back(flutter::EncodableValue(printer));
            }
            result->Success(printer_list);
          }
          catch (const std::exception &e)
          {
            result->Error("backend_error", e.what());
          }
          catch (...)
          {
            result->Error("backend_error", "Unknown error fetching printers");
          }
        }
        else if (call.method_name() == "print")
        {
          const auto *arguments = std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments)
          {
            auto device_it = arguments->find(flutter::EncodableValue("device_name"));
            auto data_it = arguments->find(flutter::EncodableValue("data"));

            if (device_it != arguments->end() && data_it != arguments->end())
            {
              if (std::holds_alternative<std::string>(device_it->second) &&
                  std::holds_alternative<std::vector<uint8_t>>(data_it->second))
              {

                std::string device_name = std::get<std::string>(device_it->second);
                std::vector<uint8_t> data = std::get<std::vector<uint8_t>>(data_it->second);

                std::string error_msg = printer_->PrintRaw(device_name, data);
                if (error_msg.empty())
                {
                  result->Success(nullptr);
                }
                else
                {
                  result->Error("print_error", error_msg);
                }
              }
              else
              {
                result->Error("invalid_arguments", "Invalid types for device_name or data");
              }
            }
            else
            {
              result->Error("invalid_arguments", "Missing device_name or data");
            }
          }
          else
          {
            result->Error("invalid_arguments", "Arguments must be a Map");
          }
        }
        else
        {
          result->NotImplemented();
        }
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]()
                                                      { this->Show(); });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy()
{
  if (flutter_controller_)
  {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept
{
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_)
  {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result)
    {
      return *result;
    }
  }

  switch (message)
  {
  case WM_FONTCHANGE:
    flutter_controller_->engine()->ReloadSystemFonts();
    break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
