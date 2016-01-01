# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

module Dizby
  def self.any_to_s(obj)
    "#{obj}:#{obj.class}"
  rescue
    format '#<%s:0x%1x>', obj.class, obj.__id__
  end
end
