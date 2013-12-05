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

# File:	modules/GeoCluster.ycp
# Package:	Configuration of geo-cluster
# Summary:	GeoCluster settings, input and output functions
# Authors:	Dongmao Zhang <dmzhang@suse.com>
#
# $Id: GeoCluster.ycp 41350 2007-10-10 16:59:00Z dfiser $
#
# Representation of the configuration of geo-cluster.
# Input and output routines.
require "yast"

module Yast
  class GeoClusterClass < Module
    def main
      textdomain "geo-cluster"

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Message"
      Yast.import "SuSEFirewall"
      Yast.import "SuSEFirewallServices"

      # Data was modified?
      @modified = false


      @proposal_valid = false

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false

      # Abort function
      # return boolean return true if abort
      @AbortFunction = fun_ref(method(:Modified), "boolean ()")


      # Settings: Define all variables needed for configuration of geo-cluster
      # TODO FIXME: Define all the variables necessary to hold
      # TODO FIXME: the configuration here (with the appropriate
      # TODO FIXME: description)
      # TODO FIXME: For example:
      #   /**
      #    * List of the configured cards.
      #    */
      #   list cards = [];
      #
      #   /**
      #    * Some additional parameter needed for the configuration.
      #    */
      #   boolean additional_parameter = true;
      # Read all geo-cluster settings
      # @return true on success
      @global_conf = { "transport" => "UDP", "port" => "", "arbitrator" => "" }
      @global_site = [""]
      @global_ticket = [""]
    end

    # Abort function
    # @return [Boolean] return true if abort
    def Abort
      return @AbortFunction.call == true if @AbortFunction != nil
      false
    end

    # Data was modified?
    # @return true if modified
    def Modified
      Builtins.y2debug("modified=%1", @modified)
      @modified
    end

    # Mark as modified, for Autoyast.
    def SetModified(value)
      @modified = true

      nil
    end

    def ProposalValid
      @proposal_valid
    end

    def SetProposalValid(value)
      @proposal_valid = value

      nil
    end

    # @return true if module is marked as "write only" (don't start services etc...)
    def WriteOnly
      @write_only
    end

    # Set write_only flag (for autoinstalation).
    def SetWriteOnly(value)
      @write_only = value

      nil
    end


    def SetAbortFunction(function)
      function = deep_copy(function)
      @AbortFunction = deep_copy(function)

      nil
    end

    def remove_quote(str)
      str = Builtins.regexpsub(str, "^\"?(.*)", "\\1")
      if Builtins.regexpmatch(str, ".*\"$")
        str = Builtins.regexpsub(str, "^(.*)\"$", "\\1")
      end
      str
    end

    def remove_list_quote(stringlist)
      stringlist = deep_copy(stringlist)
      i = 0
      while Ops.less_than(i, Builtins.size(stringlist))
        Ops.set(stringlist, i, remove_quote(Ops.get(stringlist, i, "")))
        i = Ops.add(i, 1)
      end
      deep_copy(stringlist)
    end

    def add_quote(str)
      Ops.add(Ops.add("\"", str), "\"")
    end

    def add_list_quote(stringlist)
      stringlist = deep_copy(stringlist)
      temp = remove_list_quote(stringlist)
      i = 0
      while Ops.less_than(i, Builtins.size(stringlist))
        Ops.set(stringlist, i, add_quote(Ops.get(temp, i, "")))
        i = Ops.add(i, 1)
      end
      deep_copy(stringlist)
    end


    def Read
      # GeoCluster read dialog caption
      caption = _("Initializing geo-cluster Configuration")

      # TODO FIXME Set the right number of stages
      steps = 2

      sl = 500
      Builtins.sleep(sl)

      # TODO FIXME Names of real stages
      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [_("Read the previous settings"), _("Read SuSEFirewall Settings")],
        [
          _("Reading the previous settings..."),
          _("Read SuSEFirewall Settings"),
          _("Finished")
        ],
        ""
      )



      # read port, arbitrator, transport
      Builtins.foreach(@global_conf) do |key, value|
        temp = Convert.convert(
          SCR.Read(Ops.add(path(".booth"), Builtins.topath(key))),
          :from => "any",
          :to   => "list <string>"
        )
        Ops.set(@global_conf, key, remove_quote(Ops.get(temp, 0, "")))
      end
      # if config file not exsit,set default of global_conf to UDP
      if Ops.get(@global_conf, "transport", "") == ""
        Ops.set(@global_conf, "transport", "UDP")
      end
      # read sites
      @global_site = Convert.convert(
        SCR.Read(Ops.add(path(".booth"), Builtins.topath("site"))),
        :from => "any",
        :to   => "list <string>"
      )
      @global_site = remove_list_quote(@global_site)

      @global_ticket = Convert.convert(
        SCR.Read(Ops.add(path(".booth"), Builtins.topath("ticket"))),
        :from => "any",
        :to   => "list <string>"
      )
      @global_ticket = remove_list_quote(@global_ticket)

      Builtins.y2milestone(
        "global_conf %1\n" +
          " global_site %2\n" +
          " global_ticket %3\n",
        @global_conf,
        @global_site,
        @global_ticket
      )

      # read
      return false if Abort()
      Progress.NextStage
      # Error message
      Report.Error(Message.CannotReadCurrentSettings) if false
      Builtins.sleep(sl)

      # read the SuSEfirewall2
      SuSEFirewall.Read


      return false if Abort()
      # Progress finished
      Progress.NextStage
      Builtins.sleep(sl)

      return false if Abort()
      @modified = false
      true
    end

    # Write all geo-cluster settings
    # @return true on success
    def Write
      # GeoCluster read dialog caption
      caption = _("Saving geo-cluster Configuration")
      ret = false

      # TODO FIXME And set the right number of stages
      steps = 3

      sl = 500
      Builtins.sleep(sl)

      # TODO FIXME Names of real stages
      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/2
          _("Write the settings"),
          # Progress stage 2/2
          _("Write the SuSEfirewall settings")
        ],
        [
          # Progress step 1/2
          _("Writing the settings..."),
          # Progress step 2/2
          _("Writing the SuSEFirewall settings"),
          # Progress finished
          _("Finished")
        ],
        ""
      )
      saved_global_conf = deep_copy(@global_conf)
      # write settings
      # write global_conf, global_site,  global_ticket to file
      Builtins.foreach(@global_conf) do |key, value|
        Ops.set(@global_conf, key, add_quote(value))
      end
      # read sites
      @global_site = add_list_quote(@global_site)
      @global_ticket = add_list_quote(@global_ticket)
      Builtins.y2milestone(
        "Writing global_conf %1\n" +
          " global_site %2\n" +
          " global_ticket %3\n",
        @global_conf,
        @global_site,
        @global_ticket
      )

      Builtins.foreach(@global_conf) do |key, val|
        write_val = nil
        write_val = [val] if val != nil
        ret = SCR.Write(
          Ops.add(path(".booth"), Builtins.topath(key)),
          write_val
        )
        Report.Error(_("Cannot write global settings.")) if !ret
      end
      #write site
      ret = SCR.Write(path(".booth.site"), @global_site)
      Report.Error(_("Cannot write sites settings.")) if !ret
      #write ticket
      ret = SCR.Write(path(".booth.ticket"), @global_ticket)
      Report.Error(_("Cannot write ticket settings.")) if !ret


      return false if Abort()
      Progress.NextStage
      # Error message
      Report.Error(_("Cannot write settings.")) if false
      Builtins.sleep(sl)

      # run SuSEconfig
      return false if Abort()
      Progress.NextStage
      # Error message
      Report.Error(Message.SuSEConfigFailed) if false
      Builtins.sleep(sl)

      udp_ports = [Ops.get(saved_global_conf, "port", "")]
      SuSEFirewallServices.SetNeededPortsAndProtocols(
        "service:booth",
        { "udp_ports" => udp_ports }
      )
      SuSEFirewall.Write
      return false if Abort()
      # Progress finished
      Progress.NextStage
      Builtins.sleep(sl)

      return false if Abort()
      true
    end

    # Get all geo-cluster settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      # TODO FIXME: your code here (fill the above mentioned variables)...
      true
    end

    # Dump the geo-cluster settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      # TODO FIXME: your code here (return the above mentioned variables)...
      {}
    end

    # Create a textual summary and a list of unconfigured cards
    # @return summary of the current configuration
    def Summary
      # TODO FIXME: your code here...
      # Configuration summary text for autoyast
      [_("Configuration summary..."), []]
    end

    # Create an overview table with all configured cards
    # @return table items
    def Overview
      # TODO FIXME: your code here...
      []
    end

    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      # TODO FIXME: your code here...
      { "install" => [], "remove" => [] }
    end

    publish :function => :Modified, :type => "boolean ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :SetModified, :type => "void (boolean)"
    publish :function => :ProposalValid, :type => "boolean ()"
    publish :function => :SetProposalValid, :type => "void (boolean)"
    publish :function => :WriteOnly, :type => "boolean ()"
    publish :function => :SetWriteOnly, :type => "void (boolean)"
    publish :function => :SetAbortFunction, :type => "void (boolean ())"
    publish :variable => :global_conf, :type => "map <string, string>"
    publish :variable => :global_site, :type => "list <string>"
    publish :variable => :global_ticket, :type => "list <string>"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "list ()"
    publish :function => :Overview, :type => "list ()"
    publish :function => :AutoPackages, :type => "map ()"
  end

  GeoCluster = GeoClusterClass.new
  GeoCluster.main
end
