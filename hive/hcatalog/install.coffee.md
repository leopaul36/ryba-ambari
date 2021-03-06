
# Hive HCatalog Install

TODO: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

    module.exports =  header: 'Ambari Hive HCatalog Install', handler: ({options}) ->

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register 'hdfs_upload', 'ryba/lib/hdfs_upload'
      @registry.register ['ambari', 'hosts', 'component_install'], "ryba-ambari-actions/lib/hosts/component_install"
      @registry.register ['ambari', 'hosts', 'component_wait'], "ryba-ambari-actions/lib/hosts/component_wait"
      @registry.register ['ambari','configs','update'], 'ryba-ambari-actions/lib/configs/update'

## IPTables

| Service        | Port  | Proto | Parameter            |
|----------------|-------|-------|----------------------|
| Hive Metastore | 9083  | http  | hive.metastore.uris  |
| Hive Web UI    | 9999  | http  | hive.hwi.listen.port |


IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

Note, since Hive 1.3, the port is defined by "'hive.metastore.port'"

      rules =  [
        { chain: 'INPUT', jump: 'ACCEPT', dport: options.hive_site['hive.metastore.port'], protocol: 'tcp', state: 'NEW', comment: "Hive Metastore" }
        { chain: 'INPUT', jump: 'ACCEPT', dport: options.hive_site['hive.hwi.listen.port'], protocol: 'tcp', state: 'NEW', comment: "Hive Web UI" }
      ]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: parseInt(options.jmx_port,10), protocol: 'tcp', state: 'NEW', comment: "Metastore JMX" } if options.jmx_port?
      @tools.iptables
        header: 'IPTables'
        rules: rules
        if: options.iptables

## Ulimit

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

## Kerberos

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.hive_site['hive.metastore.kerberos.principal'].replace '_HOST', options.fqdn
        randkey: true
        keytab: options.hive_site['hive.metastore.kerberos.keytab.file']
        uid: options.user.name
        gid: options.group.name
        mode: 0o0600

## Layout

Create the directories to store the logs and pid information. The options
"log\_dir" and "pid\_dir" may be modified.

      @call header: 'Layout', ->
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
          parent: true
        @system.mkdir
          target: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          parent: true

## HDFS Layout

