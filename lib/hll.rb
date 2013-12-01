require 'digest/md5'

module Vignette
  module HyperLogLog
    BUCKETS = 1024
    A = 0.721
    TWO_32 = 2.0**32

    def self.vector(str)
      h = Digest::MD5.digest(str.to_s).unpack("L")[0]
      bucket = h & (BUCKETS-1)
      counter = 32 - (Math.log(h) / Math.log(2)).floor
      {bucket => counter}
    end

    def self.estimate(vector)
      sum = vector.map{|k,v| 2.0 ** -v}.inject(0.0){|a,b| a+b}
      zeros = BUCKETS - vector.size
      est = A*BUCKETS*BUCKETS / (sum + zeros)
      if est <= 2500 && zeros > 0
        est = BUCKETS * Math.log(BUCKETS.to_f/zeros)
      elsif est > (TWO_32 / 30.0)
        est = -TWO_32 * Math.log(1 - est/TWO_32)
      end

      est.round
    end
  end
end
