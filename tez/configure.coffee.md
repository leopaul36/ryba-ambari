
## Configuration

    module.exports = (service) ->
      options = service.options

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'tez'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'tez'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.groups ?= 'hadoop'
      options.user.comment ?= 'Tez User'
      options.user.home ?= '/var/lib/tez'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= 64000


## Environment

      options.env ?= {}
      options.env['TEZ_CONF_DIR'] ?= '/etc/tez/conf'
      options.env['TEZ_JARS'] ?= '/usr/hdp/current/tez-client/*:/usr/hdp/current/tez-client/lib/*'
      options.env['HADOOP_CLASSPATH'] ?= '$TEZ_CONF_DIR:$TEZ_JARS:$HADOOP_CLASSPATH'
      # Misc
      options.hostname = service.node.hostname
      options.fqdn ?= service.node.fqdn
      options.force_check ?= false

## Kerberos

      # Kerberos HDFS Admin
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Configuration

      options.tez_site ?= {}
      options.tez_site['tez.lib.uris'] ?= "/hdp/apps/${hdp.version}/tez/tez.tar.gz"
      # For documentation purpose in case we HDFS_DELEGATION_TOKEN in hive queries
      # Following line: options.tez_site['tez.am.am.complete.cancel.delegation.tokens'] ?= 'false'
      # Renamed to: options.tez_site['tez.cancel.delegation.tokens.on.completion'] ?= 'false'
      # Validation
      # Java.lang.IllegalArgumentException: tez.runtime.io.sort.mb 512 should be larger than 0 and should be less than the available task memory (MB):364
      # throw Error '' options.tez_site['tez.runtime.io.sort.mb']

## Resource Allocation

      memory_per_container = 512
      rm_memory_max_mb = service.deps.yarn_rm[0].options.yarn_site['yarn.scheduler.maximum-allocation-mb']
      rm_memory_min_mb = service.deps.yarn_rm[0].options.yarn_site['yarn.scheduler.minimum-allocation-mb']
      am_memory_mb = options.tez_site['tez.am.resource.memory.mb'] or memory_per_container
      am_memory_mb = Math.min rm_memory_max_mb, am_memory_mb
      am_memory_mb = Math.max rm_memory_min_mb, am_memory_mb
      options.tez_site['tez.am.resource.memory.mb'] ?= am_memory_mb
      tez_memory_xmx = /-Xmx(.*?)m/.exec(options.tez_site['hive.tez.java.opts'])?[1] or Math.floor .8 * am_memory_mb
      tez_memory_xmx = Math.min rm_memory_max_mb, tez_memory_xmx
      options.tez_site['hive.tez.java.opts'] ?= "-Xmx#{tez_memory_xmx}m"

## Deprecated warning

