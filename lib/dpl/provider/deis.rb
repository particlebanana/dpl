module DPL
  class Provider
    class Deis < Provider

      requires 'git'

      def install_deploy_dependencies
        install_url = determine_install_url
        context.shell "curl -sSL #{install_url} | bash -x -s #{option(:cli_version)}"
      end

      #Default to installing the default v1 client. Otherwise determine if this is a v2 client
      def determine_install_url
         if option(:cli_version).nil?
           return "http://deis.io/deis-cli/install.sh"
         else
           version_arg = Gem::Version.new(option(:cli_version).gsub(/^v?V?/,''))
           if version_arg >= Gem::Version.new('2.0.0')
             return "http://deis.io/deis-cli/install-v2.sh"
           else
             return "http://deis.io/deis-cli/install.sh"
           end
         end
      end

      def needs_key?
        true
      end

      def check_auth
        unless context.shell "./deis login #{option(:controller)}" \
                      " --username=#{option(:username)}" \
                      " --password=#{option(:password)}"
          error 'Login failed.'
        end
      end

      def check_app
        unless context.shell "./deis apps:info --app=#{option(:app)}"
          error 'Application could not be verified.'
        end
      end

      def setup_key(file)
        unless context.shell "./deis keys:add #{file}"
          error 'Adding keys failed.'
        end
      end

      def setup_git_ssh(path, key_path)
        key_path = File.expand_path(key_path)
        path     = File.expand_path(path)

        File.open(path, 'w') do |file|
          file.write "#!/bin/sh\n"
          file.write "exec ssh #{verbose_flag} -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null -i #{key_path} \"$@\"\n"
        end

        chmod(0740, path)
        context.env['GIT_SSH'] = path

        unless context.shell "./deis git:remote --app=#{option(:app)}"
          error 'Adding git remote failed.'
        end

      end

      def remove_key
        unless context.shell "./deis keys:remove #{option(:key_name)}"
          error 'Removing keys failed.'
        end
      end

      def push_app
        unless context.shell "bash -c 'git push #{verbose_flag} deis HEAD:refs/heads/master -f 2>&1 | tr -dc \"[:alnum:][:space:][:punct:]\" | sed -E \"s/remote: (\\[1G)+//\" | sed \"s/\\[K$//\"; exit ${PIPESTATUS[0]}'"
          error 'Deploying application failed.'
        end
      end

      def run(command)
        unless context.shell "deis run -- #{command}"
          error 'Running command failed.'
        end
      end

      def cleanup
        return if options[:skip_cleanup]
        context.shell "mv deis ~/deis"
        super
        context.shell "mv ~/deis deis"
      end

      def verbose_flag
        '-v' if options[:verbose]
      end
    end
  end
end
