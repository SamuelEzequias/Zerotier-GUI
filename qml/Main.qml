import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 1280
    height: 820
    minimumWidth: 940
    minimumHeight: 680
    visible: true
    title: tr("ZeroTier — Central de Controle", "ZeroTier — Control Center")
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "#080d16"

    property color ink: "#eef5ff"
    property color muted: "#8291a8"
    property color panel: "#111a28"
    property color stroke: "#202f43"
    property color cyan: "#57dce8"
    property color blue: "#618cff"
    property bool english: appSettings.language === "en"
    property string currentPage: "overview"

    function tr(portuguese, englishText) {
        return english ? englishText : portuguese
    }

    function serviceStatusText() {
        if (!english) return zt.serviceStatus
        const translations = {
            "Verificando…": "Checking…",
            "Indisponível": "Unavailable",
            "Conectado · offline": "Connected · offline",
            "Online": "Online"
        }
        return translations[zt.serviceStatus] || zt.serviceStatus
    }

    function messageText() {
        if (!english) return zt.message
        const translations = {
            "Autorize o acesso ao ZeroTier uma vez nesta sessão…": "Authorize ZeroTier access once for this session…",
            "Digite um ID válido com 16 caracteres hexadecimais.": "Enter a valid 16-character hexadecimal ID.",
            "ID copiado para a área de transferência.": "ID copied to clipboard.",
            "Tudo atualizado": "Everything is up to date",
            "Pedido para entrar na rede enviado.": "Join request sent.",
            "Você saiu da rede.": "You left the network.",
            "É necessário ter o Polkit (pkexec) instalado para acessar o ZeroTier.": "Polkit (pkexec) must be installed to access ZeroTier.",
            "Não foi possível autorizar o acesso ao serviço ZeroTier.": "Could not authorize access to the ZeroTier service.",
            "Não foi possível abrir a autorização do sistema. Confira se o Polkit está instalado.": "Could not open system authorization. Check that Polkit is installed."
        }
        if (translations[zt.message] !== undefined) return translations[zt.message]
        const apiError = "Não foi possível falar com o serviço ZeroTier: "
        if (zt.message.indexOf(apiError) === 0)
            return "Could not reach the ZeroTier service: " + zt.message.substring(apiError.length)
        return zt.message
    }

    function networkAddress(address) {
        return english && address === "Aguardando autorização" ? "Waiting for authorization" : address
    }

    function networkStatusText(status) {
        const labels = {
            "REQUESTING_CONFIGURATION": tr("Solicitando configuração", "Requesting configuration"),
            "ACCESS_DENIED": tr("Acesso negado", "Access denied"),
            "NOT_FOUND": tr("Não encontrada", "Not found"),
            "PORT_ERROR": tr("Erro de porta", "Port error")
        }
        return labels[status] || status.replace("_", " ")
    }

    function joinNetwork() {
        if (networkIdInput.text.length !== 16 || zt.busy) return
        const networkId = networkIdInput.text
        zt.join(networkId)
        networkIdInput.clear()
    }

    function openTextContextMenu(field, mouseArea, mouse) {
        textContextMenu.targetField = field
        field.forceActiveFocus()
        const point = mouseArea.mapToItem(window.contentItem, mouse.x, mouse.y)
        textContextMenu.x = Math.max(8, Math.min(point.x, window.width - textContextMenu.width - 8))
        textContextMenu.y = Math.max(8, Math.min(point.y, window.height - textContextMenu.height - 8))
        textContextMenu.open()
    }

    background: Rectangle {
        color: window.color
        Rectangle {
            width: 580; height: 580; radius: 290
            x: window.width - 520; y: -330
            opacity: 0.16
            gradient: Gradient {
                GradientStop { position: 0; color: "#174a80" }
                GradientStop { position: 1; color: "#080d16" }
            }
        }
        Rectangle {
            width: 420; height: 420; radius: 210
            x: -290; y: window.height - 370
            opacity: 0.10
            gradient: Gradient {
                GradientStop { position: 0; color: "#0c8c9e" }
                GradientStop { position: 1; color: "#080d16" }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: 36
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 232
            color: "#0b121d"
            border.color: "#192638"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 19
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 11
                    Rectangle {
                        width: 38; height: 38; radius: 12
                        gradient: Gradient {
                            GradientStop { position: 0; color: window.cyan }
                            GradientStop { position: 1; color: window.blue }
                        }
                        Text { anchors.centerIn: parent; text: "Z"; color: "#07131e"; font.pixelSize: 18; font.bold: true }
                    }
                    Column {
                        spacing: 2
                        Text { text: "ZeroTier"; color: window.ink; font.pixelSize: 16; font.weight: Font.DemiBold }
                        Text { text: "CONTROL CENTER"; color: "#62748c"; font.pixelSize: 9; font.letterSpacing: 1.7; font.bold: true }
                    }
                }

                Item { Layout.preferredHeight: 39 }
                Text { text: tr("ESPAÇO DE TRABALHO", "WORKSPACE"); color: "#5d718a"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.7; leftPadding: 10 }
                Item { Layout.preferredHeight: 11 }

                NavItem {
                    label: tr("Visão geral", "Overview"); icon: "◈"; selected: currentPage === "overview"
                    onClicked: { currentPage = "overview"; zt.refresh() }
                }
                NavItem {
                    label: tr("Configurações", "Settings"); icon: "⚙"; selected: currentPage === "settings"
                    onClicked: currentPage = "settings"
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 146
                    radius: 15
                    color: "#101b2a"
                    border.color: "#20334a"
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 9
                        RowLayout {
                            spacing: 7
                            Rectangle { width: 7; height: 7; radius: 4; color: zt.serviceStatus === "Online" ? "#55e0b0" : "#edbd67" }
                            Text { text: tr("SERVIÇO LOCAL", "LOCAL SERVICE"); color: "#7f92aa"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.2 }
                        }
                        Text { text: "ZeroTier One"; color: window.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Text {
                            text: zt.serviceStatus === "Online" ? tr("Túnel seguro pronto", "Secure tunnel ready") : serviceStatusText()
                            color: window.muted; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }
                        Item { Layout.fillHeight: true }
                        Text { text: tr("v1  /  Nó desktop", "v1  /  Desktop node"); color: "#5d718a"; font.pixelSize: 10 }
                    }
                }
            }
        }

        Item {
            id: mainContent
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 34
            Layout.rightMargin: 34
            Layout.topMargin: 26
            Layout.bottomMargin: 22

            ColumnLayout {
                anchors.fill: parent
                spacing: 17
                visible: currentPage === "overview"

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 5
                        Text { text: tr("PAINEL DE REDE", "NETWORK DASHBOARD"); color: window.cyan; font.pixelSize: 9; font.bold: true; font.letterSpacing: 2.2 }
                        Text { text: tr("Sua rede. Sob controle.", "Your network. In control."); color: window.ink; font.pixelSize: 29; font.weight: Font.DemiBold; font.letterSpacing: -0.7 }
                        Text { text: tr("Tudo o que acontece no seu nó ZeroTier, em um só lugar.", "Everything happening on your ZeroTier node, in one place."); color: window.muted; font.pixelSize: 12 }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        visible: zt.demoMode
                        Layout.preferredWidth: 105; Layout.preferredHeight: 34; radius: 10
                        color: "#172b3d"; border.color: "#3c7990"
                        Text { anchors.centerIn: parent; text: tr("DADOS DEMO", "DEMO DATA"); color: window.cyan; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                    }
                    Rectangle {
                        id: refreshButton
                        Layout.preferredWidth: 138; Layout.preferredHeight: 42; radius: 12
                        color: refreshMouse.containsMouse ? "#1a2a40" : "#111c2a"
                        border.color: refreshMouse.containsMouse ? "#355477" : window.stroke
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on border.color { ColorAnimation { duration: 130 } }
                        scale: refreshMouse.pressed ? 0.96 : refreshMouse.containsMouse ? 1.035 : 1
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        Row { anchors.centerIn: parent; spacing: 8
                            Item {
                                width: 20; height: 22
                                anchors.verticalCenter: parent.verticalCenter
                                Text { id: refreshIcon; anchors.fill: parent; text: "↻"; color: window.cyan; font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                RotationAnimation { id: refreshSpin; target: refreshIcon; from: 0; to: 360; duration: 650; easing.type: Easing.OutCubic; onStopped: refreshIcon.rotation = 0 }
                            }
                            Text {
                                height: 22
                                text: tr("Atualizar", "Refresh"); color: "#c5d2e2"; font.pixelSize: 11; font.weight: Font.DemiBold
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { refreshSpin.restart(); zt.refresh() } }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 170
                    radius: 18
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#142b42" }
                        GradientStop { position: 0.58; color: "#122033" }
                        GradientStop { position: 1; color: "#111a28" }
                    }
                    border.color: "#29435e"
                    Rectangle {
                        width: 300; height: 300; radius: 150
                        x: parent.width - 215; y: -102
                        color: "transparent"; border.color: "#2c6681"; border.width: 1; opacity: 0.28
                    }
                    Rectangle {
                        width: 222; height: 222; radius: 111
                        x: parent.width - 176; y: -63
                        color: "transparent"; border.color: "#397e9d"; border.width: 1; opacity: 0.25
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24; anchors.rightMargin: 24
                        ColumnLayout {
                            spacing: 12
                            RowLayout {
                                spacing: 8
                                Rectangle { width: 8; height: 8; radius: 4; color: zt.serviceStatus === "Online" ? "#5be3b2" : "#efbd68"
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.45; duration: 950 }
                                        NumberAnimation { to: 1; duration: 950 }
                                    }
                                }
                                Text { text: zt.serviceStatus === "Online" ? tr("NÓ ONLINE", "NODE ONLINE") : tr("STATUS DO NÓ", "NODE STATUS"); color: "#9bb4cb"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.8 }
                            }
                            Text { text: zt.serviceStatus === "Online" ? tr("Conectado à rede global.", "Connected to the global network.") : serviceStatusText(); color: "#f3f8ff"; font.pixelSize: 23; font.weight: Font.DemiBold }
                            Text { text: tr("Seu dispositivo está pronto para trocar tráfego com seus peers.", "Your device is ready to exchange traffic with its peers."); color: "#9aacc0"; font.pixelSize: 11 }
                            Item { Layout.preferredHeight: 1 }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredWidth: 264; Layout.preferredHeight: 86
                            color: "#101b2a"; opacity: 0.82; radius: 14; border.color: "#2b4058"
                            scale: copyMouse.containsMouse ? 1.025 : 1
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Column {
                                anchors.fill: parent; anchors.margins: 14; spacing: 7
                                Text { text: tr("IDENTIDADE DESTE NÓ", "THIS NODE'S IDENTITY"); color: "#8094ac"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.2 }
                                Row {
                                    spacing: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: 8
                                    Text { text: zt.nodeId; color: window.cyan; font.pixelSize: 17; font.family: "monospace"; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                                    Rectangle {
                                        width: 31; height: 31; radius: 9
                                        color: copyMouse.containsMouse ? "#203a52" : "#17283b"
                                        border.color: copyMouse.containsMouse ? "#4bb2c6" : "#2a4058"
                                        scale: copyMouse.pressed ? 0.91 : copyMouse.containsMouse ? 1.08 : 1
                                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Text { anchors.centerIn: parent; text: "⧉"; color: copyMouse.containsMouse ? window.cyan : "#91a6bc"; font.pixelSize: 15 }
                                        MouseArea { id: copyMouse; anchors.fill: parent; hoverEnabled: true; onClicked: zt.copyToClipboard(zt.nodeId) }
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74
                    spacing: 13
                    StatCard { Layout.fillWidth: true; title: tr("REDES CONECTADAS", "CONNECTED NETWORKS"); value: zt.networks.length.toString().padStart(2, "0"); caption: zt.networks.length === 1 ? tr("1 túnel configurado", "1 configured tunnel") : tr(zt.networks.length + " túneis configurados", zt.networks.length + " configured tunnels"); accent: window.cyan; glyph: "▦" }
                    StatCard { Layout.fillWidth: true; title: tr("ESTADO DO SERVIÇO", "SERVICE STATUS"); value: zt.serviceStatus === "Online" ? tr("Estável", "Stable") : serviceStatusText(); caption: tr("Atualizado às ", "Updated at ") + (zt.lastUpdated || "—"); accent: "#72a4ff"; glyph: "⌁" }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 170
                    radius: 17
                    color: "#101824"
                    border.color: window.stroke
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 17
                        spacing: 12
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout { spacing: 3
                                Text { text: tr("Suas redes", "Your networks"); color: window.ink; font.pixelSize: 15; font.weight: Font.DemiBold }
                                Text { text: tr("Visão em tempo real das conexões deste dispositivo", "Real-time view of this device's connections"); color: window.muted; font.pixelSize: 10 }
                            }
                            Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredWidth: 214; Layout.preferredHeight: 35; radius: 10
                            color: "#0b121c"; border.color: networkSearch.activeFocus ? "#397da0" : "#233247"
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                            scale: networkSearch.activeFocus ? 1.015 : 1
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                RowLayout { anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 6
                                    Item {
                                        Layout.preferredWidth: 18
                                        Layout.fillHeight: true
                                        Text {
                                            anchors.centerIn: parent
                                            text: "⌕"; color: "#7388a2"; font.pixelSize: 16
                                        }
                                    }
                                    TextField {
                                        id: networkSearch; Layout.fillWidth: true
                                        placeholderText: tr("Filtrar redes", "Filter networks"); color: window.ink; font.pixelSize: 10
                                        placeholderTextColor: "#667991"; background: null
                                        selectByMouse: true
                                    }
                                    Text { text: "×"; visible: networkSearch.text.length > 0; color: "#8fa2b8"; font.pixelSize: 16
                                        MouseArea { anchors.fill: parent; onClicked: networkSearch.clear() }
                                    }
                                }
                                MouseArea {
                                    id: networkSearchContextMouse
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: (mouse) => window.openTextContextMenu(networkSearch, networkSearchContextMouse, mouse)
                                }
                            }
                        }
                        Item {
                            Layout.fillWidth: true; Layout.preferredHeight: 14
                            Text { x: 10; width: networkList.statusColumnX - x; text: tr("REDE / ID", "NETWORK / ID"); color: "#657992"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                            Text { x: networkList.statusColumnX; width: networkList.statusColumnWidth; horizontalAlignment: Text.AlignHCenter; text: tr("STATUS", "STATUS"); color: "#657992"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                            Text { visible: !networkList.compactMode; x: networkList.addressColumnX; width: networkList.addressColumnWidth; text: tr("ENDEREÇO", "ADDRESS"); color: "#657992"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                            Text { visible: !networkList.compactMode; x: networkList.typeColumnX; width: networkList.typeColumnWidth; horizontalAlignment: Text.AlignHCenter; text: tr("TIPO", "TYPE"); color: "#657992"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                        }
                        Rectangle { Layout.fillWidth: true; height: 1; color: "#1d2a3b" }
                        ListView {
                            id: networkList
                            Layout.fillWidth: true; Layout.fillHeight: true
                            clip: true; spacing: 4
                            property bool compactMode: width < 760
                            property real statusColumnWidth: Math.min(154, Math.max(116, width - 559))
                            property real addressColumnWidth: 250
                            property real typeColumnWidth: 82
                            property real actionColumnWidth: 29
                            property real columnGap: 8
                            // Match the visible header spacing of ENDEREÇO → TIPO.
                            // Keep a compact fallback when the window is narrow.
                            property real statusAddressGap: Math.max(52, Math.min(170, width - 700))
                            property real statusColumnX: compactMode
                                ? Math.min(width - actionColumnWidth - statusColumnWidth - 34, Math.max(180, width * 0.43))
                                : width - 10 - actionColumnWidth - columnGap - typeColumnWidth - columnGap - addressColumnWidth - statusAddressGap - statusColumnWidth
                            property real addressColumnX: statusColumnX + statusColumnWidth + statusAddressGap
                            property real typeColumnX: addressColumnX + addressColumnWidth + columnGap
                            property real actionColumnX: compactMode ? width - 10 - actionColumnWidth : typeColumnX + typeColumnWidth + columnGap
                            model: zt.networks.filter(function(item) { return (item.name + item.id).toLowerCase().includes(networkSearch.text.toLowerCase()) })
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                            delegate: Rectangle {
                                required property var modelData
                                width: networkList.width; height: 54; radius: 9
                                color: rowMouse.containsMouse ? "#152235" : "transparent"
                                border.color: rowMouse.containsMouse ? "#223a56" : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Item {
                                    anchors.fill: parent
                                    Column {
                                        x: 10; width: networkList.statusColumnX - x; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                        Text { width: parent.width; text: modelData.name || modelData.id; color: window.ink; font.pixelSize: 11; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                        Text { width: parent.width; text: modelData.id; color: "#71849c"; font.pixelSize: 9; font.family: "monospace" }
                                    }
                                    Rectangle {
                                        x: networkList.statusColumnX; width: networkList.statusColumnWidth; height: 25; anchors.verticalCenter: parent.verticalCenter; radius: 8
                                        color: modelData.connected ? "#102c2b" : "#2b241b"
                                        clip: true
                                        Row { anchors.centerIn: parent; spacing: 6
                                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; radius: 3; color: modelData.connected ? "#55dbac" : "#e9b968" }
                                            Text { width: Math.max(0, networkList.statusColumnWidth - 23); text: networkStatusText(modelData.status); color: modelData.connected ? "#70dfb9" : "#e8c27f"; font.pixelSize: 9; font.bold: true; elide: Text.ElideRight }
                                        }
                                    }
                                    Text { visible: !networkList.compactMode; x: networkList.addressColumnX; width: networkList.addressColumnWidth; anchors.verticalCenter: parent.verticalCenter; text: networkAddress(modelData.address); color: "#a9b7c8"; font.pixelSize: 10; elide: Text.ElideRight }
                                    Text { visible: !networkList.compactMode; x: networkList.typeColumnX; width: networkList.typeColumnWidth; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: modelData.type; color: "#a9b7c8"; font.pixelSize: 10 }
                                    Rectangle {
                                        x: networkList.actionColumnX; width: networkList.actionColumnWidth; height: 29; anchors.verticalCenter: parent.verticalCenter; radius: 8
                                        color: deleteMouse.containsMouse ? "#3a202b" : "transparent"
                                        scale: deleteMouse.pressed ? 0.9 : deleteMouse.containsMouse ? 1.08 : 1
                                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Text { anchors.centerIn: parent; text: "⌫"; color: deleteMouse.containsMouse ? "#ff8f9c" : "#71849c"; font.pixelSize: 15; rotation: deleteMouse.containsMouse ? -8 : 0; Behavior on rotation { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } } }
                                        MouseArea { id: deleteMouse; anchors.fill: parent; hoverEnabled: true; enabled: !zt.demoMode; onClicked: { leaveDialog.networkId = modelData.id; leaveDialog.networkName = modelData.name || modelData.id; leaveDialog.open() } }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: (mouse) => {
                                        networkContextMenu.selectedNetworkId = modelData.id
                                        networkContextMenu.selectedNetworkName = modelData.name || modelData.id
                                        networkContextMenu.selectedIp = modelData.address.indexOf("/") >= 0 ? modelData.address.split(",")[0].split("/")[0] : ""
                                        const point = mapToItem(window.contentItem, mouse.x, mouse.y)
                                        networkContextMenu.x = Math.max(8, Math.min(point.x, window.width - networkContextMenu.width - 8))
                                        networkContextMenu.y = Math.max(8, Math.min(point.y, window.height - networkContextMenu.height - 8))
                                        networkContextMenu.open()
                                    }
                                }
                                MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true; z: -1 }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: networkList.count === 0
                                text: networkSearch.text.length ? tr("Nenhuma rede corresponde ao filtro.", "No networks match your search.") : tr("Ainda sem redes — conecte-se pelo campo abaixo.", "No networks yet — join one below.")
                                color: "#73869d"; font.pixelSize: 11
                            }
                        }
                    }
                }

                Rectangle {
                    id: joinNetworkCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: compactMode ? 132 : 83
                    property bool compactMode: width < 760
                    radius: 16
                    color: "#111b29"
                    border.color: "#263b53"
                    Rectangle { x: 17; y: joinNetworkCard.compactMode ? 12 : (parent.height - height) / 2; width: 37; height: 37; radius: 11; color: "#163044"
                        Text { anchors.centerIn: parent; text: "＋"; color: window.cyan; font.pixelSize: 20 }
                    }
                    Column {
                        x: 67; y: joinNetworkCard.compactMode ? 10 : (parent.height - height) / 2; width: joinNetworkCard.compactMode ? parent.width - 82 : 340; spacing: 3
                        Text { text: tr("Entrar em uma rede", "Join a network"); color: window.ink; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Text { width: parent.width; text: tr("Cole o ID de 16 caracteres para conectar este dispositivo", "Paste a 16-character ID to connect this device"); color: window.muted; font.pixelSize: 9; elide: Text.ElideRight }
                    }
                    Rectangle {
                        x: joinNetworkCard.compactMode ? 17 : parent.width - 438
                        y: joinNetworkCard.compactMode ? 76 : (parent.height - height) / 2
                        width: joinNetworkCard.compactMode ? parent.width - 185 : 270; height: 41; radius: 10
                        color: "#0a121d"; border.color: networkIdInput.activeFocus ? "#4ba9be" : "#2a3c52"
                        Behavior on border.color { ColorAnimation { duration: 130 } }
                        scale: networkIdInput.activeFocus ? 1.012 : 1
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        TextField {
                            id: networkIdInput
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10
                            placeholderText: "0000000000000000"
                            color: window.ink; placeholderTextColor: "#52677f"
                            font.pixelSize: 12; font.family: "monospace"
                            maximumLength: 16; selectByMouse: true
                            validator: RegularExpressionValidator { regularExpression: /^[0-9a-fA-F]{0,16}$/ }
                            background: null
                            onAccepted: window.joinNetwork()
                        }
                        MouseArea {
                            id: networkIdContextMouse
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: (mouse) => window.openTextContextMenu(networkIdInput, networkIdContextMouse, mouse)
                        }
                    }
                    Rectangle {
                        id: joinButton
                        x: parent.width - width - 13
                        y: joinNetworkCard.compactMode ? 76 : (parent.height - height) / 2
                        width: 142; height: 41; radius: 10
                        opacity: networkIdInput.text.length === 16 && !zt.busy && !zt.demoMode ? 1 : 0.45
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#4fd6e1" }
                            GradientStop { position: 1; color: "#6f9dff" }
                        }
                        scale: joinMouse.pressed ? 0.96 : joinMouse.containsMouse && joinMouse.enabled ? 1.04 : 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        Text { anchors.centerIn: parent; text: zt.busy ? tr("Conectando…", "Connecting…") : tr("Conectar", "Connect"); color: "#07131f"; font.pixelSize: 10; font.bold: true }
                        MouseArea { id: joinMouse; anchors.fill: parent; enabled: networkIdInput.text.length === 16 && !zt.busy && !zt.demoMode; onClicked: window.joinNetwork() }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: zt.message ? messageText() : tr("Conexão local segura · dados mantidos no seu dispositivo", "Secure local connection · data stays on your device"); color: zt.messageIsError ? "#ff8793" : "#60748c"; font.pixelSize: 9; elide: Text.ElideRight }
                    Text { text: tr("API LOCAL", "LOCAL API") + "  ·  127.0.0.1"; color: "#445a73"; font.pixelSize: 8; font.letterSpacing: 1.2 }
                }
            }

        ColumnLayout {
            anchors.fill: parent
            spacing: 18
            visible: currentPage === "settings"

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text { text: tr("PREFERÊNCIAS", "PREFERENCES"); color: window.cyan; font.pixelSize: 9; font.bold: true; font.letterSpacing: 2.2 }
                Text { text: tr("Configurações", "Settings"); color: window.ink; font.pixelSize: 29; font.weight: Font.DemiBold; font.letterSpacing: -0.7 }
                Text { text: tr("Personalize sua experiência no ZeroTier Control Center.", "Personalize your ZeroTier Control Center experience."); color: window.muted; font.pixelSize: 12 }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 196
                radius: 17
                color: "#101824"
                border.color: window.stroke

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 18

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 13
                        Rectangle {
                            Layout.preferredWidth: 42; Layout.preferredHeight: 42; radius: 12
                            color: "#142b40"; border.color: "#254660"
                            Text { anchors.centerIn: parent; text: "文A"; color: window.cyan; font.pixelSize: 16; font.weight: Font.DemiBold }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: tr("Idioma da interface", "Interface language"); color: window.ink; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Text { text: tr("Escolha o idioma usado nos menus e mensagens.", "Choose the language used in menus and messages."); color: window.muted; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#1d2a3b" }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: tr("Idioma", "Language"); color: "#aab9ca"; font.pixelSize: 11; font.weight: Font.DemiBold }
                        Row {
                            spacing: 7
                            Rectangle {
                                width: 112; height: 38; radius: 10
                                color: !english ? "#183247" : "#0b121c"
                                border.color: !english ? "#3a8095" : "#26364a"
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                scale: portugueseLanguageMouse.pressed ? 0.96 : portugueseLanguageMouse.containsMouse ? 1.035 : 1
                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                                Row {
                                    anchors.centerIn: parent; spacing: 8
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "PT"; color: !english ? window.cyan : "#72849a"; font.pixelSize: 9; font.bold: true }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Português"; color: !english ? "#d8f6f7" : "#9aaabd"; font.pixelSize: 10; font.weight: Font.DemiBold }
                                }
                                MouseArea { id: portugueseLanguageMouse; anchors.fill: parent; hoverEnabled: true; onClicked: appSettings.language = "pt" }
                            }
                            Rectangle {
                                width: 100; height: 38; radius: 10
                                color: english ? "#183247" : "#0b121c"
                                border.color: english ? "#3a8095" : "#26364a"
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                scale: englishLanguageMouse.pressed ? 0.96 : englishLanguageMouse.containsMouse ? 1.035 : 1
                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                                Row {
                                    anchors.centerIn: parent; spacing: 8
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "EN"; color: english ? window.cyan : "#72849a"; font.pixelSize: 9; font.bold: true }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "English"; color: english ? "#d8f6f7" : "#9aaabd"; font.pixelSize: 10; font.weight: Font.DemiBold }
                                }
                                MouseArea { id: englishLanguageMouse; anchors.fill: parent; hoverEnabled: true; onClicked: appSettings.language = "en" }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
            Text { text: tr("A alteração é aplicada na hora e salva neste dispositivo.", "Changes apply immediately and are saved on this device."); color: "#60748c"; font.pixelSize: 10 }
        }
        }
    }

    Rectangle {
        id: titleBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 36
        z: 100
        color: "#0b121d"
        border.color: "#192638"

        MouseArea {
            id: titleBarDrag
            anchors.left: parent.left
            anchors.right: titleBarControls.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            acceptedButtons: Qt.LeftButton
            property real pressX: 0
            property real pressY: 0
            property bool moveStarted: false
            onPressed: (mouse) => { pressX = mouse.x; pressY = mouse.y; moveStarted = false }
            onPositionChanged: (mouse) => {
                if (pressed && !moveStarted && (Math.abs(mouse.x - pressX) + Math.abs(mouse.y - pressY)) > 6) {
                    moveStarted = true
                    window.startSystemMove()
                }
            }
            onDoubleClicked: {
                if (window.visibility === Window.Maximized) window.showNormal()
                else window.showMaximized()
            }
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9
            Rectangle {
                width: 21; height: 21; radius: 7
                gradient: Gradient {
                    GradientStop { position: 0; color: window.cyan }
                    GradientStop { position: 1; color: window.blue }
                }
                Text { anchors.centerIn: parent; text: "Z"; color: "#07131e"; font.pixelSize: 12; font.bold: true }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "ZeroTier"
                color: "#bccbdd"
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "CONTROL CENTER"
                color: "#60748c"
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1.2
            }
        }

        Row {
            id: titleBarControls
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height

            Rectangle {
                width: 44; height: parent.height
                color: minimizeMouse.containsMouse ? "#1a2738" : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "−"; color: "#a8b8ca"; font.pixelSize: 15 }
                MouseArea { id: minimizeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: window.showMinimized() }
            }
            Rectangle {
                width: 44; height: parent.height
                color: maximizeMouse.containsMouse ? "#1a2738" : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: window.visibility === Window.Maximized ? "❐" : "□"; color: "#a8b8ca"; font.pixelSize: 12 }
                MouseArea {
                    id: maximizeMouse; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (window.visibility === Window.Maximized) window.showNormal()
                        else window.showMaximized()
                    }
                }
            }
            Rectangle {
                width: 46; height: parent.height
                color: closeMouse.containsMouse ? "#c84359" : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "×"; color: closeMouse.containsMouse ? "white" : "#a8b8ca"; font.pixelSize: 17 }
                MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: window.close() }
            }
        }
    }

    MouseArea {
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 5; z: 101; acceptedButtons: Qt.LeftButton; cursorShape: Qt.SizeHorCursor
        onPressed: window.startSystemResize(Qt.LeftEdge)
    }
    MouseArea {
        anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 5; z: 101; acceptedButtons: Qt.LeftButton; cursorShape: Qt.SizeHorCursor
        onPressed: window.startSystemResize(Qt.RightEdge)
    }
    MouseArea {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 5; z: 101; acceptedButtons: Qt.LeftButton; cursorShape: Qt.SizeVerCursor
        onPressed: window.startSystemResize(Qt.TopEdge)
    }
    MouseArea {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 5; z: 101; acceptedButtons: Qt.LeftButton; cursorShape: Qt.SizeVerCursor
        onPressed: window.startSystemResize(Qt.BottomEdge)
    }

    Popup {
        id: networkContextMenu
        parent: Overlay.overlay
        property string selectedNetworkId: ""
        property string selectedNetworkName: ""
        property string selectedIp: ""
        padding: 6
        width: 184; height: 137
        background: Rectangle { radius: 12; color: "#111b29"; border.color: "#30445d" }
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 110 }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 140; easing.type: Easing.OutCubic }
        }
        exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 90 } }
        contentItem: Column {
            spacing: 3
            Rectangle {
                width: 170; height: 37; radius: 8
                color: copyIpMouse.containsMouse ? "#1a2b3f" : "transparent"
                opacity: networkContextMenu.selectedIp.length > 0 ? 1 : 0.45
                scale: copyIpMouse.pressed ? 0.97 : copyIpMouse.containsMouse ? 1.015 : 1
                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 100 } }
                Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 9
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "⧉"; color: "#62d4e0"; font.pixelSize: 13 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: tr("Copiar IP", "Copy IP"); color: "#d9e4f1"; font.pixelSize: 11; font.weight: Font.DemiBold }
                }
                MouseArea { id: copyIpMouse; anchors.fill: parent; hoverEnabled: true; enabled: networkContextMenu.selectedIp.length > 0
                    onClicked: { zt.copyToClipboard(networkContextMenu.selectedIp); networkContextMenu.close() }
                }
            }
            Rectangle { width: 170; height: 1; color: "#26364a" }
            Rectangle {
                width: 170; height: 37; radius: 8
                color: copyNetworkIdMouse.containsMouse ? "#1a2b3f" : "transparent"
                scale: copyNetworkIdMouse.pressed ? 0.97 : copyNetworkIdMouse.containsMouse ? 1.015 : 1
                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 100 } }
                Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 9
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "⧉"; color: "#62d4e0"; font.pixelSize: 13 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: tr("Copiar ID da rede", "Copy network ID"); color: "#d9e4f1"; font.pixelSize: 11; font.weight: Font.DemiBold }
                }
                MouseArea { id: copyNetworkIdMouse; anchors.fill: parent; hoverEnabled: true
                    onClicked: { zt.copyToClipboard(networkContextMenu.selectedNetworkId); networkContextMenu.close() }
                }
            }
            Rectangle { width: 170; height: 1; color: "#26364a" }
            Rectangle {
                width: 170; height: 37; radius: 8
                color: leaveNetworkMouse.containsMouse ? "#3a202b" : "transparent"
                scale: leaveNetworkMouse.pressed ? 0.97 : leaveNetworkMouse.containsMouse ? 1.015 : 1
                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 100 } }
                Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 9
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "⏻"; color: "#ff8793"; font.pixelSize: 13 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: tr("Sair da rede", "Leave network"); color: "#ff8793"; font.pixelSize: 11; font.weight: Font.DemiBold }
                }
                opacity: zt.demoMode ? 0.45 : 1
                MouseArea { id: leaveNetworkMouse; anchors.fill: parent; hoverEnabled: true; enabled: !zt.demoMode
                    onClicked: { leaveDialog.networkId = networkContextMenu.selectedNetworkId; leaveDialog.networkName = networkContextMenu.selectedNetworkName; networkContextMenu.close(); leaveDialog.open() }
                }
            }
        }
    }

    Popup {
        id: textContextMenu
        parent: Overlay.overlay
        property var targetField: null
        padding: 6
        width: 218
        height: 252
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: 12; color: "#111b29"; border.color: "#30445d" }
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 110 }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 140; easing.type: Easing.OutCubic }
        }
        exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 90 } }
        contentItem: Column {
            spacing: 2
            ContextAction {
                glyph: "↶"; label: tr("Desfazer", "Undo")
                actionEnabled: textContextMenu.targetField && textContextMenu.targetField.enabled && !textContextMenu.targetField.readOnly && textContextMenu.targetField.canUndo
                onTriggered: { textContextMenu.targetField.undo(); textContextMenu.close() }
            }
            ContextAction {
                glyph: "↷"; label: tr("Refazer", "Redo")
                actionEnabled: textContextMenu.targetField && textContextMenu.targetField.enabled && !textContextMenu.targetField.readOnly && textContextMenu.targetField.canRedo
                onTriggered: { textContextMenu.targetField.redo(); textContextMenu.close() }
            }
            Rectangle { width: 202; height: 1; color: "#26364a" }
            ContextAction {
                glyph: "✂"; label: tr("Recortar", "Cut")
                actionEnabled: textContextMenu.targetField && textContextMenu.targetField.enabled && !textContextMenu.targetField.readOnly && textContextMenu.targetField.selectionStart !== textContextMenu.targetField.selectionEnd
                onTriggered: { textContextMenu.targetField.cut(); textContextMenu.close() }
            }
            ContextAction {
                glyph: "⧉"; label: tr("Copiar", "Copy")
                actionEnabled: textContextMenu.targetField && textContextMenu.targetField.enabled && textContextMenu.targetField.selectionStart !== textContextMenu.targetField.selectionEnd
                onTriggered: { textContextMenu.targetField.copy(); textContextMenu.close() }
            }
            ContextAction {
                glyph: "▤"; label: tr("Colar", "Paste")
                actionEnabled: textContextMenu.targetField && textContextMenu.targetField.enabled && !textContextMenu.targetField.readOnly
                onTriggered: { textContextMenu.targetField.paste(); textContextMenu.close() }
            }
            Rectangle { width: 202; height: 1; color: "#26364a" }
            ContextAction {
                glyph: "⌫"; label: tr("Excluir", "Delete"); destructive: true
                actionEnabled: textContextMenu.targetField && textContextMenu.targetField.enabled && !textContextMenu.targetField.readOnly && textContextMenu.targetField.selectionStart !== textContextMenu.targetField.selectionEnd
                onTriggered: {
                    textContextMenu.targetField.remove(textContextMenu.targetField.selectionStart, textContextMenu.targetField.selectionEnd)
                    textContextMenu.close()
                }
            }
            ContextAction {
                glyph: "▧"; label: tr("Selecionar tudo", "Select All")
                actionEnabled: textContextMenu.targetField && textContextMenu.targetField.enabled && textContextMenu.targetField.text.length > 0
                onTriggered: { textContextMenu.targetField.selectAll(); textContextMenu.close() }
            }
        }
    }

    Dialog {
        id: leaveDialog
        property string networkId: ""
        property string networkName: ""
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 430
        height: 276
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: "#bd050a12" }
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
            NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: 190; easing.type: Easing.OutBack }
        }
        exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 110 } }
        background: Rectangle {
            radius: 20
            color: "#111a28"
            border.color: "#34465c"
        }
        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 23
            spacing: 0
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 47
                Rectangle {
                    x: 0; y: 0; width: 47; height: 47; radius: 14
                    color: "#321d2a"; border.color: "#683447"
                    Rectangle {
                        anchors.centerIn: parent
                        width: 42; height: 42; radius: 14
                        color: "transparent"; border.color: "#eb6279"; opacity: 0
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 650 }
                            NumberAnimation { to: 0; duration: 850 }
                        }
                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.45; duration: 1500; easing.type: Easing.OutCubic }
                            PropertyAction { value: 1 }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (parent.height - height) / 2 + 2
                        width: 33; height: 33
                        text: "⏻"; color: "#ff8a9a"; font.pixelSize: 21
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        font.family: "DejaVu Sans"
                    }
                }
                ColumnLayout {
                    x: 60; width: parent.width - 112
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text { Layout.fillWidth: true; text: tr("Desconectar da rede?", "Leave this network?"); color: window.ink; font.pixelSize: 17; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    Text { text: tr("CONFIRMAÇÃO DE AÇÃO", "ACTION CONFIRMATION"); color: "#c67787"; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1.5 }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: 31; height: 31; radius: 9
                    color: closeDialogMouse.containsMouse ? "#263346" : "transparent"
                    scale: closeDialogMouse.pressed ? 0.9 : closeDialogMouse.containsMouse ? 1.08 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "×"; color: closeDialogMouse.containsMouse ? "#e0e9f4" : "#93a3b7"; font.pixelSize: 18; rotation: closeDialogMouse.containsMouse ? 90 : 0; Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
                    MouseArea { id: closeDialogMouse; anchors.fill: parent; hoverEnabled: true; onClicked: leaveDialog.close() }
                }
            }
            Item { Layout.preferredHeight: 20 }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 65; radius: 12
                color: "#0b131f"; border.color: "#26364a"
                ColumnLayout { anchors.fill: parent; anchors.leftMargin: 13; anchors.rightMargin: 13; anchors.topMargin: 11; anchors.bottomMargin: 11; spacing: 5
                    Text { text: leaveDialog.networkName || leaveDialog.networkId; color: "#e3edf8"; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                    Text { text: leaveDialog.networkId; color: "#8195ad"; font.pixelSize: 10; font.family: "monospace" }
                }
            }
            Item { Layout.preferredHeight: 12 }
            Text {
                Layout.fillWidth: true
                text: tr("Este dispositivo perderá o acesso aos endereços e serviços disponíveis nesta rede.", "This device will lose access to the addresses and services available on this network.")
                color: "#a7b6c8"; font.pixelSize: 11; wrapMode: Text.WordWrap
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true
                spacing: 9
                Item { Layout.fillWidth: true }
                Button {
                    id: cancelLeaveButton
                    Layout.preferredWidth: 112; Layout.preferredHeight: 39
                    text: tr("Cancelar", "Cancel")
                    contentItem: Text { text: cancelLeaveButton.text; color: "#c3d0df"; font.pixelSize: 10; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle {
                        radius: 10; color: cancelLeaveButton.down ? "#1d2d42" : cancelLeaveButton.hovered ? "#19283a" : "#141f2e"
                        border.color: cancelLeaveButton.hovered ? "#405570" : "#2b3b50"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    scale: down ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                    onClicked: leaveDialog.close()
                }
                Button {
                    id: confirmLeaveButton
                    Layout.preferredWidth: 150; Layout.preferredHeight: 39
                    text: tr("Sair da rede", "Leave network")
                    contentItem: Item {
                        Text {
                            anchors.fill: parent
                            text: confirmLeaveButton.text
                            color: "#fff0f2"; font.pixelSize: 10; font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                    }
                    background: Rectangle {
                        radius: 10
                        border.width: confirmLeaveButton.hovered ? 1 : 0
                        gradient: Gradient {
                            GradientStop { position: 0; color: confirmLeaveButton.down ? "#bd4058" : confirmLeaveButton.hovered ? "#ef657c" : "#d65069" }
                            GradientStop { position: 1; color: confirmLeaveButton.down ? "#92354e" : confirmLeaveButton.hovered ? "#d65370" : "#bb435f" }
                        }
                        border.color: "#ee7183"
                        Behavior on border.width { NumberAnimation { duration: 120 } }
                    }
                    scale: down ? 0.97 : hovered ? 1.025 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    onClicked: { zt.leave(leaveDialog.networkId); leaveDialog.close() }
                }
            }
        }
    }

    component NavItem: Rectangle {
        required property string label
        required property string icon
        property bool selected: false
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredHeight: 41
        radius: 10
        color: selected ? "#142a40" : navMouse.containsMouse ? "#111e2d" : "transparent"
        border.color: selected ? "#244861" : "transparent"
        Row { anchors.fill: parent; anchors.leftMargin: 12; spacing: 11
            Text { anchors.verticalCenter: parent.verticalCenter; text: icon; color: selected ? window.cyan : "#8396ad"; font.pixelSize: 14 }
            Text { anchors.verticalCenter: parent.verticalCenter; text: label; color: selected ? "#c3f3f6" : "#a0afc1"; font.pixelSize: 11; font.weight: selected ? Font.DemiBold : Font.Normal }
        }
        Rectangle { visible: selected; width: 2; height: 20; radius: 1; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; color: window.cyan }
        MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
        Behavior on color { ColorAnimation { duration: 130 } }
    }

    component ContextAction: Rectangle {
        required property string glyph
        required property string label
        required property bool actionEnabled
        property bool destructive: false
        signal triggered()
        width: 202
        height: 30
        radius: 8
        opacity: actionEnabled ? 1 : 0.4
        color: actionMouse.containsMouse && actionEnabled
               ? (destructive ? "#3a202b" : "#1a2b3f")
               : "transparent"
        scale: actionMouse.pressed && actionEnabled ? 0.975 : actionMouse.containsMouse && actionEnabled ? 1.012 : 1
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 100 } }
        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            spacing: 10
            Text {
                width: 15; height: parent.height
                text: glyph
                color: destructive ? "#ff8793" : (actionEnabled ? "#62d4e0" : "#687b91")
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                height: parent.height
                text: label
                color: destructive ? "#ff8793" : (actionEnabled ? "#d9e4f1" : "#74869b")
                font.pixelSize: 10
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }
        }
        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: actionEnabled
            onClicked: parent.triggered()
        }
    }

    component StatCard: Rectangle {
        required property string title
        required property string value
        required property string caption
        required property color accent
        required property string glyph
        Layout.preferredHeight: 74
        radius: 14
        color: "#111a27"
        border.color: window.stroke
        Rectangle { width: 3; height: 34; radius: 2; anchors.left: parent.left; anchors.leftMargin: 0; anchors.verticalCenter: parent.verticalCenter; color: accent }
        RowLayout { anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 14; spacing: 12
            ColumnLayout { Layout.fillWidth: true; spacing: 3
                Text { text: title; color: "#778aa2"; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1.3 }
                RowLayout { spacing: 8
                    Text { text: value; color: window.ink; font.pixelSize: 17; font.weight: Font.DemiBold }
                    Text { text: caption; color: window.muted; font.pixelSize: 9; elide: Text.ElideRight }
                }
            }
            Rectangle { width: 38; height: 38; radius: 11; color: "#162536"
                Text { anchors.centerIn: parent; text: glyph; color: accent; font.pixelSize: 16 }
            }
        }
        scale: statMouse.containsMouse ? 1.008 : 1
        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        MouseArea { id: statMouse; anchors.fill: parent; hoverEnabled: true; z: -1 }
    }
}
