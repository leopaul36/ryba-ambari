
# HAdoop HDFS JournalNode

Wait transactions to be synced

    module.exports = header: 'Ranger Admin TakeOver', handler: ({options}) ->
      @service.stop
        header: 'Stop'
        name: 'ranger-admin'
      @system.remove
        header: 'Remove initd file'
        target: '/etc/init.d/zookeeper-server'
        code_skipped: 1
      @system.execute
        header: 'Daemon reload'
        cmd: 'systemctl daemon-reload;systemctl reset-failed'
        code_skipped: 1
      # @system.remove
      #   header: 'Remove old keytab'
      #   target: '/etc/security/keytabs/zookeeper.service.keytab'
      #   code_skipped: 1