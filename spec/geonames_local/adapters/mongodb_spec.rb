require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/geonames_local/adapters/mongodb')

describe Mongodb do

  SPECDB = "geonames_spec"

  before(:all) do
    Mongodb.new({:dbname => SPECDB}).purge
      @mong = Mongodb.new({:dbname => SPECDB})
  end

  def mock_spot(name)
    Spot.new("1\t#{name}\t#{name}\t\t-5.46874226086957\t-35.3565714695652\tA\tADM2\tBR\t22\t2407500\t6593\t\t12\t\t\t\tAmerica/Recife\t2006-12-17", :dump)
  end

  describe "Parsing Dump" do
    before do
      @mock_spot = mock("Spot")
    end

    it "should find all" do
     @mong.all("cities").each { |c| p c["geom"]} #should eql([])
    end

    it "should store something" do
      @mock_spot.should_receive(:to_hash).and_return({"id" => 7, "name" => "Sao Tome", "geom" => [5,5]})
      @mong.insert("cities", @mock_spot)
      @mong.count("cities").should eql(1)
    end

    it "should store a spot" do
      @mong.insert("cities", mock_spot("Loco"))
      @mong.find("cities", 1)["name"].should eql("Loco")
    end

    it "should store geom with sinusoidal projection" do
      @mock_spot.should_receive(:to_hash).and_return({"id" => 8, "name" => "Sao Tome", "geom" => [5,8]})
      @mong.insert("cities", @mock_spot)
      @mong.find("cities", 8)["geom"][0].should be_close(4.95, 0.1)
      @mong.find("cities", 8)["geom"][1].should eql(8)
    end

    it "should have some indexes" do
      @mong.index_info("cities").to_a.length.should eql(3)
    end

    describe "Finds" do

      before(:all) do
        @mong.insert("cities", {"id" => 9, "name" => "Sao Paulo", "geom" => [15,15]})
        @mong.insert("cities", {"id" => 10, "name" => "Sao Tome", "geom" => [-7,-34]})
        @mong.insert("cities", {"id" => 11, "name" => "Sao Benedito", "geom" => [-9,-39]})
      end

      it "should make sure it's on the collection" do
        @mong.count("cities").should eql(3)
      end

      it "should find geo" do
        @mong.find_near("cities", -5, -35).first["name"].should eql("Sao Tome")
        @mong.find_near("cities", -5, -35).first["geom"][0].should be_close(-5.80, 0.1)
        @mong.find_near("cities", -5, -35).first["geom"][1].should eql(-34)
      end

      it "should find geo limited" do
        @mong.find_near("cities", -5, -35, 1).length.should eql(1)
      end

      it "should find within box" do
        @mong.find_within("cities", [[10, 10],[20, 20]]).length.should eql(1)
        @mong.find_within("cities", [[10, 10],[20, 20]]).first["name"].should eql("Sao Paulo")
      end

      it "should find within radius" do
        @mong.find_within("cities", [[-6, -36], 2]).length.should eql(1)
      end

      it "should find within wider radius" do
        @mong.find_within("cities", [[-6, -36], 5]).length.should eql(2)
      end

      it "should find within wider radius limited" do
        @mong.find_within("cities", [[-6, -36], 5], 1).length.should eql(1)
      end

      it "should find geoNear" do
        @mong.near("cities", -5, -35).first["dis"].should be_close(1.97, 0.01)
        @mong.near("cities", -5, -35).first["obj"]["name"].should eql("Sao Tome")
      end

      it "should find geoNear" do
        @mong.near("cities", -5, -35).first["dis"].should be_close(1.97, 0.01)
        @mong.near("cities", -5, -35).first["obj"]["name"].should eql("Sao Tome")
      end

      it "should find geoNear limited" do
        @mong.near("cities", -5, -35, 1).length.should eql(1)
      end

    end

  end

end
