
# Ambari Takeover

    module.exports = header: 'HDFS Ambari Install', handler: ({options}) ->
      
## Register

      @registry.register ['ambari','configs','update'], 'ryba-ambari-actions/lib/configs/update'
      @registry.register ['ambari','configs','get'], 'ryba-ambari-actions/lib/configs/get'
      @registry.register ['ambari','hosts','add'], 'ryba-ambari-actions/lib/hosts/add'
      @registry.register ['ambari','services','add'], 'ryba-ambari-actions/lib/services/add'
      @registry.register ['ambari','services','wait'], 'ryba-ambari-actions/lib/services/wait'
      @registry.register ['ambari','services','component_add'], 'ryba-ambari-actions/lib/services/component_add'
      @registry.register ['ambari', 'hosts', 'component_add'], "ryba-ambari-actions/lib/hosts/component_add"
      @registry.register ['ambari', 'hosts', 'component_update'], "ryba-ambari-actions/lib/hosts/component_update"
      @registry.register ['ambari','configs','groups_add'], 'ryba-ambari-actions/lib/configs/groups/add'
      @registry.register ['ambari','kerberos','descriptor', 'update'], 'ryba-ambari-actions/lib/kerberos/descriptor/update'
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Identities

      # @call
      #   if: options.post_component
      # , ->
      #   {ambari_url, ambari_admin_password, cluster_name} = options
      #   @each options.config_groups, ({options}, cb) ->
      #     {key, value} = options
      #     @ambari.configs.groups_add
      #       header: "#{key}"
      #       url: ambari_url
      #       username: 'admin'
      #       password: ambari_admin_password
      #       cluster_name: cluster_name
      #       group_name: key
      #       tag: key
      #       description: "#{key} config groups"
      #       hosts: value.hosts
      #       desired_configs: 
      #         type: value.type
      #         tag: value.tag
      #         properties: value.properties
      #     @next cb


# ## Topology
# 
# Configure the topology script to enable rack awareness to Hadoop.
# 
#       @call header: 'Topology', ->
#         @file
#           target: "#{options.conf_dir}/rack_topology.sh"
#           source: "#{__dirname}/../resources/rack_topology.sh"
#           local: true
#           uid: options.hdfs.user.name
#           gid: options.hadoop_group.name
#           mode: 0o755
#           backup: true
#         @file
#           target: "#{options.conf_dir}/rack_topology.data"
#           content: options.topology
#             .map (node) ->
#               "#{node.ip}  #{node.rack or ''}"
#             .join '\n'
#           uid: options.hdfs.user.name
#           gid: options.hadoop_group.name
#           mode: 0o755
#           backup: true
#           eof: true

# ## Keytab Directory
# 
#       @system.mkdir
#         header: 'Keytabs'
#         target: '/etc/security/keytabs'
#         uid: 'root'
#         gid: 'root' # was hadoop_group.name
#         mode: 0o0755


## Kerberos
Create HDFS Headless keytab.

      @krb5.addprinc options.krb5.admin,
        header: 'hdfs principal'
        principal: options.hdfs.krb5_user.principal
        password: options.hdfs.krb5_user.password

      @krb5.addprinc options.krb5.admin,
        header: 'hdfs principal'
        principal: options.hdfs.smoke_user.principal
        password: options.hdfs.smoke_user.password

      @krb5.ktutil.add options.krb5.admin,
        header: 'HDFS Headless keytab'
        principal: options.hdfs.krb5_user.principal
        password: options.hdfs.krb5_user.password
        keytab: '/etc/security/keytabs/hdfs.headless.keytab'
        kadmin_server: options.krb5.admin.admin_server
        mode: 0o0640
        uid: options.hdfs.user.name      
        gid: options.hadoop_group.name      

      @krb5.ktutil.add options.krb5.admin,
        header: 'HDFS Headless keytab'
        principal: options.hdfs.smoke_user.principal
        password: options.hdfs.smoke_user.password
        keytab: '/etc/security/keytabs/hdfs.headless.keytab'
        kadmin_server: options.krb5.admin.admin_server
        mode: 0o0640
        uid: options.hdfs.user.name      
        gid: options.hadoop_group.name      

