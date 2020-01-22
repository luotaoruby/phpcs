# Install PHPCS
class phpcs (
	$config,
	$path = '/vagrant/extensions/phpcs',
) {

	if ( ! empty( $config[disabled_extensions] ) and 'chassis/phpcs' in $config[disabled_extensions] ) {
		$package = absent
	} else {
		$package = latest
	}

	if versioncmp( $config[php], '5.4') <= 0 {
		$php_package = 'php5'
	} else {
		$php_package = "php${config[php]}"
	}

	if ! defined( Package['php-pear'] ) {
		package { 'php-pear':
			ensure  => latest,
			require => [ Package["${php_package}-dev"], Apt::Ppa['ppa:ondrej/php'] ]
		}
	}

	if ! defined( Package["${php_package}-dev"] ) {
		package { "${php_package}-dev":
			ensure  => $package,
			require => Package["${php_package}-common"]
		}
	}

	if ( latest == $package ) {
		exec { 'phpcs install':
			command => 'pear install PHP_CodeSniffer',
			path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
			require => [
				Package[ "${php_package}-dev" ],
				Package[ 'php-pear'],
				Package[ "${php_package}-fpm" ],
				Package[ "${php_package}-xml" ],
			],
			unless  => 'which phpcs',
			notify  => Service["${php_package}-fpm"],
		}

		exec { 'wordpress cs install':
			command => 'git clone -b master https://github.com/WordPress/WordPress-Coding-Standards.git /vagrant/extensions/phpcs/wpcs',
			path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
			require => [ Package['git-core'], Exec['phpcs install'], File['/vagrant/extensions/phpcs/wpcs'] ]
		}

                exec { 'wordpress vip cs install':
                        command => 'git clone -b master https://github.com/Automattic/VIP-Coding-Standards.git /vagrant/extensions/phpcs/wpcs-vip && phpcs --config-set installed_paths /vagrant/extensions/phpcs/wpcs-vip',
			path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
			require => [ Package['git-core'], Exec['phpcs install'], File['/vagrant/extensions/phpcs/wpcs-vip'] ]
                }

                exec { 'register wpcs and wpcs-vip to phpcs':
                        command => 'phpcs --config-set installed_paths /vagrant/extensions/phpcs/wpcs,/vagrant/extensions/phpcs/wpcs-vip',
			path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
			require => [ Package['git-core'], Exec['phpcs install'], File['/vagrant/extensions/phpcs/wpcs'], File['/vagrant/extensions/phpcs/wpcs-vip'] ]
                }

		file { '/vagrant/extensions/phpcs/wpcs':
			ensure => absent,
			force  => true
                }

                file { '/vagrant/extensions/phpcs/wpcs-vip':
                        ensure => absent,
                        force  => true
                }
	} else {
		exec { 'phpcs uninstall':
			command => 'pear uninstall PHP_CodeSniffer',
			path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
			require => Package[ "${php_package}-dev", 'php-pear', "${php_package}-fpm" ],
			notify  => Service["${php_package}-fpm"],
		}

		file { '/vagrant/extensions/phpcs/wpcs':
			ensure => absent,
			force  => true
                }

                file { '/vagrant/extensions/phpcs/wpcs-vip':
                        ensure => absent,
                        force  => true
                }
	}
}
