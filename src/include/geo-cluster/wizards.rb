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

# File:	include/geo-cluster/wizards.ycp
# Package:	Configuration of geo-cluster
# Summary:	Wizards definitions
# Authors:	Dongmao Zhang <dmzhang@suse.com>
#
# $Id: wizards.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module GeoClusterWizardsInclude
    def initialize_geo_cluster_wizards(include_target)
      Yast.import "UI"

      textdomain "geo-cluster"

      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "geo-cluster/complex.rb"
      Yast.include include_target, "geo-cluster/dialogs.rb"
    end

    # Main workflow of the geo-cluster configuration
    # @return sequence result
    def MainSequence
      # FIXME: adapt to your needs
      aliases = { "configure" => lambda { ConfigureDialog() }, "firewall" => lambda(
      ) do
        ServiceDialog()
      end }

      # FIXME: adapt to your needs
      sequence = {
        "ws_start"  => "configure",
        "configure" => { :abort => :abort, :next => "firewall" },
        "firewall"  => {
          :abort  => :abort,
          :next   => :next,
          :cancel => "configure",
          :back   => "configure"
        }
      }

      ret = Sequencer.Run(aliases, sequence)

      deep_copy(ret)
    end

    # Whole configuration of geo-cluster
    # @return sequence result
    def GeoClusterSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of geo-cluster but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def GeoClusterAutoSequence
      # Initialization dialog caption
      caption = _("GeoCluster Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
