fluent-stackdrvier
==================

[Fluentd](http://www.fluentd.org) plugin for [stackdriver.com](http://stackdriver.com) API.

This is unofficially Fluentd output plugin for StackDriver.
NOTE: This project is under developing and only supported on
[GCE](https://cloud.google.com/products/compute-engine/) for now.

Configs
===========
    <match *>
      type stackdriver
      stackdriver_url https://custom-gateway.stackdriver.com/v1/custom
      cloud_type      gce
      api_key         XXXXXXXXXXX
    </match>
