# encoding: utf-8

class LogStash::Outputs::Msai
  class Timer
    public

    attr_accessor :state
    attr_reader :expiration
    attr_reader :object
    attr_reader :callback

    def self.config ( configuration )
      @@configuration = configuration
      @@logger = configuration[:logger]
      @@timers = []
      @@timers_modified = false
      @@timers_mutex = Mutex.new

      Thread.new do
        loop do
          sleep( 1 )

          curr_time = Time.now.utc
          timers_triggerd = [  ]

          @@timers_mutex.synchronize {
            @@timers.each do |timer|
              if :on == timer.state && curr_time >= timer.expiration
                timer.state = :trigger
                timers_triggerd << [ timer.object, timer.callback ]
              end
            end
          }

          timers_triggerd.each do |pair|
            (object, callback) = pair
            callback.call( object )
          end
        end
      end

    end

    def initialize
      @@timers_mutex.synchronize {
        @@timers << self
      }
      @state = :off
    end

    def set ( expiration, object, &callback )
      @@timers_mutex.synchronize {
        @@timers_modified= true
        @state = :on
        @object = object
        @expiration = expiration
        @callback = callback
      }
    end

    def cancel
      @@timers_mutex.synchronize {
        state = @state
        @state = :off
        @@timers_modified = true if :on == state
        state != :trigger
      }
    end

  end
end
