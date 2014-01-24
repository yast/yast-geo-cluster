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

# File:	include/geo-cluster/dialogs.ycp
# Package:	Configuration of geo-cluster
# Summary:	Dialogs definitions
# Authors:	Dongmao Zhang <dmzhang@suse.com>
#
# $Id: dialogs.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module GeoClusterDialogsInclude
    def initialize_dialogs(include_target)
      Yast.import "UI"

      textdomain "geo-cluster"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "GeoCluster"
      Yast.import "Popup"
      Yast.import "IP"
      Yast.import "CWMFirewallInterfaces"

      Yast.include include_target, "geo-cluster/helps.rb"
    end

    def cluster_configure_layout
      VBox(
        HBox(
          InputField(
            Id(:arbitrator),
            Opt(:hstretch),
            _("arbitrator ip"),
            Ops.get(GeoCluster.global_conf, "arbitrator", "")
          ),
          ComboBox(
            Id(:transport),
            Opt(:hstretch, :notify),
            _("transport"),
            [Ops.get(GeoCluster.global_conf, "transport", "UDP")]
          ),
          InputField(
            Id(:port),
            Opt(:hstretch),
            _("port"),
            Ops.get(GeoCluster.global_conf, "port", "")
          )
        ),
        HBox(
          SelectionBox(Id(:site_box), _("site")),
          Bottom(
            VBox(
              PushButton(Id(:site_add), _("Add")),
              PushButton(Id(:site_edit), _("Edit")),
              PushButton(Id(:site_del), _("Delete"))
            )
          )
        ),
        HBox(
          SelectionBox(Id(:ticket_box), _("ticket")),
          Bottom(
            VBox(
              PushButton(Id(:ticket_add), _("Add")),
              PushButton(Id(:ticket_edit), _("Edit")),
              PushButton(Id(:ticket_del), _("Delete"))
            )
          )
        )
      )
    end


    # return `cacel or a string
    def ip_address_input_dialog(title, value)
      ret = nil

      UI.OpenDialog(
        MarginBox(
          1,
          1,
          VBox(
            MinWidth(100, InputField(Id(:text), Opt(:hstretch), title, value)),
            VSpacing(1),
            Right(
              HBox(
                PushButton(Id(:ok), _("OK")),
                PushButton(Id(:cancel), _("Cancel"))
              )
            )
          )
        )
      )
      while true
        ret = UI.UserInput
        if ret == :ok
          val = Convert.to_string(UI.QueryWidget(:text, :Value))
          if IP.Check(val) == true
            ret = val
            break
          else
            Popup.Message("Please enter valid ip address")
          end
        end
        break if ret == :cancel
      end
      UI.CloseDialog
      deep_copy(ret)
    end

    def ticket_input_dialog(value)
      ret = nil
      timeout = ""
      ticket = ""
      #parser value first
      temp = Builtins.splitstring(value, ";")
      ticket = Ops.get_string(temp, 0, "")
      timeout = Ops.get_string(temp, 1, "")

      UI.OpenDialog(
        MarginBox(
          1,
          1,
          VBox(
            Label(_("Enter ticket and timeout")),
            HBox(
              InputField(Id(:ticket), Opt(:hstretch), _("ticket"), ticket),
              InputField(Id(:timeout), Opt(:hstretch), _("timeout"), timeout)
            ),
            VSpacing(1),
            Right(
              HBox(
                PushButton(Id(:ok), _("OK")),
                PushButton(Id(:cancel), _("Cancel"))
              )
            )
          )
        )
      )
      while true
        ret = UI.UserInput
        if ret == :ok
          ticket = Convert.to_string(UI.QueryWidget(:ticket, :Value))
          timeout = Convert.to_string(UI.QueryWidget(:timeout, :Value))
          num = Builtins.tointeger(timeout)
          if num == nil && timeout != ""
            Popup.Message(_("timeout is no valid"))
          elsif ticket == ""
            Popup.Message(_("ticket can not be null"))
          else
            break
          end
        end
        break if ret == :cancel
      end
      UI.CloseDialog
      ret = ticket
      if timeout != "" && ticket != ""
        ret = Ops.add(Ops.add(Convert.to_string(ret), ";"), timeout)
      end
      deep_copy(ret)
    end
    #fill site_box with global_site
    def fill_sites_entries
      i = 0
      ret = 0
      current = 0
      items = []
      Builtins.foreach(GeoCluster.global_site) do |value|
        items = Builtins.add(items, Item(Id(i), value))
        i = Ops.add(i, 1)
      end
      current = Convert.to_integer(UI.QueryWidget(:site_box, :CurrentItem))
      current = 0 if current == nil
      current = Ops.subtract(i, 1) if Ops.greater_or_equal(current, i)
      UI.ChangeWidget(:site_box, :Items, items)
      UI.ChangeWidget(:site_box, :CurrentItem, current)

      nil
    end

    #fill site_ticket with global_ticket
    def fill_ticket_entries
      i = 0
      ret = 0
      current = 0
      items = []
      Builtins.foreach(GeoCluster.global_ticket) do |value|
        items = Builtins.add(items, Item(Id(i), value))
        i = Ops.add(i, 1)
      end
      current = Convert.to_integer(UI.QueryWidget(:ticket_box, :CurrentItem))
      current = 0 if current == nil
      current = Ops.subtract(i, 1) if Ops.greater_or_equal(current, i)
      UI.ChangeWidget(:ticket_box, :Items, items)
      UI.ChangeWidget(:ticket_box, :CurrentItem, current)

      nil
    end

    def validate
      ret = true
      if Builtins.size(GeoCluster.global_site) == 0
        Popup.Message("site have to be filled")
        return false
      end

      if Builtins.size(GeoCluster.global_ticket) == 0
        Popup.Message("ticket have to be filled")
        return false
      end

      Builtins.foreach(GeoCluster.global_conf) do |key, value|
        if key == "arbitrator"
          if IP.Check(value) != true
            Popup.Message("arbitrator IP address is invalid!")
            ret = false
            raise Break
          end
        end
        if key == "port"
          num = Builtins.tointeger(value)
          if num != nil && Ops.greater_than(num, 0) &&
              Ops.less_or_equal(num, 65535)
            next
          else
            Popup.Message(Builtins.sformat("%1 is invalid", key))
            ret = false
            raise Break
          end
        end
        if value == ""
          Popup.Message(Builtins.sformat("%1 should be filled", key))
          ret = false
          raise Break
        end
      end

      ret
    end

    def ServiceDialog
      ret = nil
      event = {}
      firewall_widget = CWMFirewallInterfaces.CreateOpenFirewallWidget(
        {
          #servie:geo-cluster is the  name of /etc/sysconfig/SuSEfirewall2.d/services/geo-cluster
          "services"        => [
            "service:booth"
          ],
          "display_details" => true
        }
      )
      firewall_layout = Ops.get_term(firewall_widget, "custom_widget", VBox())
      contents = VBox(
        VSpacing(1),
        Frame("firewall settings", firewall_layout),
        VStretch()
      )
      Wizard.SetContents(
        _("Geo Cluster(geo-cluster) firewall configure"),
        firewall_layout,
        Ops.get_string(@HELPS, "geo-cluster", ""),
        true,
        true
      )
      CWMFirewallInterfaces.OpenFirewallInit(firewall_widget, "")
      while true
        event = UI.WaitForEvent
        ret = Ops.get(event, "ID")
        if ret == :next
          CWMFirewallInterfaces.OpenFirewallStore(firewall_widget, "", event)
          break
        end

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end
        break if ret == :back
        CWMFirewallInterfaces.OpenFirewallHandle(firewall_widget, "", event)
      end
      deep_copy(ret)
    end
    # Dialog for geo-cluster
    # Configure2 dialog
    # @return dialog result
    def ConfigureDialog
      # GeoCluster configure2 dialog caption
      caption = _("GeoCluster Configuration")

      # Wizard::SetContentsButtons(caption, contents, HELPS["c2"]:"",
      # 	    Label::BackButton(), Label::NextButton());

      ret = nil
      Wizard.SetContents(
        _("Geo Cluster configure"),
        cluster_configure_layout,
        Ops.get_string(@HELPS, "booth", ""),
        true,
        true
      )
      current = 0
      while true
        fill_sites_entries
        fill_ticket_entries
        ret = UI.UserInput
        if ret == :site_add
          ret = ip_address_input_dialog(
            _("Enter an IP address of your site"),
            ""
          )
          next if ret == :cancel
          GeoCluster.global_site = Builtins.add(
            GeoCluster.global_site,
            Convert.to_string(ret)
          )
        end

        if ret == :site_edit
          current = Convert.to_integer(UI.QueryWidget(:site_box, :CurrentItem))
          ret = ip_address_input_dialog(
            _("Edit IP address of your site"),
            Ops.get(GeoCluster.global_site, current, "")
          )
          next if ret == :cancel
          Ops.set(GeoCluster.global_site, current, Convert.to_string(ret))
        end
        if ret == :site_del
          current = Convert.to_integer(UI.QueryWidget(:site_box, :CurrentItem))
          GeoCluster.global_site = Builtins.remove(
            GeoCluster.global_site,
            current
          )
        end

        if ret == :ticket_add
          ret = ticket_input_dialog("")
          next if ret == :cancel
          GeoCluster.global_ticket = Builtins.add(
            GeoCluster.global_ticket,
            Convert.to_string(ret)
          )
        end

        if ret == :ticket_edit
          current = Convert.to_integer(
            UI.QueryWidget(:ticket_box, :CurrentItem)
          )
          ret = ticket_input_dialog(
            Ops.get(GeoCluster.global_ticket, current, "")
          )
          next if ret == :cancel
          Ops.set(GeoCluster.global_ticket, current, Convert.to_string(ret))
        end
        if ret == :ticket_del
          current = Convert.to_integer(
            UI.QueryWidget(:ticket_box, :CurrentItem)
          )
          GeoCluster.global_ticket = Builtins.remove(
            GeoCluster.global_ticket,
            current
          )
        end

        # abort?
        if ret == :abort || ret == :cancel || ret == :back
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :next
          Ops.set(
            GeoCluster.global_conf,
            "arbitrator",
            Convert.to_string(UI.QueryWidget(:arbitrator, :Value))
          )
          Ops.set(
            GeoCluster.global_conf,
            "port",
            Convert.to_string(UI.QueryWidget(:port, :Value))
          )
          Ops.set(
            GeoCluster.global_conf,
            "transport",
            Convert.to_string(UI.QueryWidget(:transport, :Value))
          )
          val = validate
          if val == true
            break
          else
            next
          end
        else
          Builtins.y2error("unexpected retcode: %1", ret)
          next
        end
      end

      deep_copy(ret)
    end
  end
end
