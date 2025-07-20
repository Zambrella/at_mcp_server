## Notes

- Build with `dart compile exe bin/main.dart -o at_mcp_server.exe`

## Features
### [Resources](https://modelcontextprotocol.io/docs/concepts/resources)
- Specification of at protocol
- Most pages from gitbook docs

### [Tools](https://modelcontextprotocol.io/docs/concepts/tools)
- Get all atkeys
- Get value of atkey
- TODO: Other CRUD


### Claude desktop configuration
```json
{
  "mcpServers": {
    "atsign": {
      "command": "/Users/douglastodd/Projects/atsign/at_mcp_server/at_mcp_server.exe"
    }
  }
}
```

### MCP Inspector Usage
https://modelcontextprotocol.io/docs/tools/inspector

See `mcp_inspector_config.json` for setup.

Run: `npx @modelcontextprotocol/inspector --config mcp_inspector_config.json --server at-sign-tools`
