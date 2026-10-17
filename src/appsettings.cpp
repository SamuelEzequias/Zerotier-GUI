#include "appsettings.h"

#include <QSettings>

AppSettings::AppSettings(QObject *parent) : QObject(parent)
{
    QSettings settings;
    m_language = settings.value("ui/language", "en").toString();
    if (m_language != "en" && m_language != "pt") m_language = "en";
}

void AppSettings::setLanguage(const QString &language)
{
    const QString normalized = language == "en" ? "en" : "pt";
    if (m_language == normalized) return;
    m_language = normalized;
    QSettings settings;
    settings.setValue("ui/language", m_language);
    emit languageChanged();
}
