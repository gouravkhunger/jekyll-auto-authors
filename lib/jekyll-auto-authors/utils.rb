module Jekyll
  module AutoAuthors

    class Utils

      def self.format_author_macro(toFormat, author, slugify_config=nil)
        slugify_mode = slugify_config.has_key?("mode") ? slugify_config["mode"] : nil
        slugify_cased = slugify_config.has_key?("cased") ? slugify_config["cased"] : false
        return toFormat.sub(":author", Jekyll::Utils.slugify(author.to_s, mode:slugify_mode, cased:slugify_cased))
      end

    end

  end
end