#pragma once
// #include <QString>
#include <string>
using namespace std;

// namespace ABQ {
#if defined _WIN32
#if LIBFOO_BUILD
#define LIBFOO_API __declspec(dllexport)
#else
#define LIBFOO_API __declspec(dllimport)
#endif
#else
#define LIBFOO_API
#endif

class LIBFOO_API Math {
public:
  Math(const string);
  ~Math() {}
  string getM() const;
  int squared(int x);

private:
  string m_m;
};
// } // namespace ABQ
  // namespace ABQ
