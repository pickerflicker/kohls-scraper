require 'Nokogiri'
require 'Pry'
require "watir"

class Scraper
  attr_accessor :discounted_products
  def initialize(url)
    @root_url = url
    @discounted_products = []
  end

  def execute
    browser = Watir::Browser.new :chrome
    browser.goto(@root_url)
    page = browser.html

    file = File.open('temp.html', 'w')

    loop do
      parsed_page = Nokogiri::HTML(page)

      products = {}
      parsed_page.css('.products_grid:not(.hl-beacon-impression)').each do |product_block|
        name = product_block.css('.prod_img_block img').first['title']
        link = product_block.css('.prod_img_block a').first['href']
        products[name]=link
      end

      last_url = browser.url

      products.each do |name, link|
        puts "Checking #{name}"
        browser.goto("http://www.kohls.com" + link)
        if browser.text.include? 'This product is not eligible for promotional offers and coupons'
          price = browser.div(class: 'main-price').text
          file.puts [name, price, link].inspect + ','
        end
      end

      browser.goto last_url
      browser.link(title: 'Next Page').click
      break if browser.link(title: 'Next Page').attribute_value('class').include? 'deactivate' # last page
    end

     file.close
  end

end

scraper = Scraper.new("http://www.kohls.com/catalog/baby-gear-travel-baby-gear.jsp?CN=4294712019+4294719566&Icid=bg|b0&PPP=120&srp=e1")
start_time = Time.now

scraper.execute

puts "Completed in #{(Time.now - start_time)/60} minutes"