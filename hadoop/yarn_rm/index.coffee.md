
# YARN ResourceManager

[Yarn ResourceManager ](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html) is the central authority that manages resources and schedules applications running atop of YARN.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba-ambari-takeover/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: 'ryba-ambari-takeover/zookeeper/server'
        hdfs_client: module: 'ryba-ambari-takeover/hadoop/hdfs_client', required: true
        hdfs_dn: module: 'ryba-ambari-takeover/hadoop/hdfs_dn', required: true
        mapred_jhs: module: 'ryba-ambari-takeover/hadoop/mapred_jhs', single: true
        yarn_ts: module: 'ryba-ambari-takeover/hadoop/yarn_ts', single: true
        yarn_nm: module: 'ryba-ambari-takeover/hadoop/yarn_nm'
        yarn_rm: module: 'ryba-ambari-takeover/hadoop/yarn_rm'
        ranger_admin: module: 'ryba/ranger/admin'
        metrics: module: 'ryba/metrics', local: true
        log4j: module: 'ryba/log4j', local: true
        yarn: module: 'ryba-ambari-takeover/hadoop/yarn', required: true
        ambari_server: module: 'ryba-ambari-takeover/server', single: true, required: true
      configure:
        'ryba-ambari-takeover/hadoop/yarn_rm/configure'
      commands:
        # 'backup':
        #   'ryba-ambari-takeover/hadoop/yarn_rm/backup'
        'check':
          'ryba-ambari-takeover/hadoop/yarn_rm/check'
        'report': [
          'masson/bootstrap/report'
          'ryba-ambari-takeover/hadoop/yarn_rm/report'
        ]
        'install': [
          'ryba-ambari-takeover/hadoop/yarn_rm/install'
          'ryba-ambari-takeover/hadoop/yarn_rm/scheduler'
          'ryba-ambari-takeover/hadoop/yarn_rm/start'
          'ryba-ambari-takeover/hadoop/yarn_rm/check'
        ]
        'start':
          'ryba-ambari-takeover/hadoop/yarn_rm/start'
        'status':
          'ryba-ambari-takeover/hadoop/yarn_rm/status'
        'stop':
          'ryba-ambari-takeover/hadoop/yarn_rm/stop'
        'takeover': [
          'ryba-ambari-takeover/hadoop/yarn_rm/install'
          'ryba-ambari-takeover/hadoop/yarn_rm/takeover'
          'ryba-ambari-takeover/hadoop/yarn_rm/start'
          'ryba-ambari-takeover/hadoop/yarn_rm/wait'
          'ryba-ambari-takeover/hadoop/yarn_rm/check'
        ]

[restart]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html
[ml_root_acl]: http://lucene.472066.n3.nabble.com/Yarn-HA-Zookeeper-ACLs-td4138735.html
[cloudera_ha]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_rm_ha_config.html
[cloudera_wp]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_ha_yarn_work_preserving_recovery.html
[hdp_wp]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/bk_yarn_resource_mgt/content/ch_work-preserving_restart.html
[YARN-128]: https://issues.apache.org/jira/browse/YARN-128
[YARN-128-pdf]: https://issues.apache.org/jira/secure/attachment/12552867/RMRestartPhase1.pdf
[YARN-556]: https://issues.apache.org/jira/browse/YARN-556
[YARN-556-pdf]: https://issues.apache.org/jira/secure/attachment/12599562/Work%20Preserving%20RM%20Restart.pdf