## Kerberos Descriptor Artifact

      @ambari.kerberos.descriptor.update
        header: 'Kerberos Artifact Update NN'
        if: options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        stack_name: options.stack_name
        stack_version: options.stack_version
        cluster_name: options.cluster_name
        source: 'COMPOSITE'
        service: 'HDFS'
        component: 'NAMENODE'
        identities: options.identities['hdfs']

      @ambari.kerberos.descriptor.update
        header: 'Kerberos Artifact Update JN'
        if: options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        stack_name: options.stack_name
        stack_version: options.stack_version
        cluster_name: options.cluster_name
        service: 'HDFS'
        component: 'JOURNALNODE'
        source: 'COMPOSITE'
        identities: options.identities['journalnode_jn']

## Include/Exclude

The "dfs.hosts" property specifies the file that contains a list of hosts that
are permitted to connect to the namenode. The full pathname of the file must be
specified. If the value is empty, all hosts are permitted.

The "dfs.hosts.exclude" property specifies the file that contains a list of
hosts that are not permitted to connect to the namenode.  The full pathname of
the file must be specified.  If the value is empty, no hosts are excluded.

      @file
        header: 'Include'
        content: "#{options.include.join '\n'}"
        target: "#{options.configurations['hdfs-site']['dfs.hosts']}"
        eof: true
        backup: true
      @file
        header: 'Exclude'
        content: "#{options.exclude.join '\n'}"
        target: "#{options.configurations['hdfs-site']['dfs.hosts.exclude']}"
        eof: true
        backup: true

# ## SSL
# 
#       @call header: 'SSL', retry: 0, ->
#         @hconfigure
#           target: "#{options.conf_dir}/ssl-server.xml"
#           properties: options.configurations['ssl-server']
#         @hconfigure
#           target: "#{options.conf_dir}/ssl-client.xml"
#           properties: options.configurations['ssl-client']
#         # Client: import certificate to all hosts
#         @java.keystore_add
#           keystore: options.configurations['ssl-client']['ssl.client.truststore.location']
#           storepass: options.configurations['ssl-client']['ssl.client.truststore.password']
#           caname: "hadoop_root_ca"
#           cacert: "#{options.ssl.cacert.source}"
#           local: "#{options.ssl.cacert.local}"
#         # Server: import certificates, private and public keys to hosts with a server
#         @java.keystore_add
#           keystore: options.configurations['ssl-server']['ssl.server.keystore.location']
#           storepass: options.configurations['ssl-server']['ssl.server.keystore.password']
#           key: "#{options.ssl.key.source}"
#           cert: "#{options.ssl.cert.source}"
#           keypass: options.configurations['ssl-server']['ssl.server.keystore.keypassword']
#           name: "#{options.ssl.key.name}"
#           local: "#{options.ssl.key.local}"
#         @java.keystore_add
#           keystore: options.configurations['ssl-server']['ssl.server.keystore.location']
#           storepass: options.configurations['ssl-server']['ssl.server.keystore.password']
#           caname: "hadoop_root_ca"
#           cacert: "#{options.ssl.cacert.source}"
#           local: "#{options.ssl.cacert.local}"


