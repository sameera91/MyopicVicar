class SearchStatisticsController < InheritedResources::Base
  skip_before_filter :require_login
  
  LAUNCH = [2015, 4, 14, 14]
  
  def index
     calculate_last_8_days(8)   
     if params[:hours]
#       over-write with recent stuff
       calculate_last_48_hours(params[:hours])   
       
     end
       
#     calculate_last_48_hours   
  end
  
  def calculate_last_8_days(days)
    days = [days_from_launch, days.to_i].min
    points = days + 1
    @chart_unit = "#{days} days"
    @label = [''] * points #initialize blank labels
    fields = [:n_searches, :n_time_gt_1s, :n_time_gt_10s, :n_time_gt_60s]
    @data = {}
    fields.each { |field| @data[field] = [0]*points }  #initialize data array
    (points-1).downto(0) do |i_ago| 
      date = Time.now - i_ago.day
      i = points - i_ago - 1 #TODO make not horrible
      @label[i] = date.day.to_s
      day_stats = SearchStatistic.where(:year => date.year, :month => date.month, :day => date.day)
 
      day_stats.each do |stat|
        fields.each do |field|
          @data[field][i] += stat.send(field)
        end
      end
    end
  end

  def calculate_last_48_hours(hours)
    hours = [hours_from_launch, hours.to_i].min
    points = hours + 1
    @chart_unit = "#{hours} hours"
    @label = [''] * points #initialize blank labels
    fields = [:n_searches, :n_time_gt_1s, :n_time_gt_10s, :n_time_gt_60s]
    @data = {}
    fields.each { |field| @data[field] = [0]*points }  #initialize data array
    (points-1).downto(0) do |i_ago|
      date = Time.now - i_ago.hour
      i = points - i_ago - 1
      @label[i] = date.hour.to_s
      day_stats = SearchStatistic.where(:year => date.year, :month => date.month, :day => date.day, :hour => date.hour)
      
      day_stats.each do |stat|
        fields.each do |field|
          @data[field][i] += stat.send(field)
        end
      end
    end
  end

  def days_from_launch
    (hours_from_launch / 24).to_i
  end

  def hours_from_launch
    seconds_from_launch = Time.now - Time.new(LAUNCH[0], LAUNCH[1], LAUNCH[2], LAUNCH[3])
    (seconds_from_launch / 3600).to_i
  end

end


