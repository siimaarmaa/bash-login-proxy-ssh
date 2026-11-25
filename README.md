# bash-login-proxy-ssh

A small Bash menu for logging in to SSH servers. The servers are listed in a JSON file. You pick one from a numbered list, and the script connects to it directly or through a proxy (jump host).

## Files

| File | Contents |
|---|---|
| `server.sh` | The menu script |
| `servers.json` | List of servers (example values, replace with your own) |

## Requirements

- Bash (works with the Bash 3.2 that ships with macOS)
- An OpenSSH client (`ssh`)
- Standard tools: `sed`, `grep`, `awk`, `tr`
- SSH access to the servers. Key-based login (`~/.ssh`, `ssh-agent`) is recommended

No `jq` or other JSON tools are needed.

## Configuration

Edit `servers.json`:

```json
{
    "servers": [
        {
            "name": "Proxy Server",
            "host": "private.ip",
            "user": "username",
            "port": 22,
            "proxy": "gateway.public.ip.address"
        },
        {
            "name": "Other Server",
            "host": "public.ip",
            "user": "username"
        }
    ]
}
```

| Field | Required | Meaning |
|---|---|---|
| `name` | yes | Name shown in the menu |
| `host` | yes | Host name or IP of the server |
| `user` | yes | SSH user name |
| `port` | no | SSH port, default `22` |
| `proxy` | no | Host name or IP of a jump host. If set, the connection goes through this host |

Keep the fields in the order shown above, with `name` first and each field on its own line (see [Known issues](#known-issues)).

## Usage

The script reads `servers.json` from the **current directory**, so run it from the folder that contains both files:

```bash
chmod +x server.sh
./server.sh
```

Example session:

```
Available servers:
1) Proxy Server
2) Other Server
Select a server to connect: 1
Connecting to username@private.ip via gateway.public.ip.address on port 22 ...
```

## How the connection is made

Without a proxy:

```bash
ssh -p <port> <user>@<host>
```

With a proxy, the script uses the proxy as a jump host and logs in to it as `root`:

```bash
ssh -o ProxyCommand="ssh -W %h:%p root@<proxy>" -p <port> <user>@<host>
```

The `port` value applies to the target server, not to the proxy.

## Known issues

- The proxy user is hard-coded to `root` (`root@$proxy`). If your jump host uses another user, change it in `server.sh`.
- `servers.json` is not parsed with a real JSON parser. The script finds a server with `grep -A 4` and reads the fields from the 4 lines after the name. Because of this, `name` must come first, every field must be on its own line, and a server must not have more than 4 fields after `name`.
- Server names must be unique and must not contain double quotes.
- The script uses the relative path `servers.json`, so it fails when started from another directory.
- Host key checking and other SSH options are left to your normal SSH configuration (`~/.ssh/config`).

## License

No license file is included. Add one (for example MIT) if others should be allowed to reuse the script.
