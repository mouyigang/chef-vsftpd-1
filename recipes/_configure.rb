# encoding: utf-8

# Include service definition now
include_recipe 'vsftpd::_define_service'

directory node['vsftpd']['config']['user_config_dir'] do
  action :create
  user 'root'
  group 'root'
  mode '755'
  recursive true
end

config = value_for_platform_family(
  'rhel' => '/etc/vsftpd/vsftpd.conf',
  'redhat' => '/etc/vsftpd/vsftpd.conf',
  'centos' => '/etc/vsftpd/vsftpd.conf',
  'debian' => '/etc/vsftpd.conf'
)
datafolder = node['vsftpd']['datafolder']
ftpuser = node['vsftpd']['config']['guest_username']
group "#{ftpuser}" do
  system true
  action :create
end
user "#{ftpuser}" do
  comment "ftp user"
  home "/home/#{ftpuser}"
  group "#{ftpuser}"
  shell "/usr/sbin/nologin"
  system true
  action :create
end
directory "/home/#{ftpuser}" do
  user "#{ftpuser}"
  group "#{ftpuser}"
  mode 00755
  action :create
end
directory "#{datafolder}" do
  user "#{ftpuser}"
  group "#{ftpuser}"
  mode 00755
  action :create
end
node['vsftpd']['allowed'].each do |username|
  directory "#{datafolder}/#{username}" do
    user "#{ftpuser}"
    group "#{ftpuser}"
    mode 00755
    action :create
  end
  #link data folder to ftpuser home
  link "/home/#{ftpuser}/#{username}" do
    to "#{datafolder}/#{username}"
    user "#{ftpuser}"
    group "#{ftpuser}"
    mode 00755
  end
  #virtuser conf file
  file "#{node['vsftpd']['config']['user_config_dir']}/#{username}" do
    user 'root'
    group 'root'
    content "local_root=/home/#{ftpuser}/#{username}"
    mode 00640
    action :create
  end
end

# rubocop:disable Style/LineLength,
{ 'vsftpd.conf.erb' => config,
  'vsftpd.chroot_list.erb' => node['vsftpd']['config']['chroot_list_file'],
  'vsftpd.virtuser_list.erb' => node['vsftpd']['chroot_virtuser_file'],
  'vsftpd.pam.vsftpd.erb' => node['vsftpd']['chroot_virtuser_pam_file'],
  'vsftpd.user_list.erb' => node['vsftpd']['config']['userlist_file'] }.each do |template, destination|
  # rubocop:enable Style/LineLength
  template destination do
    source template
    notifies :restart, 'service[vsftpd]', :delayed
  end
end

bash 'Generate pam db file' do
  etcdir = node['vsftpd']['etcdir']
  code <<-EOH
    db_load -T -t hash -f #{etcdir}/vsftpd.virtuser_list #{etcdir}/virtusers.db
  EOH
end
