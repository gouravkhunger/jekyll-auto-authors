module Jekyll
  module AutoAuthors

    # Default configurations for the plugin.
    DEFAULT = {
      "enabled" => false, # Enable or disable the plugin.

      "data" => "_data/authors.yml", # The data file inside _data/ folder that contains author information.
      "layouts" => ["authors.html"], # The layout file inside _layouts/ folder to use for the author pages.

      "title" => "Posts by :author", # :author is replaced by author name.
      "permalink" => "/author/:author", # :author is customizable elements

      "slugify" => {
        "mode" => "none", # [raw, default, pretty, ascii or latin], none gives back the same string.
        "cased" => false, # If cased is true, all uppercase letters in the result string are replaced with their lowercase counterparts.
      }
    }

  end
end