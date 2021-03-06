
# Hive & HCatalog Client

    module.exports = header: 'Ambari Hive Client Install', handler: ({options}) ->

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['ambari', 'hosts', 'component_install'], "ryba-ambari-actions/lib/hosts/component_install"
      @registry.register ['ambari', 'hosts', 'component_add'], "ryba-ambari-actions/lib/hosts/component_add"
      @registry.register ['ambari', 'hosts', 'component_wait'], "ryba-ambari-actions/lib/hosts/component_wait"

## Install Component

      @ambari.hosts.component_add
        header: 'HCAT'
        if: options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        component_name: 'HCAT'
        hostname: options.fqdn
        
      @ambari.hosts.component_wait
        header: 'HCAT'
        if: options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        component_name: 'HCAT'
        hostname: options.fqdn

      @ambari.hosts.component_install
        header: 'HCAT'
        if: options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        component_name: 'HCAT'
        hostname: options.fqdn

      @ambari.hosts.component_add
        header: 'HIVE_CLIENT'
        if: options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        component_name: 'HIVE_CLIENT'
        hostname: options.fqdn

      @ambari.hosts.component_wait
        header: 'HIVE_CLIENT'
        if: options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        component_name: 'HIVE_CLIENT'
        hostname: options.fqdn

      @ambari.hosts.component_install
        header: 'HIVE_CLIENT'
        if: options.takeover
        url: options.ambari_url
        username: 'admin'
        password: options.ambari_admin_password
        cluster_name: options.cluster_name
        component_name: 'HIVE_CLIENT'
        hostname: options.fqdn


## SSL
Install client truststore

      @java.keystore_add
        header: 'Client SSL'
        keystore: options.truststore_location
        storepass: options.truststore_password
        caname: "hadoop_root_ca"
        cacert: "#{options.ssl.cacert.source}"
        local: "#{options.ssl.cacert.local}"

