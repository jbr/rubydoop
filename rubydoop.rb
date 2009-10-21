def map(&proc)
  @map = proc
end

def reduce(&proc)
  @reduce = proc
end

def emit(key, value)
  puts [key, value].join("\t")
end

at_exit do
  case ARGV.first
  when 'start'
    cmd = <<-EOC
      hadoop fs -rmr output
      hadoop jar /usr/local/hadoop/contrib/streaming/hadoop-*-streaming.jar\\
        -inputformat org.apache.hadoop.mapred.KeyValueTextInputFormat\\
        -output output -input input\\
        -file #{File.expand_path __FILE__} \\
        -file #{File.expand_path $0} \\
        -mapper "#{File.basename $0} map" \\
        -reducer "#{File.basename $0} reduce"
    EOC
    puts cmd
    exec cmd
  when 'map'
    while line = STDIN.gets
      if line =~ /^([^\t]+)\t(.+)$/
        @map.call $1, $2
      end
    end
  when 'reduce'
    key, values = nil, []
    while line = STDIN.gets
      if line =~ /^([^\t]+)\t(.+)$/
        thiskey, thisvalue = $1, $2
        if key != thiskey && key
          @reduce.call key, values
          key, values = nil, []
        end
        key = thiskey
        values << thisvalue
      end
    end
  when 'simulate'
    raise unless File.exists?(ARGV.last)
    exec "cat #{ARGV.last} | #{$0} map | sort | #{$0} reduce"
  else
    STDERR.puts <<-EOM
Please run "#{$0} COMMAND", where COMMAND is one of the following:
\tstart
\tmap
\treduce
EOM
    exit -1
  end
end
