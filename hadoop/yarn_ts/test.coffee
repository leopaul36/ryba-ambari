
normalize = require 'masson/lib/config/normalize'
store = require 'masson/lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'hadoop.yarn_nm', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita
    .system.mkdir target: tmp
    .promise()
  afterEach ->
    nikita
    .system.remove tmp
    .promise()
  
  it 'validate heapsize and newsize', ->
    services = []
    store normalize
      clusters: 'ryba': services:
        'java':
          module: 'masson/commons/java'
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
        'cgroups':
          module: 'masson/core/cgroups'
          affinity: type: 'nodes', match: 'any', values: ['c.fqdn']
        'krb5_client':
          module: 'masson/core/krb5_client'
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
          options:
            admin:
              'HADOOP.RYBA':
                kadmin_principal: 'admin/admin@HADOOP.RYBA'
                kadmin_password: 'test'
                kdc: ['a.fqdn']
                admin_server: ['a.fqdn']
                kpasswd_server: 'a.fqdn'
                principals: []
            etc_krb5_conf:
              libdefaults: 'default_realm': 'HADOOP.RYBA'
              realms:
                'HADOOP.RYBA':
                  kdc: ['a.fqdn']
                  admin_server: ['a.fqdn']
                  kpasswd_server: 'a.fqdn'
        'test_user':
          module: 'ryba/commons/test_user'
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
          options:
            krb5: user:
              password: 'test123'
              password_sync: true
        'zookeeper':
          module: 'ryba-ambari-takeover/zookeeper/server'
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
        'core':
          module: "ryba-ambari-takeover/hadoop/core"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
          options: hdfs:
            user: {}
            group: {}
            krb5_user:
              password: 'test123'
        'namenode':
          module: "ryba-ambari-takeover/hadoop/hdfs_nn"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn']
          options:
            nameservice: 'rybak', hdfs_site: {}
            hdfs: user: {}, group: {}, krb5_user: password: 'test123'
        'journalnode':
          module: 'ryba-ambari-takeover/hadoop/hdfs_jn'
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
          options:
            hdfs_site: 'dfs.journalnode.edits.dir': '/var/hdfs/jn'
        'datanode':
          module: "ryba-ambari-takeover/hadoop/hdfs_dn"
          affinity: type: 'nodes', match: 'any', values: ['c.fqdn']
        'timelineserver':
          module: "ryba-ambari-takeover/hadoop/yarn_ts"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn']
          options:
            heapsize: '1024m'
            newsize: '200m'
        'historyserver':
          module: "ryba-ambari-takeover/hadoop/mapred_jhs"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn']
        'resourcemanager':
          module: "ryba-ambari-takeover/hadoop/yarn_rm"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn']
        'nodemanager':
          module: "ryba-ambari-takeover/hadoop/yarn_nm"
          affinity: type: 'nodes', match: 'any', values: ['c.fqdn']
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
        'c.fqdn': ip: '10.10.10.3'
    .chain()
    .service 'ryba', "timelineserver", (service) ->
      service.options.heapsize.should.match /([0-9]*)([mMgGkK])/
      service.options.newsize.should.match /([0-9]*)([mMgGkK])/
