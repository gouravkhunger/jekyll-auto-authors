module Jekyll
  module AutoAuthors

    class AuthorAutoPage < PaginateV2::AutoPages::BaseAutoPage
      def initialize(site, base, autopage_config, pagination_config, layout_name, author, author_name)

        # Get the slugify configuration if available.
        slugify_config = autopage_config.is_a?(Hash) && autopage_config.has_key?("slugify") ? autopage_config["slugify"] : nil

        # Construct the lambda function to set the config values this
        # function receives the pagination config hash and manipulates it.
        set_autopage_data_lambda = lambda do | in_config |
          in_config["author"] = author

          return if autopage_config["data"].nil?

          # if the data file containing authors info is not nil, transfer current author's data
          # to the paginator object so that it can be used in the pagination template
          author_data = YAML::load(File.read(File.join(site.source, autopage_config["data"]))) || {}

          if author_data.key?(author_name)
            in_config["author_data"] = author_data[author_name]
          else
            Jekyll.logger.warn "Author Pages:", "Data for author '#{author_name}' not found. Page will be generated without data."
          end
        end

        # Lambdas to return formatted permalink and title.
        get_autopage_permalink_lambda = lambda do |permalink_pattern|
          return Utils.format_author_macro(permalink_pattern, author, slugify_config)
        end

        get_autopage_title_lambda = lambda do |title_pattern|
          return Utils.format_author_macro(title_pattern, author, slugify_config)
        end
                
        # Call the super constuctor from the base generator with our custom lambda.
        super(site, base, autopage_config, pagination_config, layout_name, set_autopage_data_lambda, get_autopage_permalink_lambda, get_autopage_title_lambda, author_name)
        
      end

    end
    
  end
end