#pragma once

#include <QObject>
#include <QString>

class AppSettings final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);

    QString language() const { return m_language; }
    void setLanguage(const QString &language);

signals:
    void languageChanged();

private:
    QString m_language = "en";
};
