pragma Singleton

import QtQuick
import Quickshell.Io
import "CliOutput.js" as CliOutput

QtObject {
  id: root

  property var connection: null
  property var configuration: null
  property bool checked: false
  readonly property bool loadingConfiguration: configProbe.running

  function refresh() {
    if (!statusProbe.running) statusProbe.running = true
    if (!configProbe.running) configProbe.running = true
  }

  // One poller serves every monitor. Configuration is fetched on demand.
  property Timer statusTimer: Timer {
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!statusProbe.running) statusProbe.running = true
  }

  property Process statusProbe: Process {
    id: statusProbe
    command: ["/usr/bin/timeout", "--kill-after=2s", "12s", "protonvpn", "status"]
    environment: ({ LC_ALL: "C", NO_COLOR: "1", TERM: "dumb" })
    stdout: StdioCollector { id: statusOutput; waitForEnd: true }
    onExited: function(exitCode) {
      root.connection = exitCode === 0 ? CliOutput.parseStatus(statusOutput.text) : null
      root.checked = true
    }
  }

  property Process configProbe: Process {
    id: configProbe
    command: ["/usr/bin/timeout", "--kill-after=2s", "12s", "protonvpn", "config", "list"]
    environment: ({ LC_ALL: "C", NO_COLOR: "1", TERM: "dumb" })
    stdout: StdioCollector { id: configOutput; waitForEnd: true }
    onExited: function(exitCode) {
      root.configuration = exitCode === 0 ? CliOutput.parseConfiguration(configOutput.text) : null
    }
  }
}
