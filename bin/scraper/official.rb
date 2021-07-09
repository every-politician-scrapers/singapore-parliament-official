#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'

# TODO: fetch data from the individual member pages
class Legislature
  # details for an individual member
  class Member < Scraped::HTML
    field :id do
      url.split('/').last
    end

    field :name do
      # this seems brittle, but works with the current members
      full_name.split(' ').drop(1).join(' ')
    end

    field :url do
      noko.css('a/@href').text
    end

    field :constituency do
      noko.css('.constituency').text.tidy
    end

    def full_name
      noko.css('a').text.tidy
    end
  end

  # The page listing all the members
  class Members < Scraped::HTML
    decorator Scraped::Response::Decorator::CleanUrls

    field :members do
      noko.css('#currentlistofmps li').map { |mp| fragment(mp => Member).to_h }
    end
  end
end

url = 'https://www.parliament.gov.sg/mps/list-of-current-mps'
puts EveryPoliticianScraper::ScraperData.new(url).csv