Convert [deprecated values][dep] between HDP 2.1 and HDP 2.2.

      deprecated = {}
      deprecated['tez.am.java.opts'] = 'tez.am.launch.cmd-opts'
      deprecated['tez.am.env'] = 'tez.am.launch.env'
      deprecated['tez.am.shuffle-vertex-manager.min-src-fraction'] = 'tez.shuffle-vertex-manager.min-src-fraction'
      deprecated['tez.am.shuffle-vertex-manager.max-src-fraction'] = 'tez.shuffle-vertex-manager.max-src-fraction'
      deprecated['tez.am.shuffle-vertex-manager.enable.auto-parallel'] = 'tez.shuffle-vertex-manager.enable.auto-parallel'
      deprecated['tez.am.shuffle-vertex-manager.desired-task-input-size'] = 'tez.shuffle-vertex-manager.desired-task-input-size'
      deprecated['tez.am.shuffle-vertex-manager.min-task-parallelism'] = 'tez.shuffle-vertex-manager.min-task-parallelism'
      deprecated['tez.am.grouping.split-count'] = 'tez.grouping.split-count'
      deprecated['tez.am.grouping.by-length'] = 'tez.grouping.by-length'
      deprecated['tez.am.grouping.by-count'] = 'tez.grouping.by-count'
      deprecated['tez.am.grouping.max-size'] = 'tez.grouping.max-size'
      deprecated['tez.am.grouping.min-size'] = 'tez.grouping.min-size'
      deprecated['tez.am.grouping.rack-split-reduction'] = 'tez.grouping.rack-split-reduction'
      deprecated['tez.am.am.complete.cancel.delegation.tokens'] = 'tez.cancel.delegation.tokens.on.completion'
      deprecated['tez.am.max.task.attempts'] = 'tez.am.task.max.failed.attempts'
      deprecated['tez.generate.dag.viz'] = 'tez.generate.debug.artifacts'
      deprecated['tez.runtime.intermediate-output.key.comparator.class'] = 'tez.runtime.key.comparator.class'
      deprecated['tez.runtime.intermediate-output.key.class'] = 'tez.runtime.key.class'
      deprecated['tez.runtime.intermediate-output.value.class'] = 'tez.runtime.value.class'
      deprecated['tez.runtime.intermediate-output.should-compress'] = 'tez.runtime.compress'
      deprecated['tez.runtime.intermediate-output.compress.codec'] = 'tez.runtime.compress.codec'
      deprecated['tez.runtime.intermediate-input.key.secondary.comparator.class'] = 'tez.runtime.key.secondary.comparator.class'
      deprecated['tez.runtime.broadcast.data-via-events.enabled'] = 'tez.runtime.transfer.data-via-events.enabled'
      deprecated['tez.runtime.broadcast.data-via-events.max-size'] = 'tez.runtime.transfer.data-via-events.max-size'
      deprecated['tez.runtime.shuffle.input.buffer.percent'] = 'tez.runtime.shuffle.fetch.buffer.percent'
      deprecated['tez.runtime.task.input.buffer.percent'] = 'tez.runtime.task.input.post-merge.buffer.percent'
      deprecated['tez.runtime.job.counters.max'] = 'tez.am.counters.max.keys'
      deprecated['tez.runtime.job.counters.group.name.max'] = 'tez.am.counters.group-name.max.keys'
      deprecated['tez.runtime.job.counters.counter.name.max'] = 'tez.am.counters.name.max.keys'
      deprecated['tez.runtime.job.counters.groups.max'] = 'tez.am.counters.groups.max.keys'
      deprecated['tez.task.merge.progress.records'] = 'tez.runtime.merge.progress.records'
      deprecated['tez.runtime.metrics.session.id'] = 'tez.runtime.framework.metrics.session.id'
      deprecated['tez.task.scale.memory.additional.reservation.fraction.per-io'] = 'tez.task.scale.memory.additional-reservation.fraction.per-io'
      deprecated['tez.task.scale.memory.additional.reservation.fraction.max'] = 'tez.task.scale.memory.additional-reservation.fraction.max'
      deprecated['tez.task.initial.memory.scale.ratios'] = 'tez.task.scale.memory.ratios'
      deprecated['tez.resource.calculator.process-tree.class'] = 'tez.task.resource.calculator.process-tree.class'
      for previous, current of deprecated
        continue unless options.tez_site[previous]
        options.tez_site[current] = options.tez_site[previous]
        console.log "Deprecated property '#{previous}' [WARN]"

## Tez Ports

Enrich the Yarn NodeManager with additionnal IPTables rules.

      # Range of ports that the AM can use when binding for client connections
      options.tez_site['tez.am.client.am.port-range'] ?= '34816-36864'
      for srv in service.deps.yarn_nm
        srv.options.iptables_rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: options.tez_site['tez.am.client.am.port-range'].replace('-',':'), protocol: 'tcp', state: 'NEW', comment: "Tez AM Range" }

# ## UI
# 
#       options.ui ?= {}
#       options.ui.enabled ?= !!service.deps.httpd
#       if options.ui.enabled
#         options.ui.env ?= {}
#         options.ui.env.hosts ?= {}
#         unless options.tez_site['tez.tez-ui.history-url.base'] and options.ui.html_path
#           unless service.deps.httpd
#             throw 'Install masson/commons/httpd on ' + service.node.fqdn + ' or specify tez_site[\'tez.tez-ui.history-url.base\'] and ui.html_path if ui.enabled'
#           options.tez_site['tez.tez-ui.history-url.base'] ?= "http://#{service.node.fqdn}/tez-ui"
#           options.ui.html_path ?= "#{service.deps.httpd.options.user.home}/tez-ui"
#         id = if service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.ha.id']}" else ''
#         options.ui.env.hosts.timeline ?= if service.deps.yarn_ts[0].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
#         then "http://" + service.deps.yarn_ts[0].options.yarn_site['yarn.timeline-service.webapp.address']
#         else "https://"+ service.deps.yarn_ts[0].options.yarn_site['yarn.timeline-service.webapp.https.address']
#         options.ui.env.hosts.rm ?= if service.deps.yarn_rm[0].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
#         then "http://" + service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.address#{id}"]
#         else "https://"+ service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.https.address#{id}"]
#         ## Tez Site when UI is enabled
#         options.tez_site['tez.runtime.convert.user-payload.to.history-text'] ?= 'true'
#         options.tez_site['tez.history.logging.service.class'] ?= 'org.apache.tez.dag.history.logging.ats.ATSHistoryLoggingService'

