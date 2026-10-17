#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QProcess>
#include <QTimer>
#include <QVariantList>

class QNetworkReply;

class ZeroTierController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString serviceStatus READ serviceStatus NOTIFY stateChanged)
    Q_PROPERTY(QString nodeId READ nodeId NOTIFY stateChanged)
    Q_PROPERTY(QVariantList networks READ networks NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY stateChanged)
    Q_PROPERTY(QString message READ message NOTIFY stateChanged)
    Q_PROPERTY(bool messageIsError READ messageIsError NOTIFY stateChanged)
    Q_PROPERTY(QString lastUpdated READ lastUpdated NOTIFY stateChanged)
    Q_PROPERTY(bool demoMode READ demoMode CONSTANT)

public:
    explicit ZeroTierController(bool demoMode = false, QObject *parent = nullptr);

    QString serviceStatus() const { return m_serviceStatus; }
    QString nodeId() const { return m_nodeId; }
    QVariantList networks() const { return m_networks; }
    bool busy() const { return m_busy; }
    QString message() const { return m_message; }
    bool messageIsError() const { return m_messageIsError; }
    QString lastUpdated() const { return m_lastUpdated; }
    bool demoMode() const { return m_demoMode; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void join(const QString &networkId);
    Q_INVOKABLE void leave(const QString &networkId);
    Q_INVOKABLE void clearMessage();
    Q_INVOKABLE void copyToClipboard(const QString &text);

signals:
    void stateChanged();

private slots:
    void onAuthorizationFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onApiReply();

private:
    void ensureTokenAndRun(const QString &operation, const QString &networkId = {});
    void request(const QByteArray &method, const QString &path, const QString &operation, const QByteArray &body = {});
    void setMessage(const QString &message, bool isError = false);
    void updateNetworks(const QByteArray &json);

    QNetworkAccessManager m_network;
    QProcess m_authorizer;
    QTimer m_networkPollTimer;
    QString m_token;
    QString m_operation;
    QString m_pendingOperation;
    QString m_pendingNetworkId;
    QString m_serviceStatus = "Verificando…";
    QString m_nodeId = "—";
    QString m_message;
    QString m_lastUpdated;
    QVariantList m_networks;
    bool m_busy = false;
    bool m_messageIsError = false;
    bool m_demoMode = false;
    int m_joinPollsRemaining = 0;
};
