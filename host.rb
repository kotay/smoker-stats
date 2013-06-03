require_relative "./network_latency"
class Host
  attr_reader :addr

  def initialize addr
    @addr    = addr
  end

  def monitor(interval = 1)
    Thread.abort_on_exception = true
    loop do
      res = NetworkLatency.new(:host => addr).()
      result = res[:avg]
      event = {
        :host       => addr,
        :title      => addr,
        :avg_delta  => res[:avg].round(2),
      }
      yield event
      sleep interval
    end
  end
end