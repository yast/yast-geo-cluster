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
      @global_files = {}
      @global_conf_single = { "transport" => "UDP", "port" => "9929" }
      @global_conf_list = [ "arbitrator", "site" ]
      @global_conf_ticket = { "expire" => "", "acquire-after" => "", "timeout" => "", "retries" => "", "weights" => "", "before-acquire-handler" => ""}
      @global_del_confs = []
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

    def empty_ticket(ticket)
      empty = true
      @global_conf_ticket.each_key do |key|
        empty = false if ticket[key] != ""
      end
      empty
    end

    def get_a_conf(confname)
      conf_hash = {}

      temp_path = path(".booth")+Builtins.topath(confname)

      @global_conf_single.each do |key, value|
        temp_value = SCR.Read(temp_path+Builtins.topath(key))
        if !temp_value && value
          temp_value = value
        end
        conf_hash[key] = temp_value
      end

      @global_conf_list.each do |key|
        conf_hash[key] = SCR.Read(temp_path+Builtins.topath(key))
      end

      tickets_info = {}
      temp_ticket_path = temp_path+Builtins.topath("ticket")

      tickets_list = SCR.Dir(temp_ticket_path)

      if tickets_list
        tickets_list.each do |tname|
          temp_t = {}
          @global_conf_ticket.each_key do |key|
            # Not necessary to use remove_list_quote?
            temp_t[key] = SCR.Read(temp_ticket_path+Builtins.topath(tname)+Builtins.topath(key))
          end
          tickets_info[tname] = temp_t
        end
      end
      conf_hash["ticket"] = tickets_info

      Builtins.y2debug("Get a conf: %1 = %2", confname, conf_hash)
      conf_hash
    end

    def save_a_conf(confname)
      Builtins.y2milestone("Writing configure file %1\n", confname)
      error_flag = false
      temp_path = path(".booth")+Builtins.topath(confname)
      conf = @global_files[confname]

      @global_conf_single.each_key do |key|
        Builtins.y2milestone("Writing global_conf %1 = %2\n", key, conf[key])
        ret = SCR.Write((temp_path+Builtins.topath(key)), conf[key])
        error_flag = true if !ret
      end
      (error_flag = false && Report.Error(_("Cannot write global conf settings."))) if error_flag

      # List like site
      @global_conf_list.each do |key|
        item_str = ""
        if conf[key]
          conf[key].each do |item|
            if item_str == ""
              item_str += item
            else
              item_str = item_str + ";" + item
            end
          end
        end
        Builtins.y2milestone("Writing global %1 settings. %2\n", key, item_str)
        ret = SCR.Write((temp_path+Builtins.topath(key)), item_str)
        error_flag = true if !ret
      end
      (error_flag = false && Report.Error(_("Cannot write global settings."))) if error_flag

      temp_ticket_path = temp_path + Builtins.topath("ticket")

      # Empty all tickets from ag_booth memory
      SCR.Write((temp_ticket_path + Builtins.topath("emptyallticket")), "")

      conf["ticket"].each do |tname, value|
        Builtins.y2milestone("Writing global ticket settings - %1\n", tname)

        # Empty (all Int) ticket will be ignore by ag_booth
        # Create a ticket item
        if empty_ticket(value)
          ret = SCR.Write((temp_ticket_path+Builtins.topath(tname)+Builtins.topath("ticket")), "")
          Builtins.y2milestone("Writing empty ticket - %1 \n", tname)
          error_flag = true if !ret
        else
          @global_conf_ticket.each_key do |key|
            ret = SCR.Write((temp_ticket_path+Builtins.topath(tname)+Builtins.topath(key)), value[key])
            Builtins.y2milestone("Writing ticket settings: %1 = %2\n", key, value[key])
            error_flag = true if !ret
          end
        end
      end
      (error_flag = false && Report.Error(_("Cannot write global ticket settings."))) if error_flag

      true
    end

    def Read
      # GeoCluster read dialog caption
      caption = _("Initializing geo-cluster Configuration")

      # TODO FIXME Set the right number of stages
      steps = 2

      sl = 500

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

      file_list = SCR.Dir(path(".booth.allconfs"))

      if file_list
        # Read all confs into a hash
        file_list.each do |filename|
          temp_conf = get_a_conf(filename)
          @global_files[filename] = temp_conf
        end
      end

      Builtins.y2debug("Global files = %1", @global_files)

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
      Progress.Finish
      @modified = false
      true
    end

    # Write all geo-cluster settings
    # @return true on success
    def Write
      # GeoCluster write dialog caption
      caption = _("Saving geo-cluster Configuration")
      ret = false

      # TODO FIXME And set the right number of stages
      steps = 2

      sl = 500

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

      # Remove delete confs from memory
      # Do not empty all memory in case future extend
      @global_del_confs.each do |delconf|
        SCR.Write(path(".booth")+Builtins.topath(delconf),"")
      end

      # Not necessary to add_(list)_quote
      @global_files.each_key do |key|
        save_a_conf(key)
      end

      SCR.Write(path(".booth"),"")

      return false if Abort()
      Progress.NextStage
      # Error message
      Report.Error(_("Cannot write settings.")) if false
      Builtins.sleep(sl)

      # run SuSEconfig
      return false if Abort()

      # Open all needed port of all confs
      open_ports = []
      @global_files.each_key do |file|
        temp_port = @global_files[file]["port"]

        if !open_ports.include?(temp_port)
          open_ports.push(temp_port)
        end
      end

      SuSEFirewallServices.SetNeededPortsAndProtocols(
        "service:booth",
        # Use the same udp port for tcp.
        { "tcp_ports" => open_ports,
          "udp_ports" => open_ports }
      )

      SuSEFirewall.Write
      # Error message
      Report.Error(Message.SuSEConfigFailed) if false
      Builtins.sleep(sl)

      return false if Abort()
      # Progress finished
      Progress.NextStage
      Builtins.sleep(sl)

      return false if Abort()
      Progress.Finish
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
    publish :variable => :global_files, :type => "map <string, map>"
    publish :variable => :global_conf_single, :type => "map <string, string>"
    publish :variable => :global_conf_list, :type => "list <string>"
    publish :variable => :global_conf_ticket, :type => "map <string, string>"
    publish :variable => :global_del_confs, :type => "list <string>"
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
