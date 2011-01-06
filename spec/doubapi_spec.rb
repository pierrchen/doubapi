require 'lib/doubapi'
describe Doubapi do 

	it "should be able to search 许巍 " do 
		key = "许巍"
		Doubapi.search_events_of(key).each do |event|
				event.what.should be_include(key)
				puts event.title
				puts event.when
				puts event.where
				puts event.link
		end	
	end

	it "should be able to search albums of 李志 " do 
		author = "李志"
		Doubapi.search_album_of(author).each do |album|
			puts album.author	
			puts album.title	
			puts album.release_date	
			puts album.link	
		end
	end

	it "should be able to search albums of 李志 that released after 2010 " do 
		author = "李志"
		Doubapi.search_album_of(author, "2010.05").each do |album|
			puts album.author	
			puts album.title	
			puts album.release_date	
			puts album.link	
		end
	end



end
