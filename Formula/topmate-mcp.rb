require_relative "lib/custom_download_strategy"

class TopmateMcp < Formula
    include Language::Python::Virtualenv
  
    desc "Topmate DB MCP Server"
    homepage "https://github.com/topmate-io/topmate-db-mcp-server"
    url "https://github.com/topmate-io/topmate-db-mcp-server/archive/refs/tags/v0.1.0.tar.gz",
        using: GitHubPrivateRepositoryReleaseDownloadStrategy
    sha256 "c80ef0f314501464067e58f268bd518c5603aeebab1b7c1825026b275fd44110"
    version "0.1.0"
    license "MIT"
  
    depends_on "python@3.12"
  
    def install
      # Create virtualenv with pip
      venv = virtualenv_create(libexec, "python3.12")
      
      # Install all required dependencies
      dependencies = [
        "annotated-types==0.7.0",
        "anyio==4.9.0", 
        "authlib==1.6.0",
        "certifi==2025.4.26",
        "cffi==1.17.1",
        "charset-normalizer==3.4.2",
        "click==8.2.1",
        "cryptography==45.0.3",
        "exceptiongroup==1.3.0",
        "fastapi==0.115.12",
        "fastmcp==2.6.1",
        "h11==0.16.0",
        "httpcore==1.0.9",
        "httptools==0.6.4",
        "httpx==0.28.1",
        "httpx-sse==0.4.0",
        "idna==3.10",
        "markdown-it-py==3.0.0",
        "mcp==1.9.2",
        "mdurl==0.1.2",
        "openapi-pydantic==0.5.1",
        "pycparser==2.22",
        "pydantic==2.11.5",
        "pydantic-core==2.33.2",
        "pydantic-settings==2.9.1",
        "pygments==2.19.1",
        "python-dotenv==1.1.0",
        "python-multipart==0.0.20",
        "pyyaml==6.0.2",
        "requests==2.32.3",
        "rich==14.0.0",
        "shellingham==1.5.4",
        "sniffio==1.3.1",
        "sse-starlette==2.3.6",
        "starlette==0.47.0",
        "typer==0.16.0",
        "typing-extensions==4.14.0",
        "typing-inspection==0.4.1",
        "urllib3==2.4.0",
        "uvicorn==0.34.3",
        "uvloop==0.21.0",
        "watchfiles==1.0.5",
        "websockets==15.0.1"
      ]
      
      dependencies.each { |dep| venv.pip_install dep }
      
      # Copy the main script
      libexec.install "main.py"
      
      # Create wrapper script
      (bin/"topmate-mcp").write <<~EOS
        #!/bin/bash
        export PYTHONPATH="#{libexec}:$PYTHONPATH"
        exec "#{libexec}/bin/python" "#{libexec}/main.py" "$@"
      EOS
      
      # Create Claude Desktop configuration helper script
      (bin/"topmate-mcp-configure-claude").write <<~EOS
        #!/bin/bash
        set -e
        
        CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
        
        echo "Configuring Claude Desktop for Topmate MCP Server..."
        
        # Create directory if it doesn't exist
        mkdir -p "$(dirname "$CONFIG_PATH")"
        
        # Create or update config file
        if [ -f "$CONFIG_PATH" ]; then
          echo "Updating existing Claude Desktop configuration..."
          # Use jq if available, otherwise use python
          if command -v jq > /dev/null; then
            jq '.mcpServers["topmate-db"] = {"command": "#{opt_bin}/topmate-mcp", "args": []}' "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"
          else
            python3 -c "
import json
import sys
with open('$CONFIG_PATH', 'r') as f:
    config = json.load(f)
config.setdefault('mcpServers', {})
config['mcpServers']['topmate-db'] = {
    'command': '#{opt_bin}/topmate-mcp',
    'args': []
}
with open('$CONFIG_PATH', 'w') as f:
    json.dump(config, f, indent=2)
"
          fi
        else
          echo "Creating new Claude Desktop configuration..."
          cat > "$CONFIG_PATH" << 'EOF'
{
  "mcpServers": {
    "topmate-db": {
      "command": "#{opt_bin}/topmate-mcp",
      "args": []
    }
  }
}
EOF
        fi
        
        echo "✓ Successfully configured Claude Desktop!"
        echo "Configuration saved to: $CONFIG_PATH"
        echo ""
        echo "Please restart Claude Desktop for the changes to take effect."
      EOS
      
      chmod 0755, bin/"topmate-mcp-configure-claude"
    end
  
    def caveats
      <<~EOS
        Topmate MCP Server has been installed successfully!
        
        🔧 CLAUDE DESKTOP CONFIGURATION
        
        To enable this server in Claude Desktop, you have two options:
        
        Option 1 (Recommended): Use the configuration helper script
          #{opt_bin}/topmate-mcp-configure-claude
        
        Option 2: Manual configuration
          Add the following to your Claude Desktop config file at:
          ~/Library/Application Support/Claude/claude_desktop_config.json
          
          {
            "mcpServers": {
              "topmate-db": {
                "command": "#{opt_bin}/topmate-mcp",
                "args": []
              }
            }
          }
        
        📋 SETUP REQUIREMENTS
        
        Make sure you have set HOMEBREW_GITHUB_API_TOKEN in your environment:
          export HOMEBREW_GITHUB_API_TOKEN=your_token_here
        
        🚀 USAGE
        
        Test the server directly:
          #{opt_bin}/topmate-mcp
        
        Configure Claude Desktop:
          #{opt_bin}/topmate-mcp-configure-claude
        
        After configuration, restart Claude Desktop to load the MCP server.
      EOS
    end
  
    test do
      system bin/"topmate-mcp", "--help"
    end
  end