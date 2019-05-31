# Sources for geo-cluster

module_DATA = \
  modules/GeoCluster.rb \
  modules/GeoCluster3.py \
  modules/GeoCluster2.pm

client_DATA = \
  clients/geo-cluster.rb \
  clients/geo-cluster_auto.rb \
  clients/geo-cluster_proposal.rb

yncludedir = @yncludedir@/geo-cluster
ynclude_DATA = \
  include/geo-cluster/dialogs.rb \
  include/geo-cluster/complex.rb \
  include/geo-cluster/helps.rb \
  include/geo-cluster/wizards.rb

desktop_DATA = \
  desktop/org.openSUSE.YaST.GeoCluster.desktop

scrconf_DATA = \
  scrconf/booth.scr

agent_SCRIPTS = \
  servers_non_y2/ag_booth

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/geo-cluster.rnc

symbolicdir = @icondir@/hicolor/symbolic/apps
symbolic_DATA = \
  icons/hicolor/symbolic/apps/yast-geo-cluster-symbolic.svg
scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-geo-cluster.svg

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(desktop_DATA) $(scrconf_DATA) $(agent_SCRIPTS) $(schemafiles_DATA) $(symbolic_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common
