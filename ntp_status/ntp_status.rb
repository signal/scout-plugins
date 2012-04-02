class NtpStatus < Scout::Plugin
  def build_report
    output = `ntpstat`
    if $?.success?
      report :ntpstat => 'synchronized'
    else
      report :ntpstat => 'unsynchronized'
      alert("ntpstat failed", output)
    end
  end
end