[Coudera](http://www.cloudera.com/documentation/cdh/5-1-x/CDH5-Installation-Guide/cdh5ig_filesystem_perm.html)
recommends setting permissions on the Hive warehouse directory to 1777, making it 
accessible to all users, with the sticky bit set. This allows users to create 
and access their tables, but prevents them from deleting tables they don't 
own.

      @call header: 'HDFS Layout', ->
        # cmd = mkcmd.hdfs options.hdfs_krb5_user, "hdfs dfs -config #{options.hdfs_conf_dir} -test -d /user && hdfs dfs -test -d /apps && hdfs dfs -test -d /tmp"
        # @wait.execute
        #   cmd: cmd
        #   code_skipped: 1
        # migration: wdavidw 170907, commented since the if condition disabled it
        # @system.execute
        #   cmd: mkcmd.hdfs options.hdfs_krb5_user, """
        #   if hdfs dfs -ls /user/#{hive_user} &>/dev/null; then exit 1; fi
        #   hdfs dfs -mkdir /user/#{hive_user}
        #   hdfs dfs -chown #{hive_user}:#{hdfs.user.name} /user/#{hive_user}
        #   """
        #   code_skipped: 1
        #   if: false # Disabled
        # migration: wdavidw 170907, get path from config and change permissions
        @hdfs_mkdir
          header: 'Warehouse'
          target: options.hive_site['hive.metastore.warehouse.dir']
          user: options.user.name
          group: options.group.name
          mode: 0o1777
          parent:
            mode: 0o0711
          conf_dir: options.hdfs_conf_dir
          krb5_user: options.hdfs_krb5_user
        # @system.execute
        #   cmd: mkcmd.hdfs options.hdfs_krb5_user, """
        #   if hdfs dfs -ls /apps/#{hive_user}/warehouse &>/dev/null; then exit 3; fi
        #   hdfs dfs -mkdir /apps/#{hive_user}
        #   hdfs dfs -mkdir /apps/#{hive_user}/warehouse
        #   hdfs dfs -chown -R #{hive_user}:#{hdfs.user.name} /apps/#{hive_user}
        #   hdfs dfs -chmod 755 /apps/#{hive_user}
        #   """
        #   code_skipped: 3
        # @system.execute
        #   cmd: mkcmd.hdfs options.hdfs_krb5_user, "hdfs dfs -chmod -R #{hive.warehouse_mode or '1777'} /apps/#{hive_user}/warehouse"
       # migration: wdavidw 170907, get path from config and change group ownerships
        @hdfs_mkdir
          header: 'Warehouse Dir'
          target: options.hive_site['hive.metastore.warehouse.dir']
          user: options.user.name
          group: options.group.name
          mode: options.warehouse_mode
          parent:
            mode: 0o0711
          conf_dir: options.hdfs_conf_dir
          krb5_user: options.hdfs_krb5_user
        @hdfs_mkdir
          header: 'Scratch Dir'
          target: options.hive_site['hive.exec.scratchdir']
          user: options.user.name
          group: options.group.name
          mode: 0o1777
          parent:
            mode: 0o0711
          conf_dir: options.hdfs_conf_dir
          krb5_user: options.hdfs_krb5_user
        # @system.execute
        #   cmd: mkcmd.hdfs options.hdfs_krb5_user, """
        #   if hdfs dfs -ls /tmp/scratch &> /dev/null; then exit 1; fi
        #   hdfs dfs -mkdir /tmp 2>/dev/null
        #   hdfs dfs -mkdir /tmp/scratch
        #   hdfs dfs -chown #{hive_user}:#{hdfs.user.name} /tmp/scratch
        #   hdfs dfs -chmod -R 1777 /tmp/scratch
        #   """
        #   code_skipped: 1

## Tez

      # @service
      #   header: 'Tez Package'
      #   name: 'tez'
      #   if: -> options.tez_enabled
      # @system.execute
      #   header: 'Tez Layout'
      #   if: -> options.tez_enabled
      #   cmd: 'ls /usr/hdp/current/hive-metastore/lib | grep hive-exec- | sed \'s/^hive-exec-\\(.*\\)\\.jar$/\\1/g\''
      #   shy: true
      # , (err, status, stdout) ->
      #   version = stdout.trim() unless err
      #   @hdfs_upload
      #     source: "/usr/hdp/current/hive-metastore/lib/hive-exec-#{version}.jar"
      #     target: "/apps/hive/install/hive-exec-#{version}.jar"
      #     clean: "/apps/hive/install/hive-exec-*.jar"
      #     lock: "/tmp/hive-exec-#{version}.jar"
      #     krb5_user: options.hdfs_krb5_user

## Install Component

      @ambari.hosts.component_wait
        header: 'HIVE_METASTORE wait'
        url: options.ambari_url
        if: options.takeover
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        component_name: 'HIVE_METASTORE'
        hostname: options.fqdn
      @ambari.hosts.component_wait
        header: 'HIVE_CLIENT wait'
        url: options.ambari_url
        if: options.takeover
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        component_name: 'HIVE_CLIENT'
        hostname: options.fqdn


      @ambari.hosts.component_install
        header: 'HIVE_METASTORE install'
        if: options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        component_name: 'HIVE_METASTORE'
        hostname: options.fqdn
      @ambari.hosts.component_install
        header: 'HIVE_CLIENT install'
        if: options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        component_name: 'HIVE_METASTORE'
        hostname: options.fqdn
        
      @ambari.configs.update
        header: 'Fix hadoop-env'
        if: options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        config_type: 'hadoop-env'
        cluster_name: options.cluster_name
        properties:
          'hdfs_principal_name': options.hdfs_krb5_user.name
          
          


# Module Dependencies

    path = require 'path'
    db = require 'nikita/lib/misc/db'
    mkcmd = require 'ryba/lib/mkcmd'
