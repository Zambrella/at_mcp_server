# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an MCP (Model Context Protocol) server that provides tools and resources for interacting with the atPlatform ecosystem. The server exposes atSign operations through MCP tools and serves atPlatform documentation as resources.

## Architecture

### Core Components

- **`bin/main.dart`**: Entry point that creates an `AtSignMCPServer` instance connected to stdio
- **`lib/at_mcp_server.dart`**: Main server class extending `MCPServer` with tools and resources support
- **`lib/init_at_client.dart`**: AtClient initialization and authentication logic
- **`lib/mcp_logging_handler.dart`**: Custom logging handler for MCP integration

### MCP Integration

The server implements three main MCP capabilities:

1. **Tools**: `listKeys` and `getKey` for atSign operations
2. **Resources**: Static markdown documentation from the atPlatform docs
3. **Logging**: Custom logging that integrates with MCP's logging system

### atClient Integration

- Uses `at_client` package for atPlatform connectivity
- Handles authentication via `at_onboarding_cli`
- Stores keys in `~/.atsign/keys/` directory
- Configurable root domain/port for different atPlatform environments

## Development Commands

### Build
```bash
dart compile exe bin/main.dart -o at_mcp_server.exe
```

### Testing
```bash
dart test
```

### Linting
```bash
dart analyze
```

### MCP Inspector Testing
```bash
npx @modelcontextprotocol/inspector --config mcp_inspector_config.json --server at-sign-tools
```

## Key Dependencies

- `dart_mcp`: MCP protocol implementation
- `at_client`: atPlatform client SDK
- `at_onboarding_cli`: atSign authentication
- `at_utils`: Utility functions for atSign validation
- `http`: For fetching documentation resources

## Configuration

- **Root Domain**: Defaults to `root.atsign.org`
- **Root Port**: Defaults to `64`
- **Home Directory**: Uses `$HOME` environment variable
- **Key Storage**: `~/.atsign/keys/{atsign}_key.atKeys`
- **Local Storage**: `~/.atsign/storage/`

## Tool Parameters

Both `listKeys` and `getKey` tools accept:
- `atsign` (required): The atSign to interact with
- `rootDomain` (optional): Custom root domain
- `rootPort` (optional): Custom root port
- `namespace` (optional): Namespace filter

The `listKeys` tool additionally accepts:
- `regexp`: Regular expression to filter keys
- `sharedBy`: Filter by atSign that shared the key
- `sharedWith`: Filter by atSign the key is shared with