// Minimal CEF header stubs for compilation without full CEF
// This allows WebView to compile and function in header-only mode

#ifndef CEF_STUBS_H
#define CEF_STUBS_H

#include <string>
#include <memory>

// Minimal CEF stub types
typedef void* CefWindowHandle;
typedef int cef_cursor_type_t;
typedef int cef_log_severity_t;
typedef void* CefCursorHandle;

class CefCursorInfo {};
class CefRect {
 public:
  CefRect() {}
  CefRect(int x, int y, int width, int height) {}
};

class CefString {
 public:
  CefString() {}
  CefString(const std::string& str) {}
  std::string ToString() const { return ""; }
  const char* c_str() const { return ""; }
};

template <class T>
class CefRefPtr {
 public:
  CefRefPtr() {}
  CefRefPtr(T* ptr) {}
  T* get() { return nullptr; }
  T* operator->() { return nullptr; }
  bool operator!() const { return true; }
  operator bool() const { return false; }
};

template <class T>
class scoped_refptr {
 public:
  scoped_refptr() {}
  scoped_refptr(T* ptr) {}
  T* get() { return nullptr; }
  T* operator->() { return nullptr; }
  bool operator!() const { return true; }
  operator bool() const { return false; }
};

#define IMPLEMENT_REFCOUNTING(ClassName)
#define DISALLOW_COPY_AND_ASSIGN(ClassName)

class CefBrowser { public: ~CefBrowser() {} };
class CefBrowserHost { 
 public: 
  void WasResized() {}
  void CloseBrowser(bool force) {}
  ~CefBrowserHost() {}
};
class CefClient { public: ~CefClient() {} };
class CefDisplayHandler { public: ~CefDisplayHandler() {} };
class CefLifeSpanHandler { public: ~CefLifeSpanHandler() {} };
class CefLoadHandler { public: ~CefLoadHandler() {} };
class CefRenderHandler { public: ~CefRenderHandler() {} };
class CefV8Handler { public: ~CefV8Handler() {} };
class CefApp { public: ~CefApp() {} };
class CefBrowserProcessHandler { public: ~CefBrowserProcessHandler() {} };
class CefFrame { public: void LoadURL(const std::string& url) {} void ExecuteJavaScript(const std::string& code, const std::string& url, int line) {} ~CefFrame() {} };
class CefV8Value { public: ~CefV8Value() {} };
class CefSettings {};
class CefBrowserSettings {};
class CefWindowInfo {
 public:
  void SetAsChild(CefWindowHandle parent, const CefRect& rect) {}
};
class CefMainArgs {
 public:
  CefMainArgs(int argc, char** argv) {}
};

typedef CefString CefStringBase;

class CefCommand {};
typedef int TransitionType;
typedef int ErrorCode;

typedef std::vector<CefRect> RectList;
typedef std::vector<CefRefPtr<CefV8Value>> CefV8ValueList;

enum PaintElementType { PET_VIEW = 0 };

bool CefInitialize(const CefMainArgs& args, const CefSettings& settings, 
                   CefRefPtr<CefApp> app, void* windows_sandbox_info) {
  return true;
}

void CefShutdown() {}

void CefRunMessageLoop() {}

void CefQuitMessageLoop() {}

class CefBrowserHost {
 public:
  static CefRefPtr<CefBrowserHost> CreateBrowserSync(
      const CefWindowInfo& window_info,
      CefRefPtr<CefClient> client,
      const CefString& url,
      const CefBrowserSettings& settings,
      CefRefPtr<CefCommand> command,
      CefWindowHandle parent) {
    return CefRefPtr<CefBrowserHost>();
  }
};

class CefBrowser {
 public:
  CefRefPtr<CefBrowserHost> GetHost() { return CefRefPtr<CefBrowserHost>(); }
  CefRefPtr<CefFrame> GetMainFrame() { return CefRefPtr<CefFrame>(); }
  void Reload() {}
  void StopLoad() {}
  void GoBack() {}
  void GoForward() {}
  bool CanGoBack() { return false; }
  bool CanGoForward() { return false; }
  int GetIdentifier() { return 0; }
};

class CefFrame {
 public:
  void LoadURL(const CefString& url) {}
  void ExecuteJavaScript(const CefString& code, const CefString& url, int line) {}
  bool IsMain() { return false; }
  CefString GetURL() { return CefString(); }
};

CefString CefURIEncode(const CefString& str, bool use_plus) {
  return CefString();
}

#endif // CEF_STUBS_H
