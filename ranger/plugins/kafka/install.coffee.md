
# Ranger Kafka Plugin Install

    module.exports = header: 'Ranger Kafka Plugin', handler: ({options}) ->
      version= null


## Wait

      @call 'ryba-ambari-takeover/ranger/hdpadmin/wait', once: true, options.wait_ranger_admin

## Register

      @registry.register ['ambari','configs','update'], 'ryba-ambari-actions/lib/configs/update'

## Packages

      @service
        name: "ranger-kafka-plugin"

## Audit Layout

Matchs step 1 in [hdfs plugin configuration][plugin]. Instead of using the web ui
we execute this task using the rest api.


      @system.mkdir
        header: 'HDFS Spool Dir'
        if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        target: options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        uid: options.kafka_user.name
        gid: options.hadoop_group.name
        mode: 0o0750
      @system.mkdir
        header: 'Solr Spool Dir'
        if: options.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'
        target: options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: options.kafka_user.name
        gid: options.kafka_group.name
        mode: 0o0750


Note, by default, we're are using the same Ranger principal for every
plugin and the principal is created by the Ranger Admin service. Chances
are that a customer user will need specific ACLs but this hasn't been
tested.

      @krb5.addprinc options.krb5.admin,
        header: 'Plugin Principal'
        principal: "#{options.service_repo.configs.username}"
        password: options.service_repo.configs.password

## SSL

The Ranger Plugin does not use its truststore configuration when using solrJClient.
Must add certificate to JAVA Cacerts file manually.

TODO: remove CA from JAVA_HOME cacerts in a future version.

      @java.keystore_add
        keystore: "/usr/java/default/jre/lib/security/cacerts"
        storepass: 'changeit'
        caname: "hadoop_root_ca"
        cacert: "#{options.ssl.cacert.source}"
        local: "#{options.ssl.cacert.local}"
## SSL

      @call header: 'SSL', ->
        # Client: import certificate to all hosts
        @java.keystore_add
          keystore: options.configurations['ranger-kafka-policymgr-ssl']['xasecure.policymgr.clientssl.truststore']
          storepass: options.configurations['ranger-kafka-policymgr-ssl']['xasecure.policymgr.clientssl.truststore.password']
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: "#{options.ssl.cacert.local}"
        # Server: import certificates, private and public keys to hosts with a server
        @java.keystore_add
          keystore: options.configurations['ranger-kafka-policymgr-ssl']['xasecure.policymgr.clientssl.keystore']
          storepass: options.configurations['ranger-kafka-policymgr-ssl']['xasecure.policymgr.clientssl.keystore.password']
          key: "#{options.ssl.key.source}"
          cert: "#{options.ssl.cert.source}"
          keypass: options.configurations['ranger-kafka-policymgr-ssl']['xasecure.policymgr.clientssl.keystore.password']
          name: "#{options.ssl.key.name}"
          local: "#{options.ssl.key.local}"
        @java.keystore_add
          keystore: options.configurations['ranger-kafka-policymgr-ssl']['xasecure.policymgr.clientssl.keystore']
          storepass: options.configurations['ranger-kafka-policymgr-ssl']['xasecure.policymgr.clientssl.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: "#{options.ssl.cacert.local}"
        @system.execute
          code_skipped: 1
          header: "Fix Plugin repository permission"
          cmd: "chown -R #{options.user.name}:#{options.hadoop_group.name} /etc/ranger/#{options.install['REPOSITORY_NAME']}"

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require 'ryba/lib/mkcmd'
    fs = require 'ssh2-fs'

[plugin]: https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_kafka_plugin
