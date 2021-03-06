# Custom monitoring of Singal's SMS system.
#
# The following statistics are calculated (for the last five minutes of traffic):
#
# MT:: The number of Mobile Terminated (aka, outgoing) messages sent.
# MO:: The number of Mobile Originated (aka, incoming) messages recevied.
# CM:: The number of Carrier lookups recevied.
# Failed MTs::
#      The number of MTs that were not sent due to a failure
#      from the aggregator.
# Average Transaction Time::
#      The average latency (in seconds) for processing a text message
#      transaction. In other words, this is the total time spent in
#      our system. TM transactions originate either from received MOs
#      (user requests) or system generated MTs (scheduled messages).
#      This average is across all types.
# Average Aggregator Time::
#      The average latency (in seconds) that the aggregator took to
#      process the outgoing MT.
class SmsStats < Scout::Plugin
  OPTIONS = <<-EOS
  user:
    name: MySQL username
    notes: Specify the username to connect with!
    default: root
  password:
    name: MySQL password
    notes: Specify the password to connect with!
  host:
    name: MySQL host
    notes: Specify something other than 'localhost' to connect via TCP!
    default: localhost
  port:
    name: MySQL port
    notes: Specify the port to connect to MySQL with (if nonstandard)!
  socket:
    name: MySQL socket
    notes: Specify the location of the MySQL socket
  database:
    name: Database name
    notes: Specify the name of the database that has the messaging tables
  scheduled_messages:
    name:  Scheduled messages?
    notes: Leave blank to report on non scheduled messages. Provide a value to report on scheduled messages
  EOS

  needs 'mysql'

  DB_FORMAT = '%Y-%m-%d %H:%M:%S'

  def build_report
    last_run = memory(:last_run)

    # Will calculate message deltas on the next run.
    unless last_run.nil?
      user = option(:user) || 'root'
      password = option(:password)
      host = option(:host) || 'localhost'
      port = option(:port) || 3306
      socket = option(:socket) || '/tmp/mysql.sock'
      database = option(:database)

      mysql = Mysql.connect(host, user, password, database, port.to_i, socket)
      scheduled = option(:scheduled_messages).nil? ? " " : "not"
      results = mysql.query <<-SQL
        select sum(if(message_type='MT' and error_code is null,1,0)) as mt,
               sum(if(message_type='MO',1,0)) as mo,
               sum(if(message_type='CM',1,0)) as cm,
               sum(if(message_type = 'MT' and error_code is not null,1,0)) as failed_mt,
               avg(transaction_time) as avg_transaction_time,
               avg(aggregator_time) as avg_aggregator_time
          from recent_messages
         where created_at > '#{last_run.utc.strftime(DB_FORMAT)}'
         and scheduled_message_id is #{scheduled} null
      SQL

      results.each_hash do |row|
        report(:MT => row['mt'] || 0, :MO => row['mo'] || 0,
               'Failed MTs' => row['failed_mt'] || 0,
               'Average Transaction Time' => row['avg_transaction_time'],
               'Average Aggregator Time' => row['avg_aggregator_time'],
               :CM => row['cm'] || 0)
      end
    end

    remember(:last_run, Time.now)
  end
end
