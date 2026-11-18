import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "." as Local

Panel {
  id: root
  moduleName: "bakugo.protonvpn"
  ipcTarget: moduleName

  readonly property var vpn: Local.VpnStatus.connection
  readonly property var configuration: Local.VpnStatus.configuration
  readonly property bool connected: vpn?.state === "Connected"
  readonly property bool disconnected: vpn?.state === "Disconnected"
  readonly property string stateText: vpn?.state || (Local.VpnStatus.checked ? "Status unavailable" : "Checking status")
  readonly property string badgeText: connected ? "ON" : disconnected ? "OFF" : vpn || !Local.VpnStatus.checked ? "···" : "?"
  readonly property color foreground: barForeground
  readonly property color stateColor: connected ? "#b9adff" : disconnected ? "#ffc187" : foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onOpenedChanged: if (opened) Local.VpnStatus.refresh()

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    hasVisualContent: true
    labelVisible: false
    fixedWidth: vertical ? -1 : Style.bar.iconSlot
    fixedHeight: vertical ? Style.bar.iconSlot : -1
    tooltipText: ["Proton VPN · " + root.stateText, root.vpn?.server || ""].filter(Boolean).join("\n")

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.toggle()
      else if (mouseButton === Qt.RightButton) Local.VpnStatus.refresh()
    }

    BorderSurface {
      anchors.centerIn: parent
      width: Math.max(height, badgeLabel.implicitWidth + 10)
      height: Style.bar.iconSize
      radius: height / 2
      scale: button.pressScale
      color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.14)
      borderSpec: Border.flat(Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.68), 1)

      Text {
        id: badgeLabel
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: root.badgeText
        color: root.stateColor
        font.family: root.fontFamily
        font.pixelSize: 12
        font.bold: true
        renderType: Text.NativeRendering
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(410))
    contentHeight: panel.fittedContentHeight(details.implicitHeight, Style.space(510))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTextKey: function(key) { if (key.toLowerCase() === "r") Local.VpnStatus.refresh() }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: details.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: details
          width: panelFlick.width
          spacing: Style.space(10)

          PanelHero {
            title: "Proton VPN"
            meta: root.stateText
            foreground: root.stateColor
            fontFamily: root.fontFamily
          }

          RowInfo { visible: value !== ""; label: "Server"; value: root.vpn?.server || "" }
          RowInfo { visible: value !== ""; label: "Protocol"; value: root.vpn?.protocol || "" }
          RowInfo { visible: value !== ""; label: "Server load"; value: root.vpn?.load || "" }

          PanelSeparator { foreground: root.foreground }
          PanelSectionHeader {
            text: "Current settings"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Repeater {
            model: root.configuration || []
            delegate: RowInfo {
              required property var modelData
              label: modelData.label
              value: modelData.value
            }
          }

          Text {
            width: parent.width
            visible: !root.configuration
            textFormat: Text.PlainText
            text: Local.VpnStatus.loadingConfiguration ? "Reading settings…" : "Settings unavailable"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }
        }
      }
    }
  }

  component RowInfo: RowLayout {
    id: row
    property string label: ""
    property string value: ""

    width: parent ? parent.width : 0
    spacing: Style.space(12)

    Text {
      Layout.preferredWidth: row.width * 0.43
      Layout.alignment: Qt.AlignTop
      textFormat: Text.PlainText
      text: row.label
      color: root.foreground
      opacity: 0.8
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Text {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignTop
      textFormat: Text.PlainText
      text: row.value
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      wrapMode: Text.WrapAnywhere
    }
  }
}
