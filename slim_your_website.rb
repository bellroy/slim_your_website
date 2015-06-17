require 'uri'
require 'fileutils'

class SlimYourWebsite
  DOWNLOAD_REPEATS = 10
  DOWNLOAD_TIME_PREFIX = "Total wall clock time: "
  PAGE_SIZE_PREFIX = "Downloaded: "
  OUTPUT_FILENAME = "output.txt"

  def assess(filename, no_of_times = DOWNLOAD_REPEATS)
    lines = IO.readlines(filename).map(&:strip)
    self.current_request = 0
    self.total_requests = lines.length * no_of_times
    result = ""
    lines.each do |url|
      if is_valid_url?(url)
        output = get_site_repeatedly(url, no_of_times || DOWNLOAD_REPEATS)
        result += massage_output(url, output)
        cleanup_output_file
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
    FileUtils.mkdir("output") rescue Errno::EEXIST
    no_of_times.times do
      command = "cd output; wget -E -H -k -p -nv --output-file=../#{OUTPUT_FILENAME} #{url}; cd ../; cat #{OUTPUT_FILENAME}"
      output << `#{command}`
      update_progress
    end
    FileUtils.remove_dir("output")
    output
  end

  def cleanup_output_file
    File.delete(OUTPUT_FILENAME)
  end

  def massage_output(url, output)
    massaged_output = [url.upcase + " " * 40]
    massaged_output << collect_realtime_information(output)
    massaged_output << collect_size_and_cpu_information(output)
    massaged_output << " "
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
        match_data = /#{PAGE_SIZE_PREFIX}([0-9]+) files, (.*)K in (.*)s \((.*) KB\/s\)/.match(line)
        files_downloaded = match_data[1].gsub(",", "").to_i
        download_size = match_data[2].gsub(",", "").to_i
        times << match_data[3].gsub(",", "").to_f
        connection_speeds << match_data[4].gsub(",", "").to_i
      end
    end
    return "Files downloaded: #{files_downloaded}\n" +
      "Download size (KB): #{download_size}\n" +
      "CPU work times (s): #{times}\n" +
      "Average CPU work time (s): #{average(times)}\n" +
      "Connection speeds (KB/s): #{connection_speeds}\n" +
      "Average connection speed (KB/s): #{average(connection_speeds).to_i}"
  end

  def average(array_of_numbers)
    sum = array_of_numbers.inject(&:+)
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
