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
      
      # Install dependencies (including transitive dependencies)
      venv.pip_install "fastmcp>=2.6.1"
      venv.pip_install "httpx>=0.28.1"
      venv.pip_install "uvicorn[standard]>=0.30.0"
      venv.pip_install "anyio"  # Missing dependency
      
      # Copy the main script
      libexec.install "main.py"
      
      # Create wrapper script
      (bin/"topmate-mcp").write <<~EOS
        #!/bin/bash
        export PYTHONPATH="#{libexec}:$PYTHONPATH"
        exec "#{libexec}/bin/python" "#{libexec}/main.py" "$@"
      EOS
    end
  
    def caveats
      <<~EOS
        To enable this server in Claude for Desktop, add the following to your
        ~/Library/Application Support/Claude/claude_desktop_config.json file:
  
        "topmate-db": {
          "command": "#{opt_bin}/topmate-mcp",
          "args": []
        }
        You can automate this by running:
          brew postinstall topmate-mcp
  
        To use this package, make sure you have set HOMEBREW_GITHUB_API_TOKEN
        in your environment:
          export HOMEBREW_GITHUB_API_TOKEN=your_token_here
      EOS
    end
  
    def post_install
      config_path = File.expand_path("~/Library/Application Support/Claude/claude_desktop_config.json")
      require "json"
      
      # Create directory if it doesn't exist
      config_dir = File.dirname(config_path)
      FileUtils.mkdir_p(config_dir) unless File.directory?(config_dir)
      
      # Load or create config
      config = File.exist?(config_path) ? JSON.parse(File.read(config_path)) : { "mcpServers" => {} }
      config["mcpServers"] ||= {}
      config["mcpServers"]["topmate-db"] = {
        "command" => "#{opt_bin}/topmate-mcp",
        "args" => []
      }
      
      # Write config
      File.write(config_path, JSON.pretty_generate(config))
      puts "✓ Added topmate-db server to Claude Desktop configuration"
    rescue => e
      puts "Warning: Could not update Claude Desktop config: #{e.message}"
    end
  
    test do
      system bin/"topmate-mcp", "--help"
    end
  end