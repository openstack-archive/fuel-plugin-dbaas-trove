.. _overview:

Document purpose
================

This document provides instructions for installing, configuring and using
OpenStack Trove plugin for Fuel.


OpenStack Trove plugin
----------------------

The OpenStack Trove plugin provides ability to install an OpenStack
environment with Trove deployed on dedicated nodes. Trove provides
scalable and reliable Cloud Database as a Service provisioning functionality
for both relational and non-relational database engines, and to continue to
improve its fully-featured and extensible open source framework.

Plugin is hot-pluggable and It can be enabled in a new environment or existing
deployed environment without the plugin.

Requirements
------------

+----------------------------+--------------------+
| Requirement                | Version/Comment    |
+============================+====================+
| Fuel                       | 8.0 release        |
+----------------------------+--------------------+
| OpenStack compatibility    | Liberty            |
+----------------------------+--------------------+
| Operating systems          | Ubuntu 14.04 LTS   |
+----------------------------+--------------------+


Limitations
-----------

OpenStack Trove plugin deploys a dedicated RabbitMQ Cluster on Trove nodes for
for security reasons.
`Dedicated RabbitMQ <http://lists.openstack.org/pipermail/openstack-dev/2015-April/061759.html/>`_.

If the OpenStack Trove plugin is enabled for an environment, it is impossible
to assign Trove and Controller roles to the same node.

There is a Detach RabbitMQ plugin, which enable user to install RabbitMQ
on separate nodes. Detach RabbitMQ plugin role should not be used together
with Trove plugin role, User should ensure that:

 * Trove and RabbitMQ roles shoud not to be assigned to the same nodes
