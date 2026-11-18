function parseStatus(output) {
  const fields = {}
  for (const line of String(output).slice(0, 8192).split(/\r?\n/)) {
    const match = /^(Status|Server|Load|Protocol):\s*(\S.*)$/.exec(line.trim())
    if (match) fields[match[1]] = match[2].slice(0, 240)
  }

  const state = fields.Status
  if (!["Connected", "Disconnected", "Connecting", "Disconnecting"].includes(state)) return null

  return { state, server: fields.Server || "", load: fields.Load || "", protocol: fields.Protocol || "" }
}

const settingLabels = {
  "netshield": "NetShield",
  "kill-switch": "Kill switch",
  "port-forwarding": "Port forwarding",
  "custom-dns": "Custom DNS",
  "vpn-accelerator": "VPN Accelerator",
  "moderate-nat": "Moderate NAT",
  "ipv6": "IPv6",
  "anonymous-crash-reports": "Anonymous crash reports"
}

function parseConfiguration(output) {
  const lines = String(output).slice(0, 12288).split(/\r?\n/)
  const header = lines.findIndex(line => /^\s*Setting\s{2,}Value\s*$/.test(line))
  if (header < 0 || !/^\s*-+\s+-+\s*$/.test(lines[header + 1] || "")) return null

  const settings = []
  for (const line of lines.slice(header + 2, header + 32)) {
    const match = /^([a-z][a-z0-9-]*)\s{2,}(\S.*)$/.exec(line.trim())
    if (!match) break
    const key = match[1]
    const label = Object.prototype.hasOwnProperty.call(settingLabels, key)
      ? settingLabels[key]
      : key.replace(/-/g, " ").replace(/^./, char => char.toUpperCase())
    settings.push({ label, value: match[2].slice(0, 512) })
  }
  return settings.length ? settings : null
}
