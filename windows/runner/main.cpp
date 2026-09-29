#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Named mutex that makes CalenLog single-instance. A second launch finds the
// existing window, brings it to the front and exits.
constexpr const wchar_t kInstanceMutex[] = L"CalenLog.SingleInstance";

// Window class / title registered by Win32Window, used to locate the first
// instance's window.
constexpr const wchar_t kWindowClass[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr const wchar_t kWindowTitle[] = L"CalenLog";

// Default window size, in 96-dpi (logical) pixels.
constexpr int kWindowWidth = 1280;
constexpr int kWindowHeight = 720;

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // --- Single instance guard ---------------------------------------------
  HANDLE mutex = ::CreateMutexW(nullptr, TRUE, kInstanceMutex);
  const bool already_running =
      (mutex != nullptr) && (::GetLastError() == ERROR_ALREADY_EXISTS);
  if (already_running) {
    HWND existing = ::FindWindowW(kWindowClass, kWindowTitle);
    if (existing != nullptr) {
      if (::IsIconic(existing)) {
        ::ShowWindow(existing, SW_RESTORE);
      }
      ::SetForegroundWindow(existing);
    }
    if (mutex != nullptr) {
      ::CloseHandle(mutex);
    }
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(kWindowWidth, kWindowHeight);
  if (!window.Create(kWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();

  if (mutex != nullptr) {
    ::ReleaseMutex(mutex);
    ::CloseHandle(mutex);
  }
  return EXIT_SUCCESS;
}
