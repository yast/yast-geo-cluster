# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	include/geo-cluster/helps.ycp
# Package:	Configuration of geo-cluster
# Summary:	Help texts of all the dialogs
# Authors:	Dongmao Zhang <dmzhang@suse.com>
#
# $Id: helps.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module GeoClusterHelpsInclude
    def initialize_geo_cluster_helps(include_target)
      textdomain "geo-cluster"

      # All helps are here
      @HELPS = {
        "confs" => "<p><b>configure files</b><br> \n" +
          "Geo cluster support Multi confs, like /etc/booth/*.conf \n" +
            "<p>",
        "booth" => "<p><b>transport</b><br> \n" +
          "transport means which transport layer booth daemon will use<br>\n" +
          "Currently only UDP is supported</p>" +
          "<p><b>port</b><br>\nThe port that booth daemons will use to talk to each other.<br>\n" +
            "Defaulte port is 9929.\n" +
            "<p>" +
          "<p><b>arbitrator</b><br>\n" +
            "The arbitrator IP\n" +
            "<p>" +
          "<p><b>site</b><br>\n" +
            "The cluster site uses this IP to talk to other sites\n" +
            "<p>" +
          "<p><b>ticket</b><br>\n" +
            "The ticket name, which corresponds to a set of resources which can be<br>\n" +
            "fail-overed among different sites. Use the '__default__' ticket to set<br>\n" +
            "the default value of ticket\n" +
            "<p>",
        "geo-cluster" => "<p><b>Firewall Settings</b><br> \n" +
          "Enable the port when Firewall is enabled.\n" +
            "<p>"
      } 

      # EOF
    end
  end
end
