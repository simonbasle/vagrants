#Vagrant files for Couchbase Server VMS

System for quickly and painlessly provisioning Couchbase Server virtual machines across multiple Couchbase versions and OS's.
## Starting a Couchbase cluster

If vagrant and VirtualBox are installed, it is very easy to get started with a 4 node cluster.

See this blog post for more info: http://nitschinger.at/A-Couchbase-Cluster-in-Minutes-with-Vagrant-and-Puppet

Just change into the appropriate directory and call `vagrant up`. Everything else will be done for you, but you need
internet access.

Additionally, you can specify the number of nodes to provision from the command line by using the environment variable VAGRANT_NODES. For example: `VAGRANT_NODES=3 vagrant up` will provision a 3 node cluster. If you do not specify a number a 4 node cluster will be created by default. `VAGRANT_CPUS` and `VAGRANT_RAM` are also available.

**IP Address Ranges:**

Base range:192.168.xxx.10x where xxx is calculated based on the Couchbase Server version and the OS:

|       |  centos5  |  centos6  |  centos7  |  debian7  |  ubuntu10 |  ubuntu12 |  ubuntu14 |  windows  |
|:-----:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| 1.8.1 |        16 |        32 |        48 |        64 |        80 |        96 |       112 |       128 |
| 2.0.1 |        17 |        33 |        49 |        65 |        81 |        97 |       113 |       129 |
| 2.1.1 |        18 |        34 |        50 |        66 |        82 |        98 |       114 |       130 |
| 2.2.0 |        19 |        35 |        51 |        67 |        83 |        99 |       115 |       131 |
| 2.5.0 |        20 |        36 |        52 |        68 |        84 |       100 |       116 |       132 |
| 2.5.1 |        21 |        37 |        53 |        69 |        85 |       101 |       117 |       133 |
| 2.5.2 |        22 |        38 |        54 |        70 |        86 |       102 |       118 |       134 |
| 3.0.0 |        23 |        39 |        55 |        71 |        87 |       103 |       119 |       135 |
| 3.0.1 |        24 |        40 |        56 |        72 |        88 |       104 |       120 |       136 |
| 3.0.2 |        25 |        41 |        57 |        73 |        89 |       105 |       121 |       137 |
| cbdev |        31 |        47 |        63 |        79 |        95 |       111 |       127 |       143 |

Thus an Ubuntu12 box running 2.5.1 will have the ip 192.168.101.10x, a Centos6 box running version 3.0.2 will have the ip 192.168.41.10x, simples!

# Building Couchbase

The subdirectory `cbdev_ubuntu_1204` contains a Vagrant configuration for
building Couchbase from source; for Ubuntu 12.04. With this you should be able to build the master branch with the following:

*outside on host*:

    cd cbdev_ubuntu_1204
    vagrant up; vagrant ssh

*inside vagrant VM*:

    mkdir couchbase; cd couchbase
    repo init -u git://github.com/couchbase/manifest -m branch-master.xml
    repo sync
    make
    cd ns_server; ./cluster_run --nodes=1

To build a specific release, change the `branch-master.xml` file to be one of the release files from the [manifests repository][1]. Look for filenames of the form `rel-X.x.x.xml`.
e.g. to build 2.5.1 from source you would change the above `repo init` command to be:

    repo init -u git://github.com/couchbase/manifest -m rel-2.5.1.xml

[1]: https://github.com/couchbase/manifest

See https://github.com/couchbase/tlm/ more information on building Couchbase from source.

## Vagrant and KVM

Vagrant by default uses Virtualbox as the VM hypervisor. This is a
good general-purpose solution, but is not as performant compared to
KVM, particulary for SMP, network-heavy workloads.

Vagrant can instead be configured to use KVM as it backend, using the
vagrant-libvirt plugin.

*Note:* KVM and Virtualbox VMs **cannot** both run at the same time -
if you try to start a KVM VM when a Virtualbox VM is running, the KVM
VM will not start (and vice versa).

This requires:

1.  A one-off configuration of the KVM plugin into Vagrant.
2.  For each VM:
    a.  Ensuring the base-box is available for libvirt
    b.  Any backend-specific settings (CPUs, memory) are also set for libvirt.

### Installing vagrant-libvirt

Follow the installation instructions at the plugin's [homepage](https://github.com/pradels/vagrant-libvirt#installation)


### Updating a VM for use in KVM

Most of the Vagrant settings for a VM will work unchanged between
Virtualbox and KVM, however there are two exceptions. Firstly a base
box supporting libvirt is needed - the easiest method is to convert an
existing (non-libvirt) basebox to libvirt format.

#### Convert a base-box to libvirt format.

The [Vagrant-Mutate](https://github.com/sciurus/vagrant-mutate) plugin
is the simplest method, as it can directly convert an existing
base-box to libvirt.

1.  Install vagrant-mutate with:

        $ vagrant plugin install vagrant-mutate

2.  Determine the box which needs converting. This is a one-off
    process for each box you wish to use. The easiest way to do this
    is to attempt to start the (non-libvirt) VM you wish to use, and
    note the name of the box in the Vagrant error message - for example:

        $ vagrant up --provider=libvirt node1

        ...
        The box you're attempting to add doesn't support the provider
        you requested. Please find an alternate box or use an alternate
        provider. Double-check your requested provider to verify you didn't
        simply misspell it.

        Name: centos-6.5-64
        Address: https://vagrantcloud.com/puppetlabs/centos-6.5-64-puppet
        Requested provider: [:libvirt]

    Make a note of the box name (`centos-6.5-64` here).

3.  Use `vagrant mutate` to create a libvirt version of the box.

        $ vagrant mutate centos-6.5-64 libvirt

#### Update any provider-specific settings

If you have set hardware-level settings (memory, CPU count) in the
Vagrantfile for virtualbox then these need an equivilent setting for
libvirt. For example, the virtualbox settings:

    config.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end

Will require an equivilent, additional stanza for libvirt adding to the Vagrantfile:

    config.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end

See the [Domain Specific Options](https://github.com/pradels/vagrant-libvirt#domain-specific-options)
in the vagrant-libvirt documentation for a complete list of possible
options.

##### Running with KVM

You should now be able to bring up the VM using libvirt (KVM):

    $ vagrant up --provider=libvirt node1


Note that most (all?) normal vagrant commands should work as before
(vagrant ssh, vagrant halt, etc), the only important different is to
specify `--provider=libvirt` to the `vagrant up`
command. Alternatively you can make this the default by setting

    $ export VAGRANT_DEFAULT_PROVIDER=libvirt

## Repo Maintenance
To reduce code duplication and ease maintenance faffery this repo makes heavy use of vagrants ability to join multiple vagrant files together. As such you should only ever have to change the top level Vagrant file and puppet.pp.

### Add a new Couchbase Version:
Clone any of the existing directories and add any required values to the ip_addresses and couchbase_download_links hashes in the top level Vagrant file.

### Add a new OS
Clone any of the existing directories and add an entry in the vagrant_boxes hash in the top level Vagrant file. You may also have to adjust the startup routine in puppet.pp.
