
# HBase Client Configuration

    module.exports = (service) ->
      options = service.options

# Identities

      options.group = merge service.deps.hbase_master[0].options.group, options.group
      options.user = merge service.deps.hbase_master[0].options.user, options.user
      # Krb5 admin user
      options.admin = merge service.deps.hbase_master[0].options.admin, options.admin
      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Environment

      # Layout
      options.conf_dir ?= '/etc/hbase/conf'
      options.log_dir ?= '/var/log/hbase'
      # Java
      options.env ?=  {}
      options.env['HBASE_LOG_DIR'] ?= "#{options.log_dir}"
      options.java_home ?= "#{service.deps.java.options.java_home}"
      # Misc
      options.hostname ?= service.node.hostname
      options.force_check ?= true
      options.is_ha ?= service.deps.hbase_master.length
      options.fqdn ?= service.node.fqdn

## System Options

      options.opts ?= {}
      options.opts.base ?= ''
      options.opts.java_properties ?= {}
      options.opts.jvm ?= {}
      options.opts.jvm['-Xms'] ?= options.heapsize
      options.opts.jvm['-Xmx'] ?= options.heapsize
      options.opts.jvm['-XX:NewSize='] ?= options.newsize #should be 1/8 of hbase regionserver heapsize
      options.opts.jvm['-XX:MaxNewSize='] ?= options.newsize #should be 1/8 of hbase regionserver heapsize

## Test

      options.ranger_install = service.deps.ranger_hbase[0].options.install if service.deps.ranger_hbase
      options.test = merge {}, service.deps.test_user.options, options.test
      options.test.namespace ?= "ryba_check_client_#{service.node.hostname}"
      options.test.table ?= 'a_table'

## Configuration

      options.hbase_site ?= {}

## Configure Security

      options.hbase_site['hbase.security.authentication'] = service.deps.hbase_master[0].options.hbase_site['hbase.security.authentication']
      options.hbase_site['hbase.security.authorization'] = service.deps.hbase_master[0].options.hbase_site['hbase.security.authorization']
      options.hbase_site['hbase.superuser'] = service.deps.hbase_master[0].options.hbase_site['hbase.superuser']
      options.hbase_site['hbase.rpc.engine'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.rpc.engine']
      options.hbase_site['hbase.bulkload.staging.dir'] = service.deps.hbase_master[0].options.hbase_site['hbase.bulkload.staging.dir']
      options.hbase_site['hbase.master.kerberos.principal'] = service.deps.hbase_master[0].options.hbase_site['hbase.master.kerberos.principal']
      options.hbase_site['hbase.regionserver.kerberos.principal'] = service.deps.hbase_master[0].options.hbase_site['hbase.regionserver.kerberos.principal']
      #add jaas
      options.opts.java_properties['java.security.auth.login.config'] ?= "#{options.conf_dir}/hbase-client.jaas"


## HBase Replication

      options.hbase_site['hbase.replication'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.replication']

## Client Configuration HA Reads

      if parseInt(service.deps.hbase_master[0].options.hbase_site['hbase.meta.replica.count']) > 1
        options.hbase_site['hbase.ipc.client.specificThreadForWriting'] ?= 'true'
        options.hbase_site['hbase.client.primaryCallTimeout.get'] ?= '10000'
        options.hbase_site['hbase.client.primaryCallTimeout.multiget'] ?= '10000'
        options.hbase_site['hbase.client.primaryCallTimeout.scan'] ?= '1000000'
        options.hbase_site['hbase.meta.replicas.use'] ?= 'true'

## Configuration Distributed mode

      for property in [
        'zookeeper.znode.parent'
        'zookeeper.session.timeout'
        'hbase.cluster.distributed'
        'hbase.rootdir'
        'hbase.zookeeper.quorum'
        'hbase.zookeeper.property.clientPort'
        'dfs.domain.socket.path'
      ] then options.hbase_site[property] ?= service.deps.hbase_master[0].options.hbase_site[property]

## Configuration Quota

      options.hbase_site['hbase.quota.enabled'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.quota.enabled']
      options.hbase_site['hbase.quota.refresh.period'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.quota.refresh.period']

## Wait

      options.wait_hbase_master = service.deps.hbase_master[0].options.wait
      options.wait_hbase_regionserver = service.deps.hbase_regionserver[0].options.wait
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

## HBase Configuration
Enrich `ryba-ambari-takeover/hbase/master` with regionservers properties.
  
      enrich_config = (source, target) ->
        for k, v of source
          target[k] ?= v
      
      for srv in service.deps.hbase
        srv.options.configurations ?= {}
        srv.options.configurations['hbase-site'] ?= {}
        enrich_config options.hbase_site , srv.options.configurations['hbase-site']
        #add hosts
        srv.options.client_hosts ?= []
        srv.options.client_hosts.push options.fqdn if srv.options.client_hosts.indexOf(options.fqdn) is -1

## System Options
      
        # Env
        srv.options.configurations['hbase-env'] ?= {}
        # opts
        # enrich_config options.opts , srv.options.client_opts
        enrich_config options.opts , srv.options.opts


## Log4j Properties

        srv.options.hbase_log4j ?= {}
        enrich_config options.log4j.properties, options.hbase_log4j if service.deps.metrics?

## Dependencies

    {merge} = require 'nikita/lib/misc'
