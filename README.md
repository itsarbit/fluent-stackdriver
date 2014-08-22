fluent-stackdrvier
==================

[Fluentd](http://www.fluentd.org) plugin for [stackdriver.com](http://stackdriver.com) API.

NOTE: Still work in progress, no test or further document yet.

Configs
===========
    <match *>
      type stackdriver
      stackdriver_url https://custom-gateway.stackdriver.com/v1/custom
      api_key         XXXXXXXXXXX
    </match>

