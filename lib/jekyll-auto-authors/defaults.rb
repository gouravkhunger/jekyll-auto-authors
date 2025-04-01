module Jekyll
  module AutoAuthors

    # Default configurations for the plugin.
    DEFAULT = {
      "enabled" => false, # Enable or disable the plugin.

      "data" => nil, # The path to file that contains authors information. example: "_data/authors.yml"
      "layouts" => ["authors.html"], # The layout file inside _layouts/ folder to use for the author pages.

      "exclude" => [], # The list of authors to **force** skip processing an autopage for.

      "title" => "Posts by :author", # :author is replaced by author name.
      "permalink" => "/author/:author", # :author is customizable elements.

      "slugify" => {
        "mode" => "none", # [raw, default, pretty, ascii or latin], none gives back the same string.
        "cased" => false, # If cased is true, all uppercase letters in the result string are replaced with their lowercase counterparts.
      }
    }

  end
end