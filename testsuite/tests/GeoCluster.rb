# encoding: utf-8

module Yast
  class GeoClusterClient < Client
    def main
      # testedfiles: GeoCluster.ycp

      Yast.include self, "testsuite.rb"
      TESTSUITE_INIT([], nil)

      Yast.import "Iplb"

      DUMP("GeoCluster::Modified")
      TEST(lambda { GeoCluster.Modified() }, [], nil)

      nil
    end
  end
end

Yast::GeoClusterClient.new.main