## Render Files

      @call
        if: options.post_component
        header: 'Hadoop Env'
      , ->
          HADOOP_NAMENODE_OPTS = options.hdfs_nn_opts.base
          HADOOP_NAMENODE_OPTS += " -D#{k}=#{v}" for k, v of options.hdfs_nn_opts.java_properties
          HADOOP_NAMENODE_OPTS += " #{k}#{v}" for k, v of options.hdfs_nn_opts.jvm
          HADOOP_DATANODE_OPTS = options.hdfs_dn_opts.base
          HADOOP_DATANODE_OPTS += " -D#{k}=#{v}" for k, v of options.hdfs_dn_opts.java_properties
          HADOOP_DATANODE_OPTS += " #{k}#{v}" for k, v of options.hdfs_dn_opts.jvm
          HADOOP_JOURNALNODE_OPTS = options.hdfs_jn_opts.base
          HADOOP_JOURNALNODE_OPTS += " -D#{k}=#{v}" for k, v of options.hdfs_jn_opts.java_properties
          HADOOP_JOURNALNODE_OPTS += " #{k}#{v}" for k, v of options.hdfs_jn_opts.jvm
          HADOOP_ZKFC_OPTS = options.zkfc_opts.base
          HADOOP_ZKFC_OPTS += " -D#{k}=#{v}" for k, v of options.zkfc_opts.java_properties
          HADOOP_ZKFC_OPTS += " #{k}#{v}" for k, v of options.zkfc_opts.jvm
          @file.render
            header: 'Render'
            source: "#{__dirname}/../resources/hadoop-env.sh.ambari.j2"
            target: "#{options.cache_dir}/hadoop-env.sh"
            ssh: false
            context:
              HADOOP_NAMENODE_OPTS: HADOOP_NAMENODE_OPTS
              HADOOP_DATANODE_OPTS: HADOOP_DATANODE_OPTS
              HADOOP_JOURNALNODE_OPTS: HADOOP_JOURNALNODE_OPTS
              HADOOP_ZKFC_OPTS: HADOOP_ZKFC_OPTS

## Log4j

      @file
        header: 'HDFS Log4j'
        if: options.post_component
        target: "#{options.cache_dir}/hdfs-log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        ssh: false
        write: for k, v of options.hdfs_log4j.properties
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true
        
## Site

      @hconfigure
        if: options.post_component
        target: "#{options.cache_dir}/ssl-server.xml"
        properties: options.configurations['ssl-server']
        ssh: false
      @hconfigure
        if: options.post_component
        target: "#{options.cache_dir}/ssl-client.xml"
        ssh: false
        properties: options.configurations['ssl-client']

### HDFS Service
      
      @ambari.services.add
        header: 'HDFS Service'
        if: options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        name: 'HDFS'

## Upload Configs

## HDFS-SITE, YARN-SITE, MAPRED-SITE
Update hdfs-site.xml, yarn-site.xml, mapred-site.xml

      @ambari.configs.update
        header: 'Upload core-site'
        if: options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        config_type: 'core-site'
        cluster_name: options.cluster_name
        properties: options.configurations['core-site']

      @ambari.configs.update
        header: 'Upload hdfs-site'
        if: options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        config_type: 'hdfs-site'
        cluster_name: options.cluster_name
        properties: options.configurations['hdfs-site']
      
      @ambari.configs.update
        header: 'Upload Yarn Site'
        if: options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        config_type: 'yarn-site'
        cluster_name: options.cluster_name
        properties: options.configurations['yarn-site']

## Hadoop Policy

      @ambari.configs.update
        header: 'Hadoop Policy'
        if: options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        config_type: 'hadoop-policy'
        cluster_name: options.cluster_name
        properties: options.hadoop_policy

## Hadoop Log4j

      @ambari.configs.update
        header: 'HDFS Log4j'
        if: options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        config_type: 'hdfs-log4j'
        cluster_name: options.cluster_name
        properties: options.hdfs_log4j

