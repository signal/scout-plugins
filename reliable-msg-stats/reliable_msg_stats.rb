class ReliableMsgStats < Scout::Plugin
  needs 'mysql'

  def build_report
    user = option(:user) || 'root'
    password = option(:password)
    host = option(:host) || 'localhost'
    port = option(:port) || 3306
    socket = option(:socket) || '/tmp/mysql.sock'
    database = option(:database)
    max_queue_size = option(:max_queue_size) || 100

    mysql = Mysql.connect(host, user, password, database, port.to_i, socket)
    results = mysql.query('SELECT queue, count(1) from reliable_msg_queues group by queue')

    report_data = {}
    alert_data = []
    results.each do |row|
      report_data[row[0]] = row[1].to_i
      alert_data << {:subject => "Maximum Queue Size Exceeded for Queue: #{row[0]} - Size: #{row[1]}"} if row[1].to_i >= max_queue_size.to_i && row[0] != '$dlq'
    end

    report(report_data)
    alert(alert_data) unless alert_data.empty?
  end
end
