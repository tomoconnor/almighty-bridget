#Bridget.rb
#Connects Pagerduty alerts to Campfire
require "tinder"
require "redphone/pagerduty"
require "YAML"

def humanize secs
  [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
    if secs > 0
      secs, n = secs.divmod(count)
      "#{n.to_i} #{name}"
    end
  }.compact.reverse.join(' ')
end


systemSettings = YAML.load(File.read("#{File.dirname(__FILE__)}/config.yml"))
campfire = Tinder::Campfire.new(systemSettings["campfire_subdomain"], :token => systemSettings["campfire_key"])
room = campfire.find_room_by_id(systemSettings["campfire_room"])

postMessage = ""
pagerduty = Redphone::Pagerduty.new(
	:service_key => systemSettings["pagerduty_key"],
	:subdomain => systemSettings["pagerduty_subdomain"],
	:user => systemSettings["pagerduty_user"],
	:password => systemSettings["pagerduty_password"]
	)

current_incidents = pagerduty.incidents(:status=>"triggered")["incidents"]

if current_incidents.count > 0
	postMessage = "There are #{current_incidents.count} incidents currently."

	current_incidents.each_with_index{|incident,index|
		created_on = DateTime.strptime(incident["created_on"],"%Y-%m-%dT%H:%M:%SZ")
		last_change_on = DateTime.strptime(incident["last_status_change_on"],"%Y-%m-%dT%H:%M:%SZ")
		
		event_occured = ((DateTime.now() - created_on )*24*60*60).to_i
		change_occured = ((DateTime.now() - last_change_on )*24*60*60).to_i

		human_ago = humanize(event_occured)
		human_resolved_ago = humanize(change_occured)

		description = incident["trigger_summary_data"]["description"]
		url = incident["html_url"]
		status = incident["status"]
		if status == "triggered"
			detailMessage = "#{index}: #{description} Triggered #{human_ago} ago => #{url}"
		#elsif status == "resolved"
		#	detailMessage = "#{index}: #{description} Resolved #{human_resolved_ago} ago => #{url}"
		end
		room.speak(postMessage)
		room.speak(detailMessage)
	}

elsif current_incidents.count == 0
	room.speak("There are currently no unresolved incidents")
end	



