#!/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'csv'
require 'scraped'

class Results < Scraped::JSON
  field :members do
    json[:results][:bindings].map { |result| fragment(result => Member).to_h }
  end
end

class Member < Scraped::JSON
  field :name do
    json.dig(:name, :value)
  end
end

WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql?format=json&query=%s'

memberships_query = <<SPARQL
  SELECT ?item ?name
  WHERE {
    ?item p:P39 ?ps .
    ?ps ps:P39 wd:Q21294917 ; pq:P2937 wd:Q104845061 .
    FILTER NOT EXISTS { ?ps pq:P582 ?end }

    OPTIONAL { ?ps prov:wasDerivedFrom/pr:P1810 ?sourceName }
    OPTIONAL { ?item rdfs:label ?enLabel FILTER(LANG(?enLabel) = "en") }
    BIND(COALESCE(?sourceName, ?enLabel) AS ?name)
  }
  ORDER BY ?name
SPARQL

url = WIKIDATA_SPARQL_URL % CGI.escape(memberships_query)
headers = { 'User-Agent' => 'every-politican-scrapers/singapore-parliament-official' }
data = Results.new(response: Scraped::Request.new(url: url, headers: headers).response).members

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
abort 'No results' if rows.count.zero?

puts header + rows.join
