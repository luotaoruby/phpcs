class phpcs (
	$path         = '/vagrant/extensions/phpcs',
	$phpcs_config = sz_load_config()
) {

	if versioncmp( "${phpcs_config[php]}", '5.4') <= 0 {
		$php_package = 'php5'
	} else {
		$php_package = "php${phpcs_config[php]}"
	}

	package { 'php-pear':
		ensure  => latest,
		require => Package["$php_package-dev"]
	}

	package { "$php_package-dev":
		ensure  => latest,
		require => Package["$php_package-common"]
	}

	exec { 'phpcs install':
		command => 'pear install PHP_CodeSniffer',
		path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
		require => Package[ "$php_package-dev", 'php-pear',"$php_package-fpm" ],
		unless  => 'which phpcs',
		notify  => Service["$php_package-fpm"],
	}

	exec { 'wordpress cs install':
		command => 'git clone -b master https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git /vagrant/extensions/phpcs/wpcs && phpcs --config-set installed_paths /vagrant/extensions/phpcs/wpcs',
		path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
		require => [ Package['git-core'], Exec['phpcs install'] ]
	}
}