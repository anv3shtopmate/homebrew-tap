require_relative "lib/custom_download_strategy"

class TopmateMcp < Formula
    include Language::Python::Virtualenv
  
    desc "Topmate DB MCP Server"
    homepage "https://github.com/topmate-io/topmate-db-mcp-server"
    url "https://github.com/topmate-io/topmate-db-mcp-server/archive/refs/tags/v0.1.0.tar.gz"
    using GitHubPrivateRepositoryReleaseDownloadStrategy
    sha256 "c80ef0f314501464067e58f268bd518c5603aeebab1b7c1825026b275fd44110"
    version "1.0.0"
    license "MIT"
  
    depends_on "python@3.12"
  
    def install
      ENV["PYTHONPATH"] = libexec/"lib/python3.12/site-packages"
      virtualenv_install_with_resources
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
  
    # Optional: Add a postinstall step to automate config update
    def post_install
      config_path = File.expand_path("~/Library/Application Support/Claude/claude_desktop_config.json")
      require "json"
      config = File.exist?(config_path) ? JSON.parse(File.read(config_path)) : { "mcpServers" => {} }
      config["mcpServers"] ||= {}
      config["mcpServers"]["topmate-db"] = {
        "command" => "#{opt_bin}/topmate-mcp",
        "args" => []
      }
      File.write(config_path, JSON.pretty_generate(config))
    end
  
    test do
      system bin/"topmate-mcp", "--version"
    end
  end