
# Hive Client Configuration

Example:

```json
{
  "ryba": {
    "hive": {
      "client": {
        opts": "-Xmx4096m",
        heapsize": "1024"
      }
    }
  }
}
```

    module.exports = (service) ->
      options = service.options

## Identities

      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge service.deps.hive_server2[0].options.group, options.group
      options.user = merge service.deps.hive_server2[0].options.user, options.user

## Kerberos

      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Environment

      # Layout
      options.conf_dir ?= '/etc/hive/conf'
      # Opts and Java
      options.java_home ?= service.deps.java.options.java_home
      options.opts ?= {}
      options.heapsize ?= '1024'
      options.aux_jars_paths ?= {}
      for path, val of service.deps.hive_hcatalog[0].options.aux_jars_paths
        options.aux_jars_paths[path] ?= val
      #aux_jars forced by ryba to guaranty consistency
      options.aux_jars = "#{Object.keys(options.aux_jars_paths).join ':'}"
      # Misc
      options.hostname ?= service.node.hostname
      options.force_check ?= false
      options.fqdn ?= service.node.fqdn

## Import HiveServer2 Configuration

      options.hive_site ?= {}
      for property in [
        'hive.server2.authentication'
        'hive.server2.authentication.kerberos.principal'
        'hive.server2.authentication'
        'hive.server2.transport.mode'
        'hive.server2.use.SSL'
        'hive.server2.thrift.http.port'
        'hive.server2.thrift.port'
        # Transaction, read/write locks
        'hive.execution.engine'
        'hive.zookeeper.quorum'
        'hive.server2.thrift.sasl.qop'
        'hive.optimize.mapjoin.mapreduce'
        'hive.heapsize'
        'hive.auto.convert.sortmerge.join.noconditionaltask'
        'hive.exec.max.created.files'
      ] then options.hive_site[property] ?= service.deps.hive_server2[0].options.hive_site[property]

## Configure SSL

      options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl
      options.truststore_location ?= "#{options.conf_dir}/truststore"
      options.truststore_password ?= options.ssl.truststore.password

## Test

      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin
      options.ranger_install = service.deps.ranger_hive[0].options.install if service.deps.ranger_hive
      options.test = merge {}, service.deps.test_user.options, options.test
      # Hive Server2
      options.hive_server2 = for srv in service.deps.hive_server2
        fqdn: srv.options.fqdn
        hostname: srv.options.hostname
        hive_site: srv.options.hive_site
      # Spark Thrift Server
      options.spark_thrift_server = for srv in service.deps.spark_thrift_server or []
        fqdn: srv.options.fqdn
        hostname: srv.options.hostname

## Wait

      options.wait_hive_server2 = service.deps.hive_server2[0].options.wait
      options.wait_spark_thrift_server = service.deps.spark_thrift_server?.options?.wait if service.deps.spark_thrift_server
      options.wait_ranger_admin = service.deps.ranger_admin.options.wait if service.deps.ranger_admin

## Ambari REST API

      #ambari server configuration
      options.post_component = service.instances[0].node.fqdn is service.node.fqdn
      options.ambari_host = service.node.fqdn is service.deps.ambari_server.node.fqdn
      options.ambari_url ?= service.deps.ambari_server.options.ambari_url
      options.ambari_admin_password ?= service.deps.ambari_server.options.ambari_admin_password
      options.cluster_name ?= service.deps.ambari_server.options.cluster_name
      options.takeover = service.deps.ambari_server.options.takeover
      options.baremetal = service.deps.ambari_server.options.baremetal

## Ambari Configurations
Enrich `ryba-ambari-takeover/hive/service` with hive/server2 properties.
  
      enrich_config = (source, target) ->
        for k, v of source
          target[k] ?= v
          
      for srv in service.deps.hive
        srv.options.configurations ?= {}
        #hive-site
        srv.options.configurations['hive-site'] ?= {}
        enrich_config options.hive_site, srv.options.configurations['hive-site']
        #hive-env
        srv.options.configurations['hive-env'] ?= {}
        srv.options.configurations['hive-env']['hive.client.heapsize'] ?= options.heapsize
        srv.options.beeline_opts ?= options.opts
        srv.options.beeline_aux_jars ? options.aux_jars
        #add hosts
        srv.options.beeline_hosts ?= []
        srv.options.beeline_hosts.push service.node.fqdn if srv.options.beeline_hosts.indexOf(service.node.fqdn) is -1

## Dependencies

    {merge} = require 'nikita/lib/misc'
