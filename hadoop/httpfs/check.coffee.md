
# HDFS HttpFS Check

    module.exports = header: 'HDFS HttpFS Check', handler: ({options}) ->

## Assert Connection

      @connection.assert
        header: 'HTTP'
        servers: options.wait.http.filter (srv) -> srv.host is options.fqdn
        retry: 3
        sleep: 3000

TODO: Test the HTTP server with a JMX request.

List the files and diretory from the HDFS root.

      protocol = if options.env.HTTPFS_SSL_ENABLED is 'true' then 'https' else 'http'
      @system.execute
        header: 'List Files'
        cmd: mkcmd.test options.test_krb5_user, """
        curl --fail -k --negotiate -u: \
          #{protocol}://#{options.fqdn}:#{options.http_port}/webhdfs/v1?op=GETFILESTATUS
        """
      , (err, data, stderr) ->
        throw Error "Invalid output" unless JSON.parse(data.stdout).FileStatus.type is 'DIRECTORY'

# Dependencies

    mkcmd = require 'ryba/lib/mkcmd'