## Upload Ranger HDFS Configuration to Ambari

      @ambari.configs.update
        header: 'Upload ranger-hdfs-plugin-properties'
        if : options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        config_type: 'ranger-hdfs-plugin-properties'
        cluster_name: options.cluster_name
        properties: options.configurations['ranger-hdfs-plugin-properties']

      @ambari.configs.update
        header: 'Upload ranger-hdfs-security'
        if : options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        config_type: 'ranger-hdfs-security'
        cluster_name: options.cluster_name
        properties: options.configurations['ranger-hdfs-security']

      @ambari.configs.update
        header: 'Upload ranger-hdfs-policymgr-ssl'
        if : options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        config_type: 'ranger-hdfs-policymgr-ssl'
        cluster_name: options.cluster_name
        properties: options.configurations['ranger-hdfs-policymgr-ssl']

      @ambari.configs.update
        header: 'Upload ranger-hdfs-audit'
        if : options.post_component and options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        config_type: 'ranger-hdfs-audit'
        cluster_name: options.cluster_name
        properties: options.configurations['ranger-hdfs-audit']


## HADOOP-ENV
Render hadoop-env.sh and yarn-env.sh files, before uploading to Ambari Server.

      @call
        header: 'Hadoop Env'
        if: options.post_component and options.takeover
      , (_, callback) ->
          ssh2fs.readFile null, "#{options.cache_dir}/hadoop-env.sh", (err, content) =>
            try
              throw err if err
              content = content.toString()
              @ambari.configs.update
                header: 'Update to Ambari'
                url: options.ambari_url
                username: 'admin'
                merge: true
                password: options.ambari_admin_password
                config_type: 'hadoop-env'
                cluster_name: options.cluster_name
                properties: merge {}, options.configurations['hadoop-env'], content: content.toString()
              .next callback
            catch err
              callback err


## Log4j

      @call
        header: 'HDFS Log4j'
        if: options.post_component and options.takeover
      , (_, callback) ->
          ssh2fs.readFile null, "#{options.cache_dir}/hdfs-log4j.properties", (err, content) =>
            try
              throw err if err
              content = content.toString()
              @ambari.configs.update
                header: 'Update To ambari'
                url: options.ambari_url
                username: 'admin'
                password: options.ambari_admin_password
                config_type: 'hdfs-log4j'
                cluster_name: options.cluster_name
                properties: 
                  content: content
              .next callback
            catch err
              callback err


      @call
        header: 'SSl Server'
        if: options.post_component and options.takeover
      , (_, callback) ->
          properties.read null, "#{options.cache_dir}/ssl-server.xml", (err, props) =>
            @ambari.configs.update
              header: 'config update'
              url: options.ambari_url
              username: 'admin'
              password: options.ambari_admin_password
              config_type: 'ssl-server'
              cluster_name: options.cluster_name
              properties: props
            @next callback

      @call
        header: 'SSl Client'
        if: options.post_component and options.takeover
      , (_, callback) ->
          properties.read null, "#{options.cache_dir}/ssl-client.xml", (err, props) =>
            @ambari.configs.update
              header: 'config update'
              url: options.ambari_url
              username: 'admin'
              password: options.ambari_admin_password
              config_type: 'ssl-client'
              cluster_name: options.cluster_name
              properties: props
            @next callback

## Metrics Properties
  
      # @file.properties
      #   if: options.ambari_host and options.post_component and options.takeover
      #   header: 'Metrics Render'
      #   target: "#{options.cache_dir}/hadoop-metrics2.properties"
      #   ssh: false
      #   content: options.configurations['hadoop-metrics-properties']
      # 
      # @file.download
      #   if: options.ambari_host and options.component and options.takeover
      #   header: 'Metrics Upload'
      #   target: '/var/lib/ambari-server/resources/stacks/HDP/2.0.6/hooks/before-START/templates/hadoop-metrics2.properties.j2'
      #   source: "#{options.cache_dir}/hadoop-metrics2.properties"
      #   backup: true
      #   ssh: true

## Ambari Config Groups
          
      @call
        if: options.post_component and options.takeover
      , ->
        {ambari_url, ambari_admin_password, cluster_name} = options
        @each options.config_groups, ({options}, cb) ->
          {key, value} = options
          @ambari.configs.groups_add
            header: "#{key}"
            url: ambari_url
            username: 'admin'
            password: ambari_admin_password
            cluster_name: cluster_name
            group_name: key
            tag: key
            description: "#{key} config groups"
            hosts: value.hosts
            desired_configs: 
              type: value.type
              tag: value.tag
              properties: value.properties
          @next cb

