require "base64"
require "uri"
require "yaml"

abort "Pass at least one rendered booking-tool manifest" if ARGV.empty?

ARGV.each do |path|
  documents = Psych.parse_stream(File.read(path)).children.map do |document|
    stream = Psych::Nodes::Stream.new
    stream.children << document
    YAML.safe_load(stream.to_yaml, aliases: false)
  end.compact
  resource = lambda do |kind, suffix = ""|
    matches = documents.select { |doc| doc["kind"] == kind && doc.dig("metadata", "name").end_with?(suffix) }
    raise "Expected one #{kind} #{suffix}" unless matches.length == 1
    matches.first
  end
  runtime_config = YAML.safe_load(resource.call("ConfigMap", "-deployment-config").fetch("data").fetch("config.yaml"))
  migration_config = YAML.safe_load(resource.call("ConfigMap", "-migration-config").fetch("data").fetch("migrate.yaml"))
  raise "Migration config must be database-only" unless migration_config.keys == ["database"]
  raise "Legacy database credentials must not render" if [runtime_config, migration_config].any? { |config| config.fetch("database").key?("secret_arn") }

  users = %w[runtime migration].map do |role|
    config = role == "runtime" ? runtime_config : migration_config
    uri = URI(config.fetch("database").fetch("dsn"))
    secret = resource.call("Secret", "-pg-#{role}").fetch("data")
    username = URI::DEFAULT_PARSER.unescape(uri.user)
    password = URI::DEFAULT_PARSER.unescape(uri.password)
    raise "#{role} username mismatch" unless username == Base64.strict_decode64(secret.fetch("username"))
    raise "#{role} password URL encoding mismatch" unless password == Base64.strict_decode64(secret.fetch("password"))
    raise "#{role} must connect to CNPG with TLS" unless uri.host.end_with?("-postgres-cluster-rw") && uri.query == "sslmode=require"
    [username, uri.host, uri.path]
  end
  raise "Runtime and migration must use distinct roles on the same database" unless users[0][0] != users[1][0] && users[0][1..] == users[1][1..]

  cluster = resource.call("Cluster").fetch("spec")
  cluster.fetch("managed").fetch("roles").each do |role|
    raise "Application database role has administrative privileges" unless %w[superuser createdb createrole replication bypassrls].all? { |flag| role[flag] == false }
  end
  if cluster.fetch("bootstrap").key?("initdb")
    initdb = cluster.fetch("bootstrap").fetch("initdb")
    raise "Migration role must own the database" unless initdb.fetch("owner") == users[1][0]
    grants = initdb.fetch("postInitApplicationSQL").join("\n")
    raise "Missing future-table grants" unless grants.include?("ALTER DEFAULT PRIVILEGES FOR ROLE \"#{users[1][0]}\" IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO \"#{users[0][0]}\"")
    raise "Missing future-sequence grants" unless grants.include?("ALTER DEFAULT PRIVILEGES FOR ROLE \"#{users[1][0]}\" IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO \"#{users[0][0]}\"")
  else
    raise "Recovery must reference its ObjectStore" unless cluster.fetch("externalClusters").first.fetch("plugin").fetch("parameters").fetch("barmanObjectName") == resource.call("ObjectStore", "-postgres-recovery-source").dig("metadata", "name")
  end

  pod = resource.call("Deployment").dig("spec", "template", "spec")
  job_pod = resource.call("Job").dig("spec", "template", "spec")
  job_container = job_pod.fetch("containers").first
  raise "Migration and application images must match" unless job_container["image"] == pod.fetch("containers").first.fetch("image")
  raise "Wrong booking-tool migration command" unless job_container["command"] == ["/srv/roclub-booking"] && job_container["args"] == ["migrate", "up", "--config", "/srv/migrate.yaml"]
  mount = job_container.fetch("volumeMounts").first
  raise "Migration config must be mounted at its CLI path" unless mount["mountPath"] == "/srv/migrate.yaml" && mount["subPath"] == "migrate.yaml" && mount["readOnly"]
  raise "Migration config volume must reference its ConfigMap" unless job_pod.fetch("volumes").first.dig("configMap", "name") == resource.call("ConfigMap", "-migration-config").dig("metadata", "name")
  raise "Job must not mount a Kubernetes token" unless job_pod["automountServiceAccountToken"] == false
  raise "Runtime must not mount a Kubernetes token" unless pod["automountServiceAccountToken"] == false
  selector = resource.call("Service").dig("spec", "selector")
  job_labels = resource.call("Job").dig("spec", "template", "metadata", "labels")
  raise "Service must not select migration Pods" if selector.all? { |key, value| job_labels[key] == value }
  puts "#{File.basename(path)}: role separation, URL encoding, bootstrap/recovery and migration Job passed"
end
