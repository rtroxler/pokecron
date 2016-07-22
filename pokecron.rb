#!/usr/bin/env ruby
#require 'pry'
require 'pony'
require_relative 'pokemon_hash'

@found_pokes = []

RELEVANT_POKES = [
  #"29", # DeBUG pokes (lol)
  #"41",
  #"13",
  #"48",
  "1",
  "2",
  "3",   # Venusaur
  "4",
  "5",
  "6",   # Charizard
  "7",
  "8",
  "9",   # Blastoise
  "25",  # Pikachu
  "26",  # Raichu
  "38",  # Ninetales
  "63",  # Abra
  "64",  # Kadabra
  "64",  # Alakazam
  "67",  # Machoke
  "68",  # Machamp
  "83",  # Farfetch'd
  "97",  # Hypno
  "100", # Voltorb
  "101", # Electrode
  "106", # Hitmonlee
  "107", # Hitmonchan
  "115", # Kangaskhan
  "122", # Mr Mime
  "125", # Electabuzz
  "128", # Tauros
  #"129", # Magikarp
  "130", # Gyrados
  "131", # Lapras
  "137", # Paragon
  "138", # Omanyte
  "139", # Omastar
  "140", # Kabuto
  "141", # Kabutops
  "142", # Aerodactyl
  "143", # Snorlax
  "147", # Dratini
  "148", # Dragonair
  "149", # Dragonite
  "150", # Mewtwo LOL
  "151"  # Mew LOL
]

PLAZA_COORDS = [
  "39.040765, -94.588615",
  "39.042273, -94.589269",
  "39.042560, -94.591597",
  "39.040436, -94.591978",
  "39.039911, -94.595661",
  "39.042411, -94.594728"
]

def hit_api location=nil
  puts "[#{Time.now}] Searching at #{location}..."

  Dir.chdir("/Users/ryantroxler/playground/pokemon-go/pokemongo-api-demo")
  output = `python main.py -u coathanger5000 -p testtest --location "#{location}"`

  parse_response output.split("\n")
end

def parse_response response
  if response[4].match(/offline/) || response.any? {|r| r.match(/main.py/) }
    puts "[#{Time.now}] servers are offline"
    exit
  end

  response.select {|line| line.include?("seconds") && line.include?("visible") }.each do |poke_line|
    poke_num, gps_coords, despawn = fetch_from_line poke_line
    alert_if_relevant(poke_num, gps_coords, despawn)
  end
end

def fetch_from_line poke_line
  result = poke_line.scan(/\((.*?)\)/)
  poke_num = result[0][0] # lol this sucks
  gps_coords = result[1][0] # lol this sucks
  despawn = poke_line.match(/for (.*?) seconds/)[1]

  return poke_num, gps_coords, despawn
end

def alert_if_relevant(num, gps, despawn)
  if pokemon = RELEVANT_POKES.include?(num)
    str = "[#{Time.now}] Found a #{POKEMON[num.to_i]} at #{gps}, despawning in #{despawn} seconds."
    puts str
    @found_pokes << {num: num, gps: gps, despawn: Time.now + despawn.to_i}
  end
end

def start
  PLAZA_COORDS.each do |location|
    hit_api(location)
  end
end

start

if @found_pokes.any?
  body = @found_pokes.uniq {|poke| poke[:num] && poke[:gps]}.collect do |poke_data|
    loc = poke_data[:gps].gsub(/\s+/, "").split(",").join("+")
    """
    <div>
      <h3>#{POKEMON[poke_data[:num].to_i]}</h3>
      Found at (#{poke_data[:gps]}) -- <a href='http://maps.google.com/maps?&z=10&mrt=yp&t=m&q=#{loc}'>See Map</a>
      Despawning at #{poke_data[:despawn]}.
    </div>
    """
  end.join("")
  Pony.mail(
    to: 'troxler.ryan@gmail.com',
    from: 'brian.tresler@gmail.com',
    subject: 'Found some pokemon!',
    html_body: body
  )
  puts "[#{Time.now}] Email sent."
end

