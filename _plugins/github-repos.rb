require 'json'
require 'net/http'
require 'uri'

# Fetches GitHub profile and repository metadata at build time so the
# repositories page can render its cards as plain HTML, without relying on
# third-party image services (github-readme-stats, github-profile-trophy).
#
# Results are exposed as site.data.github.users[<username>] and
# site.data.github.repos[<owner/repo>]. Set GITHUB_TOKEN to avoid the
# unauthenticated rate limit (60 requests/hour).
module Jekyll
  class GitHubReposGenerator < Generator
    safe true
    priority :highest

    API = 'https://api.github.com'.freeze

    def generate(site)
      config = site.data['repositories'] || {}
      users = Array(config['github_users'])
      repos = Array(config['github_repos'])

      site.data['github'] = {
        'users' => users.to_h { |u| [u, fetch_user(u)] },
        'repos' => repos.to_h { |r| [r, fetch_repo(r)] },
      }
    end

    private

    def fetch_user(username)
      data = get("/users/#{username}")
      return { 'login' => username, 'html_url' => "https://github.com/#{username}" } unless data

      data.slice('login', 'name', 'bio', 'avatar_url', 'html_url', 'public_repos', 'followers', 'following')
    end

    def fetch_repo(full_name)
      owner, name = full_name.split('/', 2)
      data = get("/repos/#{full_name}")
      return { 'name' => name, 'owner' => owner, 'html_url' => "https://github.com/#{full_name}" } unless data

      data.slice('name', 'description', 'html_url', 'language', 'stargazers_count', 'forks_count', 'fork')
          .merge('owner' => data.dig('owner', 'login'))
    end

    def get(path)
      uri = URI("#{API}#{path}")
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/vnd.github+json'
      request['User-Agent'] = 'jekyll-github-repos'
      request['Authorization'] = "Bearer #{ENV['GITHUB_TOKEN']}" if ENV['GITHUB_TOKEN'] && !ENV['GITHUB_TOKEN'].empty?

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 10) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        Jekyll.logger.warn 'GitHub:', "#{path} returned #{response.code}"
        return nil
      end

      JSON.parse(response.body)
    rescue StandardError => e
      Jekyll.logger.warn 'GitHub:', "#{path} failed: #{e.message}"
      nil
    end
  end
end
