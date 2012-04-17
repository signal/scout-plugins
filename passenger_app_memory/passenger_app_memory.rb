class PassengerAppMemory < Scout::Plugin
  OPTIONS=<<-EOS
  passenger_memory_stats_command:
    name: The Passenger Memory Stats Command
    notes: The full path to the passenger-memory-stats command.
    default: /usr/bin/passenger-memory-stats
  app_instance:
    name: App Instance
    notes: The app instance to monitor
  EOS

  def build_report
    cmd  = option(:passenger_memory_stats_command) || "passenger-memory-stats"
    @app_instance = option(:app_instance)
    data = `#{cmd} | grep -E 'Rails|Rack' | grep #{@app_instance}`.to_a
    stats = parse_data(data)
    report(stats)
  end

  def parse_data(data)
    report_data = {}
    report_data["count"] = data.size
    memory = []
    data.each { | instance |
       fields = instance.split
       memory << fields[1].to_f
    }

    report_data["total memory (MB)"] = memory.inject(0){|sum,item| sum + item}
    report_data["max memory (MB)"] = memory.max
    report_data["min memory (MB)"] = memory.min

    report_data
  end
end
