require_relative 'common'

#
# import the test data
#

system "cd #{File.dirname(__FILE__)}/../../../ && rake logstash:pv_to_redis[#{ARGV[0]},#{ARGV[1]}]"

raise "Failed to import '#{ARGV[1]}' as #{ARGV[0]}" if 0 < $?.exitstatus


# logstash workers have a slight delay with queueing/flushing
# @todo make this static sleep more intelligent...
sleep 30

#
# make sure everything parsed okay
#

res = eslog_search(
  "_search",
  {
    "query" => {
      "filtered" => {
        "query" => {
          "query_string" => {
            "query" => "@tags:\"_grokparsefailure\""
          }
        }
      }
    },
    "size" => 10,
    "sort" => [
      {
        "@timestamp" => {
          "order" => "desc"
        }
      }
    ]
  }
)

if (0 < res['hits']['total'])
    raise "Some log events were not parsed correctly (#{res['hits']['total']} events) " +
          "- the most recent 10 are shown: #{JSON.pretty_generate(res)}"
end
