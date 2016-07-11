.. _installation:

Installation Guide
==================

#. Start with `installing Fuel Master node`_.

#. Install `Fuel Plugin Builder on Fuel Master node`_.

#. Install Git on Fuel Master node::

      [root@fuel ~]# yum install git -y

#. Clone the plugin from `Github`_.
    
      [root@fuel ~]# git clone http://github.com/openstack/fuel-plugin-dbaas-trove.git -b stable/8.0

#. Build the plugin::
   
      [root@fuel ~]# cd fuel-plugin-dbaas-trove
      [root@fuel ~]# fpb --build .

 
#. Install the plugin::

      [root@fuel ~]# fuel plugins --install fuel-plugin-dbaas-trove-1.0-1.0.3-1.noarch.rpm

#. Verify that the plugin is installed correctly::

      [root@nailgun ~]# fuel plugins
      id | name                    | version | package_version
      ---|-------------------------|---------|----------------
      1  | fuel-plugin-dbaas-trove | 1.0.3  | 4.0.0



.. target-notes::
.. _installing Fuel Master node: https://docs.mirantis.com/openstack/fuel/fuel-8.0/fuel-install-guide.html#introduction-to-fuel-installation
.. _Fuel Plugin Builder on Fuel Master node: https://wiki.openstack.org/wiki/Fuel/Plugins#install_latest
.. _Github: http://github.com/openstack/fuel-plugin-dbaas-trove.git
