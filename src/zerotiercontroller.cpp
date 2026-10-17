#include "zerotiercontroller.h"

#include <QDateTime>
#include <QGuiApplication>
#include <QClipboard>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QStandardPaths>
#include <unistd.h>

ZeroTierController::ZeroTierController(bool demoMode, QObject *parent)
    : QObject(parent), m_demoMode(demoMode)
{
    m_networkPollTimer.setSingleShot(true);
    connect(&m_networkPollTimer, &QTimer::timeout, this, [this] {
        if (m_joinPollsRemaining <= 0) return;
        if (m_busy) {
            m_networkPollTimer.start(750);
            return;
        }
        --m_joinPollsRemaining;
        refresh();
    });
    connect(&m_authorizer, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, &ZeroTierController::onAuthorizationFinished);
    connect(&m_authorizer, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart) return;
        m_busy = false;
        m_serviceStatus = "Indisponível";
        setMessage("Não foi possível abrir a autorização do sistema. Confira se o Polkit está instalado.", true);
        emit stateChanged();
    });
    if (m_demoMode) {
        m_nodeId = "8f3c2a1d7b9e4c60";
        m_serviceStatus = "Online";
        m_lastUpdated = QDateTime::currentDateTime().toString("HH:mm");
        m_networks.append(QVariantMap{
            {"id", "a09acf0234e5d6f7"},
            {"name", "Studio Mesh"},
            {"status", "OK"},
            {"type", "PRIVATE"},
            {"address", "10.147.20.14/24"},
            {"connected", true}
        });
    } else {
        refresh();
    }
}

void ZeroTierController::refresh()
{
    if (m_demoMode) return;
    ensureTokenAndRun("status");
}

void ZeroTierController::join(const QString &networkId)
{
    if (m_demoMode) return;
    static const QRegularExpression idPattern("^[0-9a-fA-F]{16}$");
    if (!idPattern.match(networkId).hasMatch()) {
        setMessage("Digite um ID válido com 16 caracteres hexadecimais.", true);
        emit stateChanged();
        return;
    }
    ensureTokenAndRun("join", networkId.toLower());
}

void ZeroTierController::leave(const QString &networkId)
{
    if (m_demoMode) return;
    m_networkPollTimer.stop();
    m_joinPollsRemaining = 0;
    ensureTokenAndRun("leave", networkId);
}

void ZeroTierController::clearMessage()
{
    if (m_message.isEmpty()) return;
    m_message.clear();
    m_messageIsError = false;
    emit stateChanged();
}

void ZeroTierController::copyToClipboard(const QString &text)
{
    QGuiApplication::clipboard()->setText(text);
    setMessage("ID copiado para a área de transferência.");
    emit stateChanged();
}

void ZeroTierController::ensureTokenAndRun(const QString &operation, const QString &networkId)
{
    if (m_busy) return;
    m_busy = true;
    m_operation = operation;
    m_pendingOperation = operation;
    m_pendingNetworkId = networkId;
    emit stateChanged();

    if (!m_token.isEmpty()) {
        if (operation == "status") request("GET", "/status", operation);
        else if (operation == "networks") request("GET", "/network", operation);
        else if (operation == "join") request("POST", "/network/" + networkId, operation, "{}");
        else if (operation == "leave") request("DELETE", "/network/" + networkId, operation);
        return;
    }

    const QString catPath = QStandardPaths::findExecutable("cat");
    const QString pkexecPath = QStandardPaths::findExecutable("pkexec");
    if (catPath.isEmpty() || (::geteuid() != 0 && pkexecPath.isEmpty())) {
        m_busy = false;
        setMessage("É necessário ter o Polkit (pkexec) instalado para acessar o ZeroTier.", true);
        emit stateChanged();
        return;
    }

    const QString tokenFile = "/var/lib/zerotier-one/authtoken.secret";
    m_authorizer.setProgram(::geteuid() == 0 ? catPath : pkexecPath);
    m_authorizer.setArguments(::geteuid() == 0
        ? QStringList{tokenFile}
        : QStringList{catPath, tokenFile});
    setMessage("Autorize o acesso ao ZeroTier uma vez nesta sessão…");
    m_authorizer.start();
}

