require 'spec_helper'

describe Noid::Minter do
  it "should mint a few random 3-digit numbers" do
    minter = Noid::Minter.new(:template => '.rddd')
    minter.mint.should =~ /\d\d\d/
  end

  it "should mint random 3-digit numbers, stopping after the 1000th" do
    minter = Noid::Minter.new(:template => '.rddd')
    1000.times { minter.mint.should =~ /^\d\d\d$/ }
    expect { minter.mint }.to raise_exception
  end

  it "should mint sequential numbers without limit, adding new digits as needed" do
    minter = Noid::Minter.new(:template => '.zd')
    minter.mint.should == "0"
    999.times { minter.mint.should =~ /\d/ }
    minter.mint.should == "1000"
  end

  it "should mint random 4-digit numbers with constant prefix bc" do
    minter = Noid::Minter.new(:template => 'bc.rdddd')
    1000.times { minter.mint.should =~ /^bc\d\d\d\d$/ }
  end

  it "should mint sequential 2-digit numbers with constant prefix 8rf" do
    minter = Noid::Minter.new(:template => '8rf.sdd')
    minter.mint.should == "8rf00"
    10.times { minter.mint.should =~ /^8rf\d\d$/ }
    minter.mint.should == "8rf11"
    88.times { minter.mint.should =~ /^8rf\d\d$/ }
    expect { minter.mint }.to raise_exception
  end

  it "should mint sequential extended-digits" do
    minter = Noid::Minter.new(:template => '.se')
    29.times.map { minter.mint }.join('').should == "0123456789bcdfghjkmnpqrstvwxz"
  end
  
  it "should mint random 3-extended-digit numbers with constant prefix h9" do
    minter = Noid::Minter.new(:template => 'h9.reee')

    (minter.template.max).times { minter.mint.should =~ /^h9\w\w\w$/ }
    expect { minter.mint }.to raise_exception
  end

  it "should mint unlimited sequential numbers with at least 3 extended digits" do
    minter = Noid::Minter.new(:template => '.zeee')
    (29*29*29).times { minter.mint.should =~ /^\w\w\w/ }
    minter.mint.should =~ /^\w\w\w\w/
  end

  it "should mint random 7-char numbers, with extended digits at chars 2,4,and 5" do
    minter = Noid::Minter.new(:template => '.rdedeedd')
    1000.times { minter.mint.should =~ /^\d\w\d\w\w\d\d$/ }
  end

  it "should mint unlimited mixed digits, adding new extended digits as needed" do
    minter = Noid::Minter.new(:template => '.zedededed')
    minter.mint.should == "00000000"
  end

  it "should mint sequential 4-mixed-digit with constant prefix sdd" do
    minter = Noid::Minter.new(:template => 'sdd.sdede')
    minter.mint.should == 'sdd0000'
    1000.times { minter.mint.should =~ /^sdd\d\w\d\w$/}
    minter.mint.should == "sdd034h"
  end

  it "should mint random 3 mixed digits plus final (4th) computed check character" do
    minter = Noid::Minter.new(:template => '.rdedk')
    1000.times { minter.mint.should =~ /^\d\w\d\w$/ }
  end

  it "should mint 5 sequential mixed digits plus final extended digit check char" do
    minter = Noid::Minter.new(:template => '.sdeeedk')
    minter.mint.should == "000000"
    minter.mint.should == "000015"
    minter.mint.should == "00002b"
    1000.times { minter.mint.should =~ /^\d\w\w\w\d\w$/ }
    minter.mint.should == "003f3m"
  end

  it "should mint sequential digits plus check char, with new digits added as needed" do
    minter = Noid::Minter.new(:template => ".zdeek")
    minter.mint.should == "0000"
    minter.mint.should == "0013"
    (10*29*29-2).times { minter.mint.should =~ /^\d\w\w\w$/ }
    minter.mint.should == "10001"
  end

  it "should mint prefix plus random 3 mixed digits plus a check char" do
    minter = Noid::Minter.new(:template => "63q.redek")
    minter.mint.should =~ /63q\w\d\w\w/
  end

  describe "validate" do
    it "should validate a prefixed identifier" do
      minter = Noid::Minter.new(:template => "foobar.redek")
      id = minter.mint
      minter.valid?(id).should be_true
    end
    it "should validate a prefixless identifier" do
      minter = Noid::Minter.new(:template => ".redek")
      id = minter.mint
      minter.valid?(id).should be_true
    end
    it "should validate with a new minter" do
      minter = Noid::Minter.new(:template => ".redek")
      id = minter.mint
      minter2 = Noid::Minter.new(:template => ".redek")
      minter2.valid?(id).should be_true
    end
  end

  describe "seed" do
    it "given a specific seed, identifiers should be replicable" do
      minter = Noid::Minter.new(:template => "63q.redek")
      minter.seed(1)
      minter.mint.should == "63q3706"
      
      minter = Noid::Minter.new(:template => "63q.redek")
      minter.seed(1)
      minter.mint.should == "63q3706"
    end

    it "given a specific seed and sequence, identifiers should be replicable" do
      minter = Noid::Minter.new(:template => "63q.redek")
      minter.seed(23456789, 567)
      minter.mint.should == "63qh305"

      minter = Noid::Minter.new(:template => "63q.redek")
      minter.seed(23456789, 567)
      minter.mint.should == "63qh305"
    end
  end

  describe "dump and reload" do
    it "should dump the minter state" do
      minter = Noid::Minter.new(:template => ".sddd")
      d = minter.dump
      d[:template].should == ".sddd"
      d[:seq].should == 0

      minter.mint
      minter.mint
      d = minter.dump
      d[:seq] == 2
    end

    it "should dump the seed, sequence, and counters for the RNG" do
      minter = Noid::Minter.new(:template => ".rddd")
      d = minter.dump
      d[:seq] == 0
      d[:seed].should == minter.instance_variable_get('@seed')
    end

    it "should allow a random identifier minter to be 'replayed' accurately" do
      minter = Noid::Minter.new(:template => '.rd')
      d = minter.dump
      arr = 10.times.map { minter.mint }

      minter = Noid::Minter.new(d)

      arr2 = 10.times.map { minter.mint }

      arr.should == arr2

    end

  end

  describe "multithreading-safe example" do
    before do
      require 'yaml'
      minter = Noid::Minter.new(:template => '.rd')
      yaml = YAML::dump(minter.dump)
      File.open('minter-state', 'w') { |f| f.write yaml }
    end

    after do
      File.delete('minter-state')
    end

    it "should persist state to the filesystem" do

      File.open("minter-state", File::RDWR|File::CREAT, 0644) {|f|
        f.flock(File::LOCK_EX)
        yaml = YAML::load(f.read)
        
        minter = Noid::Minter.new(yaml)

        f.rewind
        yaml = YAML::dump(minter.dump)
        f.write yaml
        f.flush
        f.truncate(f.pos)
      }

    end
  end


end
