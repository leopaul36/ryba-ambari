
# HiveServer2 Configuration

The following properties are required by knox in secured mode:

*   hive.server2.enable.doAs
*   hive.server2.allow.user.substitution
*   hive.server2.transport.mode
*   hive.server2.thrift.http.port
*   hive.server2.thrift.http.path

Example:

```json
{ "ryba": {
    "hive": {
      "server2": {
        "heapsize": "4096",
        "opts": "-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=130.98.196.54 -Dcom.sun.management.jmxremote.rmi.port=9526 -Dcom.sun.management.jmxremote.port=9526 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
      },
      "site": {
        "hive.server2.thrift.port": "10001"
      }
    }
} }
```

    module.exports = (service) ->
      options = service.options

## Identities

      # Hadoop Group
      options.hadoop_group = service.deps.hadoop_core.options.hadoop_group
      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'oozie'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'oozie'
      options.user.system ?= true
      options.user.gid ?= 'oozie'
      options.user.comment ?= 'Oozie User'
      options.user.home ?= '/var/lib/oozie'
      options.user.groups ?= 'hadoop'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= 32000

## Environment

      # Layout
      options.conf_dir ?= '/etc/oozie/conf'
      options.data_dir ?= '/var/db/oozie'
      options.log_dir ?= '/var/log/oozie'
      options.pid_dir ?= '/var/run/oozie'
      options.tmp_dir ?= '/var/tmp/oozie'
      # Opts and Java
      options.java_home ?= service.deps.java.options.java_home
      options.heapsize ?= '1024'
      # Misc
      options.fqdn = service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]

      options.hdfs_krb5_user = service.deps.hdfs[0].options.hdfs.krb5_user
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## SSL

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      options.ssl.truststore ?= {}
      if options.ssl.enabled
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        options.ssl.keystore.target = "#{options.conf_dir}/keystore"
        throw Error "Required Property: ssl.keystore.password" if not options.ssl.keystore.password
        options.ssl.truststore.target = "#{options.conf_dir}/truststore"
        throw Error "Required Property: ssl.truststore.password" if not options.ssl.truststore.password

## Oozie Layout

      options.server_hosts ?= []
      options.client_hosts ?= []

## Ambari REST API

      #ambari server configuration
      options.post_component = service.instances[0].node.fqdn is service.node.fqdn
      options.ambari_host = service.node.fqdn is service.deps.ambari_server.node.fqdn
      options.ambari_url ?= service.deps.ambari_server.options.ambari_url
      options.ambari_admin_password ?= service.deps.ambari_server.options.ambari_admin_password
      options.cluster_name = service.deps.ambari_server.options.cluster_name
      options.stack_name ?= service.deps.ambari_server.options.stack_name
      options.stack_version ?= service.deps.ambari_server.options.stack_version
      options.takeover = service.deps.ambari_server.options.takeover
      options.baremetal = service.deps.ambari_server.options.baremetal

## Ambari Configurations

      options.configurations ?= {}
      options.configurations['oozie-site'] ?= {}
      options.configurations['oozie-env'] ?= {}
      options.configurations['oozie-env']['oozie_java_home'] ?= options.java_home

## Ambari Agent
Register users to ambari agent's user list.

      for srv in service.deps.ambari_agent
        srv.options.users ?= {}
        srv.options.users['oozie'] ?= options.user
        srv.options.groups ?= {}
        srv.options.groups['oozie'] ?= options.group

## Ambari Config Groups
`config_groups` contains final object that install will submit to ambari.
`groups` is the array of config_groups name to which the host belongs to.

      options.config_groups ?= {}
      options.groups ?= []
      for srv in service.deps.oozie
        for name in options.groups
          srv.options.config_groups ?= {}
          srv.options.config_groups[name] ?= {}
          srv.options.config_groups[name]['hosts'] ?= []
          srv.options.config_groups[name]['hosts'].push service.node.fqdn unless srv.options.config_groups[name]['hosts'].indexOf(service.node.fqdn) > -1
      
## Dependencies

    {merge} = require 'nikita/lib/misc'
