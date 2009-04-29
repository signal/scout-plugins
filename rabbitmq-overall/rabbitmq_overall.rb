class RabbitmqOverall < Scout::Plugin
  def build_report
    begin
      report_data = {}

      connection_stats = `#{rabbitmqctl} -q list_connections`.to_a
      report_data['connections'] = connection_stats.size

      report_data['queues'] = report_data['messages'] = report_data['queue_b'] = 0
      report_data['exchanges'] = 0
      report_data['bindings'] = 0
      vhosts.each do |vhost|
        queue_stats = `#{rabbitmqctl} -q list_queues -p '#{vhost}' messages memory`.to_a
        report_data['queues'] += queue_stats.size
        report_data['messages'] += queue_stats.inject(0) do |sum, line|
          sum += line.split[0].to_i
        end

        report_data['queue_b'] += queue_stats.inject(0) do |sum, line|
          sum += line.split[1].to_i
        end

        exchange_stats = `#{rabbitmqctl} -q list_exchanges -p #{vhost}`.to_a
        report_data['exchanges'] += exchange_stats.size

        binding_stats = `#{rabbitmqctl} -q list_bindings -p #{vhost}`.to_a
        report_data['bindings'] += binding_stats.size
      end

      report(report_data)
    rescue RuntimeError => e
      add_error(e.message)
    end
  end

  def rabbitmqctl
    @options['rabbitmqctl'] || '/opt/local/lib/erlang/lib/rabbitmq_server-1.5.0/sbin/rabbitmqctl'
  end

  def vhosts
    @vhosts ||= `#{rabbitmqctl} -q list_vhosts`.to_a
  end

  def `(command)
    result = super(command)
    if ($? != 0)
      raise "<#{command}> exited with a non-zero value: #{$?}"
    end
    result
  end
end
