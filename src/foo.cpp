#include "foo.h"
#include <QDate>
#include <QDebug>

namespace ABQ {
Math::Math(const string m) : m_m(m) {
  qDebug() << "Date: " << m_m.data() << " Date2:" << QDate::currentDate();
}
string Math::getM() const { return m_m; }
int Math::squared(int x) { return x * x; }
} // namespace ABQ
