fluent-stackdrvier
==================

Inofficial [Fluentd](http://www.fluentd.org) plugin for [stackdriver.com](http://stackdriver.com) API.

NOTE: Still work in progress, no test or further document yet.

Usage
===========
configs
    <match *>
      type fluent-stackdriver
      stackdriver_url    https://custom-gateway.stackdriver.com/v1/custom
      api_key XXXXXXXXXXX
    </match>
contributing
============

Welcome for contributing. Please send pull request for any dedicated branch.
