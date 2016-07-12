      def install_deploy_dependencies
        cli_version="v2.0.0"
        install_url = determine_install_url
        puts "curl -sSL #{install_url} | sh -s #{cli_version}"
      end

      #Default to installing the default v1 client. Otherwise determine if this is a v2 client
      def determine_install_url
         cli_version='v2.0.0'
         if cli_version.nil?
           return "http://deis.io/deis-cli/install.sh"
         else
           version_arg = Gem::Version.new(cli_version.gsub(/^v?V?/,''))
           if version_arg >= Gem::Version.new('2.0.0')
             return "http://deis.io/deis-cli/install-v2.sh"
           else
             return "http://deis.io/deis-cli/install.sh"
           end
         end
      end

install_deploy_dependencies
