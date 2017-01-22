# puppet-vra7-autosign
Puppet Policy Based Autosiging integration with VMware vRealize Automation 7

## Installation/Configuration

Add the following entry to the "[master]" section of the puppet.conf configuration file on the Puppet master.

```
autosign = $confdir/vrapolicyautosign.rb  
```

The script must be executable and accessible by the user running puppet.

```
chmod +x vrapolicyautosign.rb  
chown pe-puppet:pe-puppet vrapolicyautosign.rb or chown puppet:puppet vrapolicysign.rb for Puppet open source
```

Restart the puppet server service

```
systemctl restart pe-puppetserver or systemctl restart puppetsever for Puppet open source

```

## Configuration File
The autosign script utilizes a configuration file for storing vRA connection
information. By default the name of the file is "vrapolicyconfig.yaml" and is
stored in the "/etc/puppetlabs/puppet" directory.

```
grtvra7:
  url: https://cloudportal.grt.local
  username: administrator@vsphere.local
  password: P@$$w0rd
  tenant: vsphere.local
```