## Add Component
add NAMENODE, DATANODE, JOURNALNODE, ZKFC, MAPREDUCE RESOURCEMANAGER and NODEMANAGER
component to cluster but NOT in `INSTALLED` desired state.

### Wait HDFS Service

      @call
        if: options.post_component and options.takeover
      , ->

        @ambari.services.wait
          header: 'HDFS Service WAITED'
          url: options.ambari_url
          username: 'admin'
          password: options.ambari_admin_password
          cluster_name: options.cluster_name
          name: 'HDFS'

        @ambari.services.component_add
          header: 'NAMENODE'
          url: options.ambari_url
          username: 'admin'
          password: options.ambari_admin_password
          cluster_name: options.cluster_name
          component_name: 'NAMENODE'
          service_name: 'HDFS'

        @ambari.services.component_add
          header: 'JOURNALNODE'
          url: options.ambari_url
          username: 'admin'
          password: options.ambari_admin_password
          cluster_name: options.cluster_name
          component_name: 'JOURNALNODE'
          service_name: 'HDFS'
          
        @ambari.services.component_add
          header: 'DATANODE'
          url: options.ambari_url
          username: 'admin'
          password: options.ambari_admin_password
          cluster_name: options.cluster_name
          component_name: 'DATANODE'
          service_name: 'HDFS'
          
        @ambari.services.component_add
          header: 'ZKFC'
          url: options.ambari_url
          username: 'admin'
          password: options.ambari_admin_password
          cluster_name: options.cluster_name
          component_name: 'ZKFC'
          service_name: 'HDFS'

        @ambari.services.component_add
          header: 'HDFS_CLIENT'
          url: options.ambari_url
          username: 'admin'
          password: options.ambari_admin_password
          cluster_name: options.cluster_name
          component_name: 'HDFS_CLIENT'
          service_name: 'HDFS'

### NAMENODE COMPONENT
      
        for host in options.nn_hosts
          @ambari.hosts.component_add
            header: 'NAMENODE ADD'
            url: options.ambari_url
            username: 'admin'
            password: options.ambari_admin_password
            cluster_name: options.cluster_name
            component_name: 'NAMENODE'
            hostname: host

### JOURNALNODE COMPONENT
      
        for host in options.jn_hosts
          @ambari.hosts.component_add
            header: 'JOURNALNODE ADD'
            url: options.ambari_url
            username: 'admin'
            password: options.ambari_admin_password
            cluster_name: options.cluster_name
            component_name: 'JOURNALNODE'
            hostname: host

### DATANODE COMPONENT
      
        for host in options.dn_hosts
          @ambari.hosts.component_add
            header: 'DATANODE ADD'
            url: options.ambari_url
            username: 'admin'
            password: options.ambari_admin_password
            cluster_name: options.cluster_name
            component_name: 'DATANODE'
            hostname: host

### ZKFC COMPONENT
      
        for host in options.zkfc_hosts
          @ambari.hosts.component_add
            header: 'ZKFC ADD'
            url: options.ambari_url
            username: 'admin'
            password: options.ambari_admin_password
            cluster_name: options.cluster_name
            component_name: 'ZKFC'
            hostname: host

### ZKFC COMPONENT
      
        for host in options.client_hosts
          @ambari.hosts.component_add
            header: 'HDFS_CLIENT ADD'
            url: options.ambari_url
            username: 'admin'
            password: options.ambari_admin_password
            cluster_name: options.cluster_name
            component_name: 'HDFS_CLIENT'
            hostname: host

## Dependencies

    {merge} = require 'nikita/lib/misc'
    fs = require 'fs'
    ssh2fs = require 'ssh2-fs'
    properties = require 'ryba/lib/properties'
