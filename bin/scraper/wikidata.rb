#!/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'csv'
require 'scraped'

WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql?query=%s'

memberships_query = <<SPARQL
  SELECT (STRAFTER(STR(?member), STR(wd:)) AS ?item) ?name
  WHERE {
    ?member p:P39 ?ps .
    ?ps ps:P39 wd:Q21294917 ; pq:P2937 wd:Q104845061 .
    FILTER NOT EXISTS { ?ps pq:P582 ?end }

    OPTIONAL { ?ps prov:wasDerivedFrom/pr:P1810 ?sourceName }
    OPTIONAL { ?member rdfs:label ?enLabel FILTER(LANG(?enLabel) = "en") }
    BIND(COALESCE(?sourceName, ?enLabel) AS ?name)
  }
  ORDER BY ?name
SPARQL

url = WIKIDATA_SPARQL_URL % CGI.escape(memberships_query)
headers = {
  'User-Agent' => 'every-politican-scrapers/singapore-parliament-official',
  'Accept' => 'text/csv',
}

puts Scraped::Request.new(url: url, headers: headers).response.body
