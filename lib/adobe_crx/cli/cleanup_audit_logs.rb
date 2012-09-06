require 'date'

@@process_uri_for_audit_logs__go_deep = false
def process_uri_for_audit_logs(client, uri, cutoff, start_with)
  puts "checking #{uri}"
  @@process_uri_for_audit_logs__go_deep = true if uri == start_with
  valid_audit_events = 0
  begin
    to_delete = []
    JSON.parse(client.get_resource("#{uri}.1.json")).each do |key, value|
      if value.respond_to?(:has_key?) && value.has_key?('jcr:primaryType')
        primary_type = value['jcr:primaryType']
        if primary_type.match /.*Folder$/
          if @@process_uri_for_audit_logs__go_deep || start_with.match(/^#{uri}\/#{key}/)
            folder_audit_events = process_uri_for_audit_logs(client, "#{uri}/#{key}", cutoff, start_with)
            valid_audit_events = valid_audit_events + folder_audit_events
            if folder_audit_events == 0 && "#{uri}/#{key}".count('/') > 3
              puts "Deleting folder #{uri}/#{key}"
              client.delete_resources ["#{uri}/#{key}"]
            end
          else
            valid_audit_events = valid_audit_events + 1
          end
        elsif 'cq:AuditEvent' == primary_type && value.has_key?('cq:time')
          time = DateTime.strptime(value['cq:time'], '%a %b %d %Y %H:%M:%S GMT%z')
          if time.to_time.to_i < cutoff
            puts "Marking '#{uri}/#{key}' for deletion (time=#{time})"
            to_delete << "#{uri}/#{key}"
          else
            valid_audit_events = valid_audit_events + 1
          end
        end
      end
    end
    if (valid_audit_events > 0 || "#{uri}".count('/') == 3) && to_delete.size > 0
      client.delete_resources to_delete
    end
  rescue JSON::ParserError
    #to keep directories from being deleted when we don't want them to
    valid_audit_events = valid_audit_events + 1
  end
  valid_audit_events
end

command :cleanup_audit_logs do |c|
  c.syntax = 'crx cleanup_audit_logs [options]'
  c.description = 'Removes log entries under /var/audit older than a specified number of days (defaults to 180)'
  c.option "--days_to_keep OUTPUT_FILE", String, "number of days to keep (defaults to 180)"
  c.option "--start_with PATH_TO_START_WITH", String, "the path to start with"
  c.action do |args, options|
    validate_global_options c, options
    days_to_keep = 180
    if options.days_to_keep
      days_to_keep = options.days_to_keep.to_i
    end
    start_with = '/var/audit'
    if options.start_with
      start_with = options.start_with
    end
    
    puts "Deleting all audit nodes greater than #{days_to_keep} days old."
    client = AdobeCRX::Client.new options.host, options.port, options.username, options.password
    process_uri_for_audit_logs(client, '/var/audit', Time.now.to_i - (days_to_keep * (24*60*60)), start_with)
  end
end