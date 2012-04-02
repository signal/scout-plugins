class NtpStatus < Scout::Plugin
  def build_report
    output = `ntpstat`
    if $?.success?
      status = output.split("\n")[0]
      time_correct_ms = output.match(/time correct to within ([0-9]+) ms/)[1].to_i
      polling_server_s = output.match(/polling server every ([0-9]+) s/)[1].to_i
      report :status => status, :time_correct_ms => time_correct_ms, :polling_server_s => polling_server_s
    else
      report :ntpstat => 'unsynchronized'
      alert("ntpstat failed", output)
    end
  end
end
