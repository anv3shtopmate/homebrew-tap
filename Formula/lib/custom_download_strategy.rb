require "download_strategy"

# GitHubPrivateRepositoryDownloadStrategy downloads the source from a private
# GitHub repository using an access token.
class GitHubPrivateRepositoryDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
    parse_url_pattern
    set_github_token
  end

  def parse_url_pattern
    unless match = url.match(%r{https://github.com/([^/]+)/([^/]+)/(\S+)})
      raise CurlDownloadStrategyError, "Invalid url pattern for GitHub Repository."
    end

    _, @owner, @repo, @filepath = *match
  end

  def download_url
    "https://github.com/#{@owner}/#{@repo}/#{@filepath}"
  end

  private

  def _fetch(url:, resolved_url:, timeout:)
    curl_download download_url, "--header", "Authorization: token #{@github_token}", to: temporary_path
  end

  def set_github_token
    @github_token = ENV["HOMEBREW_GITHUB_API_TOKEN"]
    unless @github_token
      raise CurlDownloadStrategyError, "Environmental variable HOMEBREW_GITHUB_API_TOKEN is required"
    end
  end
end

# GitHubPrivateRepositoryReleaseDownloadStrategy downloads the source from
# a private GitHub repository release using an access token.
class GitHubPrivateRepositoryReleaseDownloadStrategy < GitHubPrivateRepositoryDownloadStrategy
  def initialize(url, name, version, **meta)
    super
  end

  def parse_url_pattern
    url_pattern = %r{https://github.com/([^/]+)/([^/]+)/archive/refs/tags/([^/]+)(\.tar\.gz|\.zip)}
    unless @url =~ url_pattern
      raise CurlDownloadStrategyError, "Invalid url pattern for GitHub Release."
    end

    _, @owner, @repo, @tag = *@url.match(url_pattern)
  end

  def download_url
    "https://github.com/#{@owner}/#{@repo}/archive/refs/tags/#{@tag}.tar.gz"
  end

  private

  def _fetch(url:, resolved_url:, timeout:)
    curl_download download_url, "--header", "Authorization: token #{@github_token}", to: temporary_path
  end
end 