require 'uri'
require 'open3'
require 'fileutils'
require 'shellwords'
require 'tmpdir'

class SlimYourWebsite
  DOWNLOAD_REPEATS = 10
  DOWNLOAD_TIME_PREFIX = "Total wall clock time: "
  PAGE_SIZE_PREFIX = "Downloaded: "

  def assess(filename, no_of_times = DOWNLOAD_REPEATS)
    lines = IO.readlines(filename).map(&:strip)
    self.current_request = 0
    self.total_requests = lines.length * no_of_times
    result = ""
    lines.each do |url|
      if is_valid_url?(url)
        output = get_site_repeatedly(url, no_of_times || DOWNLOAD_REPEATS)
        result += massage_output(url, output)
      end
    end if File.exists?(ARGV[0])
    result
  end

  private

  attr_accessor :total_requests, :current_request

  def is_valid_url?(url)
    url =~ URI::regexp
  end

  def update_progress
    self.current_request += 1
    percent = ((current_request / total_requests.to_f) * 100).to_i
    print "\r"
    print "#{current_request}/#{total_requests} requests completed - #{percent}% complete"
  end

  def get_site_repeatedly(url, no_of_times)
    output = []
    no_of_times.times do
      Dir.mktmpdir do |output_dir|
        command = "wget -H -p -nv #{url.shellescape}"
        _, stderr, status = Open3.capture3(command, chdir: output_dir)
        output << stderr
      end

      update_progress
    end

    output
  end

  def massage_output(url, output)
    massaged_output = [url.upcase + " " + "=" * (40 - url.length)]
    massaged_output << collect_realtime_information(output)
    massaged_output << collect_size_and_cpu_information(output)
    massaged_output.join("\n") + "\n"
  end

  def collect_realtime_information(output)
    times = []
    output.each do |output_entry|
      lines = output_entry.split("\n")
      line = lines.find{|line| line.start_with?(DOWNLOAD_TIME_PREFIX)}
      if line
        match_data = /#{DOWNLOAD_TIME_PREFIX}(.*)s/.match(line)
        times << match_data[1].gsub(",", "").to_f
      end
    end
    return "Realtime download times (s): #{times}\n" +
      "Average realtime download time (s): #{average(times)}"
  end

  def collect_size_and_cpu_information(output)
    files_downloaded = nil
    download_size = nil
    times = []
    connection_speeds = []
    output.each do |output_entry|
      lines = output_entry.split("\n")
      line = lines.find{|line| line.start_with?(PAGE_SIZE_PREFIX)}
      if line
        match_data = /#{PAGE_SIZE_PREFIX}([0-9]+) files, (.*)([KM]+) in (.*)s \((.*) ([KM]+)B\/s\)/.match(line)
        files_downloaded = match_data[1].gsub(",", "").to_i
        download_size = match_data[2].gsub(",", "").to_f
        download_size *= 1000 if match_data[3] == "M"
        times << match_data[4].gsub(",", "").to_f
        connection_speed = match_data[5].gsub(",", "").to_f
        connection_speed *= 1000 if match_data[6] == "M"
        connection_speeds << connection_speed
      end
    end

    <<-INFO
Files downloaded: #{files_downloaded}
Download size (KB): #{download_size.to_i}
CPU work times (s): #{times}
Average CPU work time (s): #{average(times)}
Connection speeds (KB/s): #{connection_speeds}
Average connection speed (KB/s): #{average(connection_speeds).to_i}
    INFO
  end

  def average(array_of_numbers)
    sum = array_of_numbers.inject(0, :+)
    length = array_of_numbers.length == 0 ? 1 : array_of_numbers.length
    return (sum / length).round(1)
  end
end

slim_your_website = SlimYourWebsite.new
times = (ARGV[1] || "10").to_i
filename = ARGV[0]
result = slim_your_website.assess(filename, times)
print "\r"
puts result