void ZeroTierController::onAuthorizationFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    const QString token = QString::fromLocal8Bit(m_authorizer.readAllStandardOutput()).trimmed();
    const QString error = QString::fromLocal8Bit(m_authorizer.readAllStandardError()).trimmed();
    if (exitStatus != QProcess::NormalExit || exitCode != 0 || token.isEmpty()) {
        m_busy = false;
        setMessage(error.isEmpty() ? "Não foi possível autorizar o acesso ao serviço ZeroTier." : error, true);
        emit stateChanged();
        return;
    }
    m_token = token;
    const QString operation = m_pendingOperation;
    if (operation == "status") request("GET", "/status", operation);
    else if (operation == "networks") request("GET", "/network", operation);
    else if (operation == "join") request("POST", "/network/" + m_pendingNetworkId, operation, "{}");
    else if (operation == "leave") request("DELETE", "/network/" + m_pendingNetworkId, operation);
}

void ZeroTierController::request(const QByteArray &method, const QString &path,
                                 const QString &operation, const QByteArray &body)
{
    m_operation = operation;
    QNetworkRequest request(QUrl("http://127.0.0.1:9993" + path));
    request.setRawHeader("X-ZT1-Auth", m_token.toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    QNetworkReply *reply = nullptr;
    if (method == "GET") reply = m_network.get(request);
    else if (method == "POST") reply = m_network.post(request, body);
    else reply = m_network.sendCustomRequest(request, method, body);
    connect(reply, &QNetworkReply::finished, this, &ZeroTierController::onApiReply);
}

void ZeroTierController::onApiReply()
{
    auto *reply = qobject_cast<QNetworkReply *>(sender());
    if (!reply) return;
    const QByteArray body = reply->readAll();
    const auto error = reply->error();
    const QString errorText = reply->errorString();
    const QString operation = m_operation;
    reply->deleteLater();

    if (error != QNetworkReply::NoError) {
        m_busy = false;
        if (operation == "status") m_serviceStatus = "Indisponível";
        setMessage("Não foi possível falar com o serviço ZeroTier: " + errorText, true);
        emit stateChanged();
        if (m_joinPollsRemaining > 0) m_networkPollTimer.start(2000);
        return;
    }

    const QJsonDocument json = QJsonDocument::fromJson(body);
    if (operation == "status") {
        const QJsonObject status = json.object();
        m_nodeId = status.value("address").toString("—");
        const bool online = status.value("online").toBool();
        m_serviceStatus = online ? "Online" : "Conectado · offline";
        request("GET", "/network", "networks");
        return;
    }
    if (operation == "networks") {
        updateNetworks(body);
        m_busy = false;
        m_lastUpdated = QDateTime::currentDateTime().toString("HH:mm");
        setMessage("Tudo atualizado");
        emit stateChanged();
        bool requestingConfiguration = false;
        for (const QVariant &network : m_networks) {
            if (network.toMap().value("status").toString() == "REQUESTING_CONFIGURATION") {
                requestingConfiguration = true;
                break;
            }
        }
        if (m_joinPollsRemaining > 0 && requestingConfiguration)
            m_networkPollTimer.start(2000);
        else {
            m_networkPollTimer.stop();
            m_joinPollsRemaining = 0;
        }
        return;
    }
    if (operation == "join" || operation == "leave") {
        if (operation == "join") {
            m_networkPollTimer.stop();
            m_joinPollsRemaining = 30;
        } else {
            m_networkPollTimer.stop();
            m_joinPollsRemaining = 0;
        }
        setMessage(operation == "join" ? "Pedido para entrar na rede enviado." : "Você saiu da rede.");
        m_pendingOperation = "status";
        request("GET", "/status", "status");
    }
}

void ZeroTierController::updateNetworks(const QByteArray &json)
{
    m_networks.clear();
    const QJsonArray array = QJsonDocument::fromJson(json).array();
    for (const QJsonValue &value : array) {
        const QJsonObject network = value.toObject();
        QStringList addresses;
        for (const QJsonValue &address : network.value("assignedAddresses").toArray())
            addresses.append(address.toString());
        const QString status = network.value("status").toString("UNKNOWN");
        m_networks.append(QVariantMap{
            {"id", network.value("id").toString()},
            {"name", network.value("name").toString()},
            {"status", status},
            {"type", network.value("type").toString("—")},
            {"address", addresses.isEmpty() ? QStringLiteral("Aguardando autorização") : addresses.join(", ")},
            {"connected", status == "OK"}
        });
    }
}

void ZeroTierController::setMessage(const QString &message, bool isError)
{
    m_message = message;
    m_messageIsError = isError;
}
