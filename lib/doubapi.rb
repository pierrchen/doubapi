require 'rubygems'  #a hack to require failure for nokogiri
require 'open-uri'
require 'nokogiri'
require 'pp'


module Doubapi
#return a Nokogiri XML  object
#use Douban API
def self.douban_get_xml url
	puts url
    doc = open(url,'User-Agent' => 'ruby')
    Nokogiri::HTML(doc,nil, "utf-8")
    #Nokogiri::HTML(open(url,:proxy => nil,'User-Agent' => 'ruby'),nil, "utf-8")
	#no network access, used to simulator 
	#doc = File.read(File.join(RAILS_ROOT, "app","controllers","event_sample.xml"))
	#Nokogiri::HTML(doc,nil, "utf-8")
    #Nokogiri::HTML(open(url,:proxy => nil,'User-Agent' => 'ruby'),nil, "utf-8")
end



#return Atom
#Douban search : will return results that does not match 
def self.search_event key_chinese, location = "shanghai"
  keywords= "%" + key_chinese.each_byte.map {|c| c.to_s(16)}.join("%")
  uri="http://api.douban.com/events?q=#{keywords}&location=#{location}&start-index=1&max-results=5"
  #Let's grab it slowly to avoid being baned...	
  sleep(7) 	
  douban_get_xml(uri)
end

def self.search_ablum artist_chinese ,max=10
  keywords= "%" + artist_chinese.each_byte.map {|c| c.to_s(16)}.join("%")
  uri="http://api.douban.com/music/subjects?tag=#{keywords}&start-index=1&max-results=#{max}"
  #Let's grab it slowly to avoid being baned...	
  sleep(7) 	
  douban_get_xml(uri)
end

Douban_Event =  Struct.new :title, :when, :where, :what, :link

#
#release_date is in the format of YY-MM-DD
Douban_Album =  Struct.new :author, :title, :release_date,  :link


#TODO
def self.looks_like_a_live_show? e, artist

	#check e.when should happen
	#2010-08-13F21:30:00+08:00
	_,_,_,hour = e.when.scan(/\d{1,4}/);

	return true if hour.to_i > 18 and e.what.include?(artist)
	return false
end

#return true if a >= b
#a,b could be one of the following format
#2010.01
#2010.1
#2010#1
#2010-1
#2010年1
def self.compare_date a , b
	ya, ma = a.scan(/\d{1,4}/)
	yb, mb = b.scan(/\d{1,4}/)
	return true if (ya.to_i * 12 + ma.to_i ) >= (yb.to_i*12+mb.to_i)
end

def self.search_albums_of artist , after_date = "1900.01"
	doc = search_ablum artist
	albums=[]

	doc.xpath("//entry").each do |entry|
		title = entry.at_xpath(".//title").text
		author = unless entry.at_xpath(".//name").nil?
				 entry.at_xpath(".//name").text
			     else
				 "unknown(#{artist}?)"
				 end
		release_date = unless entry.at_xpath(".//attribute[@name='pubdate']").nil?
							entry.at_xpath(".//attribute[@name='pubdate']").text
					   else
							#means unknow
							"0000-00"
					   end
    	link =  entry.at_xpath(".//link[@rel='alternate']")["href"]
    
		#make release data YY-MM-DD style
		r = release_date.scan(/\d{1,4}/)
		#if DD was not specified
		r << "01"         if r.size == 2
		r << "01" << "01" if r.size == 1
	
		y , m , d = r

		m = "01" unless (1..12).include?(m.to_i) 
		d = "01" unless (1..30).include?(d.to_i) 

		formated_release_day = "#{y}-#{m}-#{d}" 
		#check the release date
		if compare_date release_date, after_date			
			albums << Douban_Album.new(author, title, formated_release_day, link)
		end
	end
	albums
end

def self.search_events_of artist
  doc = search_event artist
  events=[]
  doc.xpath("//entry").each do |entry|
    #pp entry
    title = entry.at_xpath(".//title").text
    #attribute is starttime NOT startTime as specified in the xml
    start_time = entry.at_xpath('.//when')["starttime"]
    #  city = entry.at_xpath('.//location').text
    where = entry.at_xpath('.//where')["valuestring"]
    link =  entry.at_xpath(".//link[@rel='alternate']")["href"]
    what = entry.at_xpath(".//content").text
    events << Douban_Event.new(title, start_time, where, what, link)
  end
	
  #filtering of the results
  events.select{|e| looks_like_a_live_show?(e,artist)}
end



if __FILE__== $0
#should use Artist Model
#File.read("./app/controllers/artists.txt").split("\n").each {|artist| Artist.new(:name=>artist,:intro=>"no").save}
#Artist.all.each {|a| puts a.name}
File.read("artists.txt").split("\n").each do |artist|
	puts artist
	e = search_events_of artist
  	e.each do |event|
    	puts event.title
  		puts event.when
  		puts event.where
        puts event.what
  end
end
end

end #Module  
