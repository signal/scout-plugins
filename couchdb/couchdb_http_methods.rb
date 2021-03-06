class CouchDBHttpMethodsPlugin < Scout::Plugin

  OPTIONS = <<-EOS
    couchdb_port:
      label: The port that CouchDB is running on
      default: 5984
    couchdb_host:
      label: The host that CouchDB is running on
      default: http://127.0.0.1
    stats_range:
      label: The time range to fetch stats for in seconds (60, 300, or 900).  Used for CouchDB 0.11 and higher.
      default: 300
  EOS

  needs 'net/http', 'json', 'facets'

  def build_report
    base_url = "#{option(:couchdb_host)}:#{option(:couchdb_port)}/"

    response = JSON.parse(Net::HTTP.get(URI.parse(base_url)))
    version = response['version']

    http_methods = %w{GET POST PUT DELETE HEAD}
    if version.to_f >= 0.11
      stats = %w{sum mean max stddev}
      http_methods.each do |http_method|
        response = JSON.parse(Net::HTTP.get(URI.parse(base_url + "_stats/httpd_request_methods/#{http_method}?range=#{option(:stats_range)}")))
        stats.each { |stat| report("httpd_request_methods_#{http_method}_#{stat}".to_sym => response['httpd_request_methods'][http_method].ergo[stat] || 0) }
      end
    else
      now = Time.now.to_i
      seconds_since_last_run = now - (memory(:last_run_time) || 0)
      remember(:last_run_time, now)

      http_methods.each do |http_method|
        key = "httpd_request_methods_#{http_method}_sum".to_sym
        response = JSON.parse(Net::HTTP.get(URI.parse(base_url + "_stats/httpd_request_methods/#{http_method}")))
        count = response['httpd_request_methods'][http_method].ergo['current'] || 0
        value = count - (memory(key) || 0)
        report(key => value)
        remember(key, count)

        key = "httpd_request_methods_#{http_method}_mean".to_sym
        report(key => value/seconds_since_last_run.to_f)
      end
    end
  end
end
