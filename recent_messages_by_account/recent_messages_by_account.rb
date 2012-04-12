class RecentMessagesByAccount < Scout::Plugin
  OPTIONS=<<-EOS
  user:
    name: MySQL username
    notes: Specify the username to connect with
    default: root
  password:
    name: MySQL password
    notes: Specify the password to connect with
    attributes: password
  database:
    name : Database
    notes: Specify the database to connect to
  host:
    name: MySQL host
    notes: Specify something other than 'localhost' to connect via TCP
    default: localhost
  port:
    name: MySQL port
    notes: Specify the port to connect to MySQL with (if nonstandard)
  socket:
    name: MySQL socket
    notes: Specify the location of the MySQL socket
  account_id:
    name: Account Id
    notes: Specify the id of the account you want to monitor
  EOS

  needs 'mysql'

  def build_report
    # get_option returns nil if the option value is blank
    user     = get_option(:user) || 'root'
    password = get_option(:password)
    database = get_option(:database)
    host     = get_option(:host)
    port     = get_option(:port)
    socket   = get_option(:socket)
    account_id = get_option(:account_id)

    current_start = Time.now
    start_key = "last_start"
    last_start = memory(start_key)

    if last_start
      difference_in_minutes = (current_start - last_start) / 60.0

      mysql = Mysql.connect(host, user, password, database, (port.nil? ? nil : port.to_i), socket)
      sql = <<-SQL
    select message_type
         , count(*)
      from recent_messages
     where created_at between '#{last_start.utc.strftime("%Y-%m-%d %H:%M:%S")}'
                          and '#{current_start.utc.strftime("%Y-%m-%d %H:%M:%S")}'
       and account_id       = #{account_id}
  group by message_type
    SQL

       result = mysql.query(sql)
       total = 0
       result.each do |row|
         message_count = row[1].to_i
         total += message_count
         report("#{row[0]}" =>  message_count / difference_in_minutes)
       end
       result.free

       report("Total" => total / difference_in_minutes)
       
    end

    remember(start_key => current_start)
  end

  # Returns nil if an empty string
  def get_option(opt_name)
    val = option(opt_name)
    return (val.is_a?(String) and val.strip == '') ? nil : val
  end
end

