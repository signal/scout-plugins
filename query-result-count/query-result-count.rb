class QueryResultCount < Scout::Plugin
  OPTIONS=<<-EOS
  user:
    name: MySQL username
    notes: Specify the username to connect with
    default: root
  password:
    name: MySQL password
    notes: Specify the password to connect with
    attributes: password
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
  database:
    name: MySQL database
    notes: The database that the tables are located in
  query:
    name: Query to execute
    notes: Specify the table name and WHERE clause (ex. "FROM table_1 WHERE col1=1")
  EOS

  needs 'mysql'

  def build_report
    # get_option returns nil if the option value is blank
    user     = get_option(:user) || 'root'
    password = get_option(:password)
    host     = get_option(:host)
    port     = get_option(:port)
    socket   = get_option(:socket)
    database = get_option(:database)
    query    = get_option(:query)

    mysql = Mysql.connect(host, user, password, database, (port.nil? ? nil : port.to_i), socket)

    result = mysql.query("SELECT count(*) #{query}")
    row = result.fetch_row
    if row
      report(:count => row[0].to_i)
    end
    result.free
  end

  # Returns nil if an empty string
  def get_option(opt_name)
    val = option(opt_name)
    return (val.is_a?(String) and val.strip == '') ? nil : val
  end
end
