#!/usr/bin/env ruby

require 'rubygems'
require 'json'

def parse_moov(offset)

  @f.seek(offset)
  moov_size = @f.read(4).unpack("N").first
  moov_type = @f.read(4)

  moov_size = offset + moov_size

  offset += 8
  while offset < moov_size do
    size = @f.read(4).unpack("N").first
    type = @f.read(4)

    if type == "mvhd"
      parse_mvhd(offset)
    elsif type == "trak"
      parse_trak(offset)
    elsif type == "udta"
      #parse_udta(offset)
    end
    
    offset += size
    @f.seek(offset)
  end
end

def parse_trak(offset)

  @f.seek(offset)
  trak_size = @f.read(4).unpack("N").first
  trak_type = @f.read(4)

  trak_offset = offset + trak_size

  offset += 8
  while offset < trak_offset do
    size = @f.read(4).unpack("N").first
    type = @f.read(4)

    if type == "tkhd"
      parse_tkhd(offset)
    end
    
    offset += size
    @f.seek(offset)
  end
end

def parse_tkhd(offset)
  offset += 8
  @f.seek(offset)

  version = @f.read(1).unpack("C").first # C - 8-bit
  flags = @f.read(3)

  if version.to_i == 0
    ctime = @f.read(4).unpack("N").first
    mtime = @f.read(4).unpack("N").first
    track_id = @f.read(4).unpack("N").first
    reserved = @f.read(4)
    duration = @f.read(4).unpack("N").first
  elsif version.to_i == 1
    ctime = @f.read(8).unpack("Q").first
    mtime = @f.read(8).unpack("Q").first
    track_id = @f.read(4).unpack("N").first
    reserved = @f.read(4)
    duration = @f.read(8).unpack("Q").first
  end 

  reserved = @f.read(8)
  layer = @f.read(2).unpack("n").first
  alternate_group = @f.read(2).unpack("n").first

  volume = @f.read(2).unpack("n").first

  reserved = @f.read(2)

  matrix = @f.read(36) 
  width = @f.read(4).unpack("N").first
  height = @f.read(4).unpack("N").first
  

  tkhd = Hash.new
  tkhd[:ctime] = ctime
  tkhd[:mtime] = mtime
  tkhd[:track_id] = track_id
  tkhd[:duration] = duration
  tkhd[:layer] = layer
  tkhd[:alternate_group] = alternate_group
  tkhd[:volume] = volume
  tkhd[:width] = width
  tkhd[:height] = height

  @i[:ftyp][:moov][:trak] << tkhd 
end

def parse_mvhd(offset)

  offset += 8
  @f.seek(offset)

  version = @f.read(1).unpack("C").first # C - 8-bit
  flags = @f.read(3)

  if version.to_i == 0
    ctime = @f.read(4).unpack("N").first
    mtime = @f.read(4).unpack("N").first
    scale = @f.read(4).unpack("N").first
    duration = @f.read(4).unpack("N").first
  elsif version.to_i == 1
    ctime = @f.read(8).unpack("Q").first
    mtime = @f.read(8).unpack("Q").first
    scale = @f.read(4).unpack("N").first
    duration = @f.read(8).unpack("Q").first
  end 

  mvhd = Hash.new
  mvhd[:ctime] = ctime
  mvhd[:mtime] = mtime
  mvhd[:scale] = scale
  mvhd[:duration] = duration

  @i[:ftyp][:moov][:mvhd] = mvhd
end


# main

filename = ARGV[0]
@f = File.new(filename) # file
@i = Hash.new # info

offset = 0
atom_size = 0

while offset < @f.size

  atom_size = @f.read(4).unpack("N").first
  atom_type = @f.read(4)

  @i[:ftyp] = {}
  @i[:ftyp][:moov] = Hash.new
  @i[:ftyp][:moov][:trak] = Array.new

  if atom_type == "ftyp"
    major_brand = @f.read(4).unpack("N").first
    minor_version = @f.read(4).unpack("N").first
    compatible_brands = @f.read(4)

    @i[:ftyp][:major_brand] = major_brand
    @i[:ftyp][:minor_version] = minor_version
    @i[:ftyp][:compatible_brands] = compatible_brands

  elsif atom_type == "moov"
    parse_moov(offset)
  end

  offset += atom_size
  @f.seek(offset)
end

puts JSON.generate(@i)
