require "tilt/erubis"
require "sinatra"
require "sinatra/reloader"

before do
  @contents = File.readlines("data/toc.txt")
end

# Calls the block for each chapter, passing that chapter's number, name, and
# contents.
def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

# define a method to yield each paragraph to a block
# given a chapter, split it by paragraphs
# iterate through the paragraphs
# yield the paragraph's id number (should be its index in the array) and the text itself
# add the paragraph content and id number if the paragraph includes the query

def each_paragraph(contents)
  contents.split("\n\n").each_with_index do |paragraph, id|
    yield id, paragraph
  end
end

# This method returns an Array of Hashes representing chapters that match the
# specified query. Each Hash contain values for its :name and :number keys.
def chapters_matching(query)
  results = []

  return results if !query || query.empty?

  each_chapter do |number, name, contents|
    if contents.include?(query)
      chapter_hsh = { name: name, meta: [] }
      results << chapter_hsh 
    end

    each_paragraph(contents) do |id, paragraph|
      if paragraph.include?(query)
        chapter_hsh[:meta] << {number: number, id: id, paragraph: paragraph}
      end
    end
  end

  results
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/chapters/:number" do
  @ch_number = params[:number]
  @title = "Chapter #{@ch_number}: #{ch_title(@ch_number.to_i)}"
  @chapter = File.read("data/chp#{@ch_number}.txt")

  erb :chapter
end

get "/search" do
  erb :search
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").map.with_index do |paragraph, i|
      "<p id='#{i}'>#{paragraph}</p>"
    end.join
  end

  def ch_title(num)
    @contents[num - 1]
  end

  def highlight(text, keychars)
    text.gsub(keychars, "<strong>#{keychars}</strong>")
  end
end

not_found do
  redirect "/"
end