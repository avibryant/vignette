module Vignette
  class DB
    def initialize
      @store = {}
    end

    def query(key, vector = {})
#      puts "Query: #{key}: #{vector.inspect}"
      case key
      when /[*]/
        aggregate_query(key, vector)
      when /%/
        search_query(key, vector)
      else
        simple_query(key, vector)
      end
    end

    def simple_query(key, vector)
      result = {}
      if(current = @store[key])
        if(vector.empty?)
          result = current
        else
          vector.each do |i,n|
            if((v = current[i]) && n < v)
              result[i] = v
            end
          end
        end
      end

      if(result.empty?)
        {}
      else
        {key => result}
      end
    end

    def search_query(key, vector)
      regex = /#{key.gsub(".", "[.]").gsub("%", ".*")}/
      results = {}
      @store.keys.each do |k|
        if k =~ regex
          results.merge!(query(k, vector))
        end
      end
      results
    end

    def update(key, vector)
      return {} if key =~ /%/ || vector.empty?
      if(current = @store[key])
        updates = {}
        vector.each do |i,n|
          if(n > (current[i] || 0))
            current[i] = n
            updates[i] = n
          end
        end
        updates
      else
        @store[key] = vector
        vector
      end
    end
  end
end