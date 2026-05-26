// Minimal CEF header stubs for compilation without full CEF.

#ifndef CEF_STUBS_H
#define CEF_STUBS_H

#include <string>
#include <vector>

typedef void* CefWindowHandle;
typedef int cef_cursor_type_t;
typedef int cef_log_severity_t;
typedef void* CefCursorHandle;
typedef int TransitionType;
typedef int ErrorCode;

class CefApp;
class CefBrowser;
class CefBrowserHost;
class CefBrowserProcessHandler;
class CefClient;
class CefCommand;
class CefCommandLine;
class CefDictionaryValue;
class CefDisplayHandler;
class CefFrame;
class CefLifeSpanHandler;
class CefLoadHandler;
class CefRequestContext;
class CefV8Value;

template <class T>
class CefRefPtr {
 public:
  CefRefPtr() : ptr_(NULL) {}
  CefRefPtr(T* ptr) : ptr_(ptr) {}
  T* get() const { return ptr_; }
  T* operator->() const { return ptr_; }
  bool operator!() const { return ptr_ == NULL; }
  operator bool() const { return ptr_ != NULL; }
  CefRefPtr<T>& operator=(T* ptr) { ptr_ = ptr; return *this; }

 private:
  T* ptr_;
};

#define IMPLEMENT_REFCOUNTING(ClassName)
#define DISALLOW_COPY_AND_ASSIGN(ClassName)

class CefString {
 public:
  CefString() : value_() {}
  CefString(const char* str) : value_(str ? str : "") {}
  CefString(const std::string& str) : value_(str) {}
  explicit CefString(std::string* str) : value_(str ? *str : "") {}
  std::string ToString() const { return value_; }
  const char* c_str() const { return value_.c_str(); }
  void FromString(const std::string& str) { value_ = str; }

 private:
  std::string value_;
};

class CefRect {
 public:
  CefRect() : x(0), y(0), width(0), height(0) {}
  CefRect(int ax, int ay, int awidth, int aheight)
    : x(ax), y(ay), width(awidth), height(aheight) {}
  int x;
  int y;
  int width;
  int height;
};

class CefCursorInfo {};
typedef std::vector<CefRect> RectList;
typedef std::vector<CefRefPtr<CefV8Value> > CefV8ValueList;
enum PaintElementType { PET_VIEW = 0 };

class CefBrowserHost {
 public:
  static CefRefPtr<CefBrowser> CreateBrowserSync(
      const class CefWindowInfo& window_info,
      CefRefPtr<CefClient> client,
      const CefString& url,
      const class CefBrowserSettings& settings,
      CefRefPtr<CefDictionaryValue> extra_info,
      CefRefPtr<CefRequestContext> request_context) {
    return CefRefPtr<CefBrowser>();
  }

  void WasResized() {}
  void CloseBrowser(bool force) {}
};

class CefFrame {
 public:
  void LoadURL(const CefString& url) {}
  void ExecuteJavaScript(const CefString& code, const CefString& url, int line) {}
  bool IsMain() { return true; }
  CefString GetURL() { return CefString(); }
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

class CefClient {
 public:
  virtual CefRefPtr<CefDisplayHandler> GetDisplayHandler() { return CefRefPtr<CefDisplayHandler>(); }
  virtual CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() { return CefRefPtr<CefLifeSpanHandler>(); }
  virtual CefRefPtr<CefLoadHandler> GetLoadHandler() { return CefRefPtr<CefLoadHandler>(); }
};

class CefDisplayHandler {
 public:
  virtual void OnTitleChange(CefRefPtr<CefBrowser> browser, const CefString& title) {}
};

class CefLifeSpanHandler {
 public:
  virtual void OnAfterCreated(CefRefPtr<CefBrowser> browser) {}
  virtual bool DoClose(CefRefPtr<CefBrowser> browser) { return false; }
  virtual void OnBeforeClose(CefRefPtr<CefBrowser> browser) {}
};

class CefLoadHandler {
 public:
  virtual void OnLoadStart(CefRefPtr<CefBrowser> browser,
                           CefRefPtr<CefFrame> frame,
                           TransitionType transition_type) {}
  virtual void OnLoadEnd(CefRefPtr<CefBrowser> browser,
                         CefRefPtr<CefFrame> frame,
                         int httpStatusCode) {}
  virtual void OnLoadError(CefRefPtr<CefBrowser> browser,
                           CefRefPtr<CefFrame> frame,
                           ErrorCode errorCode,
                           const CefString& errorText,
                           const CefString& failedUrl) {}
};

class CefRenderHandler {
 public:
  virtual void GetViewRect(CefRefPtr<CefBrowser> browser, CefRect& rect) {}
  virtual void OnPaint(CefRefPtr<CefBrowser> browser,
                       PaintElementType type,
                       const RectList& dirtyRects,
                       const void* buffer,
                       int width,
                       int height) {}
};

class CefV8Handler {
 public:
  virtual bool Execute(const CefString& name,
                       CefRefPtr<CefV8Value> object,
                       const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception) { return false; }
};

class CefApp {
 public:
  virtual void OnBeforeCommandLineProcessing(const CefString& process_type,
                                             CefRefPtr<CefCommandLine> command_line) {}
  virtual CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() {
    return CefRefPtr<CefBrowserProcessHandler>();
  }
};

class CefBrowserProcessHandler {
 public:
  virtual void OnBeforeChildProcessLaunch(CefRefPtr<CefCommandLine> command_line) {}
  virtual void OnContextInitialized() {}
};

class CefV8Value {};
class CefCommand {};
class CefCommandLine {
 public:
  void AppendSwitch(const CefString& name) {}
};
class CefDictionaryValue {};
class CefRequestContext {};

class CefSettings {
 public:
  std::string browser_subprocess_path;
  std::string cache_path;
  std::string resources_dir_path;
  std::string locales_dir_path;
};

class CefBrowserSettings {};

class CefWindowInfo {
 public:
  void SetAsChild(CefWindowHandle parent, const CefRect& rect) {}
};

class CefMainArgs {
 public:
  CefMainArgs(int argc, char** argv) {}
};

inline bool CefInitialize(const CefMainArgs& args,
                          const CefSettings& settings,
                          CefRefPtr<CefApp> app,
                          void* windows_sandbox_info) {
  return true;
}

inline int CefExecuteProcess(const CefMainArgs& args,
                             CefRefPtr<CefApp> app,
                             void* windows_sandbox_info) {
  return -1;
}

inline void CefShutdown() {}
inline void CefRunMessageLoop() {}
inline void CefQuitMessageLoop() {}

inline CefString CefURIEncode(const CefString& str, bool use_plus) {
  return str;
}

#endif