## Ambari REST API

      #ambari server configuration
      options.post_component = service.instances[0].node.fqdn is service.node.fqdn
      options.ambari_host = service.node.fqdn is service.deps.ambari_server.node.fqdn
      options.ambari_url ?= service.deps.ambari_server.options.ambari_url
      options.ambari_admin_password ?= service.deps.ambari_server.options.ambari_admin_password
      options.cluster_name ?= service.deps.ambari_server.options.cluster_name
      options.stack_name ?= service.deps.ambari_server.options.stack_name
      options.stack_version ?= service.deps.ambari_server.options.stack_version
      options.takeover = service.deps.ambari_server.options.takeover
      options.baremetal = service.deps.ambari_server.options.baremetal

## Ambari Configurations
Enrich `ryba-ambari-takeover/hive/service` with TEZ properties.
  
      enrich_config = (source, target) ->
        for k, v of source
          target[k] ?= v
          
      for srv in service.deps.hive
        srv.options.configurations ?= {}
        #hive-site
        srv.options.configurations['tez-site'] ?= {}
        enrich_config options.tez_site, srv.options.configurations['tez-site']
        #hive-env
        srv.options.configurations['tez-env'] ?=
        srv.options.server2_opts ?= options.opts
        srv.options.server2_aux_jars ? options.aux_jars

## Log4j Properties

        srv.options.hive_log4j ?= {}
        enrich_config options.log4j.properties, options.hive_log4j if service.deps.log4j?

## Log4j Properties

        srv.options.configurations['hiveserver2-site'] ?= {}
        enrich_config options.hiveserver2_site, srv.options.configurations['hiveserver2-site']
      # 
      # 
      # 
      options.configurations ?= {}
      # #tez-site
      # options.configurations['tez-site'] ?= {}
      # for k, v of options.tez_site
      #   options.configurations['tez-site'][k] ?= v
      # #tez-env
      options.configurations['tez-env'] ?= {}
      options.configurations['tez-env']['enable_heap_dump'] ?= 'false'
      options.configurations['tez-env']['heap_dump_location'] ?= '/tmp'
      options.configurations['tez-env']['tez_user'] ?= options.user.name
      options.configurations['tez-site'] ?= {}
      for k,v of options.tez_site
        options.configurations['tez-site'][k] ?= v
        
## Ambari Configurations
Enrich `ryba-ambari-takeover/hive/service` with TEZ properties.
  
      enrich_config = (source, target) ->
        for k, v of source
          target[k] ?= v
          
      for srv in service.deps.hive
        srv.options.configurations ?= {}
        #hive-site
        srv.options.configurations['tez-site'] ?= {}
        enrich_config options.tez_site, srv.options.configurations['tez-site']
        #hive-env
        srv.options.configurations['tez-env'] ?= {}
        srv.options.configurations['tez-env']['enable_heap_dump'] ?= 'false'
        srv.options.configurations['tez-env']['heap_dump_location'] ?= '/tmp'
        srv.options.configurations['tez-env']['tez_user'] ?= options.user.name
        srv.options.configurations['tez-env']['conf_dir'] ?= options.env['TEZ_CONF_DIR']
        #add hosts
        srv.options.tez_hosts ?= []
        srv.options.tez_hosts.push service.node.fqdn if srv.options.tez_hosts.indexOf(service.node.fqdn) is -1

## Ambari Agent - Register Hosts
Register users to ambari agent's user list.

      for srv in service.deps.ambari_agent
        srv.options.users ?= {}
        srv.options.users['tez'] ?= options.user
        srv.options.groups ?= {}
        srv.options.groups['tez'] ?= options.group
      

[tez]: http://tez.apache.org/
[instructions]: (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.8.4)
[dep]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/bk_upgrading_hdp_manually/content/start-tez-21.html
