package { 'python-software-properties':
        ensure  =>  latest,
}
exec { "/usr/bin/apt-add-repository ppa:yjwong/cmake && /usr/bin/apt-get update":
    alias   => "ppa_cmake",
    require => Package["python-software-properties"],
    creates => "/etc/apt/sources.list.d/yjwong-cmake.list"
}

# Needed for building couchbase
$build_deps = [ "build-essential", "git", "cmake", "libevent-dev",
                "libcurl4-openssl-dev", "libicu-dev", "libsnappy-dev",
                "libv8-dev", "erlang", "erlang-src" ]
package { $build_deps:
        ensure => "installed",
        require => Exec["ppa_cmake"]
}

# Needed for pre-cmake (<3.0.0) builds:
$old_build_deps = [ "automake", "libtool", "libunwind7-dev", "cloog-ppl" ]
package { $old_build_deps:
        ensure => "installed"
}
exec {"/usr/bin/curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo && chmod a+x /usr/local/bin/repo":
     alias => "install_repo",
     creates => "/usr/local/bin/repo"
}

# Google perftools (for tcmalloc). Not sure if this is needed for 3.0.0+
exec {"/usr/bin/curl -O https://gperftools.googlecode.com/files/gperftools-2.1.tar.gz":
     alias   => "download_gperftools",
     cwd     => "/tmp",
     creates => "/tmp/gperftools-2.1.tar.gz"
}
exec {"/bin/tar xfz gperftools-2.1.tar.gz && cd gperftools-2.1 && ./configure && make -j4 && make install":
     alias => "install_gperftools",
     cwd =>  "/tmp",
     require => Exec["download_gperftools"]
}
