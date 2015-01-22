# encoding: utf-8

package 'vsftpd'
case node['platform_family']
when 'debian'
	package 'db-util'
when 'rhel', 'fedora'
	package 'db4-devel'
end
