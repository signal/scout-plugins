class MonitStatsPlugin < Scout::Plugin
  OPTIONS=nil

  MONIT_STATES = ['execution failed', 'not monitored', 'running', 'initializing', 'Resource limit matched']

  def build_report
    processes = `sudo monit summary`
    processes_array = processes.scan(/process\s\S*\s*([a-z ]*)/i).flatten
    processes_hash = Hash.new(0)
    MONIT_STATES.each {|state| processes_hash[state] = 0 }
    processes_array.each {|state| processes_hash[state] += 1 }
    report(processes_hash)
  end
end
