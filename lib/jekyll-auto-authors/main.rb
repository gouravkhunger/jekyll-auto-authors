module Jekyll
  module AutoAuthors

    # The entrypoint for the plugin, auto called by Jekyll based on priorities.
    # :lowest - after all the plugins are done with their thing.
    class AuthorPageGenerator < Generator
      safe true
      priority :lowest

      def generate(site)
        # load the configs for jekyll-paginate-v2.
        autopage_config = Jekyll::Utils.deep_merge_hashes(PaginateV2::AutoPages::DEFAULT, site.config["autopages"] || {})
        pagination_config = Jekyll::Utils.deep_merge_hashes(PaginateV2::Generator::DEFAULT, site.config["pagination"] || {})

        # Hack for exclude logic to be used later
        autopage_config["authors"]["exclude"] ||= []

        # load the configs for jekyll-auto-authors (this plugin).
        authors_config = Jekyll::Utils.deep_merge_hashes(DEFAULT, site.config["autopages"]["authors"] || {})

        # Do nothing if autopages / author config is disabled.
        if (
          autopage_config["enabled"].nil? ||
          !autopage_config["enabled"] ||
          authors_config["enabled"].nil? ||
          !authors_config["enabled"]
        )
          Jekyll.logger.info "Author Pages:", "Disabled / Not configured properly."
          return
        end

        # Lambda that created the author page for a given author.
        # will be passed to PaginateV2::Autopages for processing.
        createauthorpage_lambda = lambda do | autopage_author_config, pagination_config, layout_name, author, author_original_name |
          # Force skip excluded authors from autopage generation
          return if autopage_author_config["exclude"].include?(author)

          if !autopage_author_config["data"].nil?
            author_data = YAML::load(File.read(autopage_author_config["data"]))[author_original_name]

            if author_data.nil?
              Jekyll.logger.warn "Author Pages:", "Author data for '#{author_original_name}' not found. Page will be generated without data."
            end
          end

          site.pages << AuthorAutoPage.new(site, site.dest, autopage_author_config, pagination_config, layout_name, author, author_original_name)
        end

        posts_to_use = []
        site.collections.each do |coll_name, coll_data|
          if !coll_data.nil?
            # Exclude all pagination pages, as they are not posts.
            # Then for every page store it"s collection name.

            posts_to_use += coll_data.docs.select { |doc| !doc.data.has_key?("pagination") }.each{ |doc| doc.data["__coll"] = coll_name }
          end
        end

        # Pass the config to PaginateV2::AutoPages for processing.
        # autopage_create() indexes the posts into hashes by author (5th parameter here).
        # then checkes if configs are enabled and if so, calls the lambda to generate the author page.
        PaginateV2::AutoPages.autopage_create(
          autopage_config, pagination_config, posts_to_use, "authors", "author", createauthorpage_lambda
        )

        # Set of authors for whom autopages have been created
        finished_pages = Set.new

        posts_to_use.each do | post |
          next if post.data["author"].nil? || finished_pages.include?(post.data["author"])
          finished_pages << post.data["author"]
        end

        if !authors_config["data"].nil?
          # if a data file containing authors is not nil, then iterate through the specified
          # authors to build author pages for them, even if they don't have posts yet.
          author_data = YAML::load(File.read(authors_config["data"]))

          author_data.each do | author, data |
            # The exclude attribute ignores authors from autopage generation unless they have a post assigned.
            if !finished_pages.include?(author) and !data["exclude"]
              # create pages for pending authors with specified layouts
              authors_config['layouts'].each do | layout_name |
                createauthorpage_lambda.call(authors_config, pagination_config, layout_name, author, author)
              end

              finished_pages << author
            end
          end
        end

        # Now auto pages for authors have been created, we can generate the pagination logic.

        # Further logic is mostly similar as PaginateV2::Generator::PaginationModel#paginate(), but we need
        # to override the default pagination logic to include author pages too, so it isn"t called directly.

        # Generate lambda for adding/deleting pages to the site.
        page_add_lambda = lambda do | newpage |
          site.pages << newpage
          return newpage
        end

        page_remove_lambda = lambda do | page_to_remove |
          site.pages.delete_if {|page| page == page_to_remove } 
        end

        # Logs formatted messages, defined similar to the one in PaginateV2::Generator::PaginationModel.
        logging_lambda = lambda do | message, type = "info" |
          if type == "debug"
            Jekyll.logger.debug "Author Pages:","#{message}"
          elsif type == "error"
            Jekyll.logger.error "Author Pages:", "#{message}"
          elsif type == "warn"
            Jekyll.logger.warn "Author Pages:", "#{message}"
          else
            Jekyll.logger.info "Author Pages:", "#{message}"
          end
        end

        # Create an instance of pagination model. We will use some functions from this instance while
        # defining some logic of our own, for overriding the default pagination to include author pages too.
        pagination_model = Jekyll::PaginateV2::Generator::PaginationModel.new(
          logging_lambda, page_add_lambda, page_remove_lambda, nil
        )

        # get posts which have pagination enabled. Ignore hidden posts.
        all_posts = site.collections["posts"].docs.select { |doc| !doc.data.has_key?("pagination") }
        all_posts = all_posts.reject { |doc| doc["hidden"] }

        # The Indexer is responsible for generating the hash for posts indexed by by author.
        # The structure is: {"author1" => {<posts>}, "author2" => {<posts>}, ...}
        posts_by_authors = Jekyll::PaginateV2::Generator::PaginationIndexer.index_posts_by(all_posts, "author")

        # This gets all the pages where pagination is enabled. This also includes Autopages too, 
        # as pagination data is assigned to them while generation (PaginateV2::AutoPages::BaseAutoPage line 45).
        templates = pagination_model.discover_paginate_templates(site.pages)

        templates.each do |template|
          if template.data["pagination"].is_a?(Hash)

            # For each template get the config, skip if paginatio is disabled, or it"s not an author page.
            config = Jekyll::Utils.deep_merge_hashes(pagination_config, template.data["pagination"] || {})
            next if !config["enabled"]
            next if template.data["pagination"]["author"].nil?

            # Filter posts with bad configs.
            pagination_posts = PaginateV2::Generator::PaginationIndexer.read_config_value_and_filter_posts(
              config, "author", all_posts, posts_by_authors
            )

            # Apply sorting to the posts if configured, any field for the post is available for sorting.
            if config["sort_field"]
              sort_field = config["sort_field"].to_s

              pagination_posts.each do |post|
                if post.respond_to?("date")
                  tmp_date = post.date
                  if( !tmp_date || tmp_date.nil? )
                    post.date = File.mtime(post.path)
                  end
                end
              end

              pagination_posts.sort!{ |a,b| 
                PaginateV2::Generator::Utils.sort_values(
                  PaginateV2::Generator::Utils.sort_get_post_data(a.data, sort_field),
                  PaginateV2::Generator::Utils.sort_get_post_data(b.data, sort_field)
                )
              }

              # Remove the first x entries. Defined by "offset" in the config.
              offset_post_count = [0, config["offset"].to_i].max
              pagination_posts.pop(offset_post_count)

              if config["sort_reverse"]
                pagination_posts.reverse!
              end
            end

            # Calculate number of total pages.
            total_pages = (pagination_posts.size.to_f / config["per_page"].to_i).ceil

            # If a upper limit is set on the number of total pagination pages then impose that now.
            if config["limit"] && config["limit"].to_i > 0 && config["limit"].to_i < total_pages
              total_pages = config["limit"].to_i
            end

            # Remove the template page from the site, index pages will be generated in the next steps.
            page_remove_lambda.call(template)
            
            # Store List of all newly created pages, used in creating pagination trails later.
            newpages = []

            # Consider the default index page name and extension.
            indexPageName = config["indexpage"].nil? ? "" : config["indexpage"].split(".")[0]
            indexPageExt =  config["extension"].nil? ? "" : Jekyll::PaginateV2::Generator::Utils.ensure_leading_dot(config["extension"])
            indexPageWithExt = indexPageName + indexPageExt

            total_pages = 1 if total_pages.zero?

            (1..total_pages).each do |cur_page_nr|
              # Create a new page for each page number.
              newpage = Jekyll::PaginateV2::Generator::PaginationPage.new( template, cur_page_nr, total_pages, indexPageWithExt )

              # Create the permalink for the in-memory page, construct title, set all page.data values needed.
              paginated_page_url = config["permalink"]
              first_index_page_url = ""
              if template.data["permalink"]
                first_index_page_url = Jekyll::PaginateV2::Generator::Utils.ensure_trailing_slash(template.data["permalink"])
              else
                first_index_page_url = Jekyll::PaginateV2::Generator::Utils.ensure_trailing_slash(template.dir)
              end
              paginated_page_url = File.join(first_index_page_url, paginated_page_url)
              
              # Create the pager logic for this page, pass in the prev and next page numbers, assign pager to in-memory page.
              newpage.pager = PaginateV2::Generator::Paginator.new( config["per_page"], first_index_page_url, paginated_page_url, pagination_posts, cur_page_nr, total_pages, indexPageName, indexPageExt)

              # Create the url for the new page, make sure to prepend any permalinks that are defined in the template page before.
              if newpage.pager.page_path.end_with? "/"
                newpage.set_url(File.join(newpage.pager.page_path, indexPageWithExt))
              elsif newpage.pager.page_path.end_with? indexPageExt
                # Support for direct .html files.
                newpage.set_url(newpage.pager.page_path)
              else
                # Support for extensionless permalinks.
                newpage.set_url(newpage.pager.page_path + indexPageExt)
              end

              if( template.data["permalink"] )
                newpage.data["permalink"] = newpage.pager.page_path
              end

              # Transfer the title across to the new page.
              if( !template.data["title"] )
                tmp_title = site.title
              else
                tmp_title = template.data["title"]
              end

              # If the user specified a title suffix to be added then add that to all the pages except the first.
              if( cur_page_nr > 1 && config.has_key?("title") )
                newpage.data["title"] = "#{Jekyll::PaginateV2::Generator::Utils.format_page_title(config["title"], tmp_title, cur_page_nr, total_pages)}"
              else
                newpage.data["title"] = tmp_title
              end

              # Signals that this page is automatically generated by the pagination logic.
              # We don"t do this for the first page as it is there to mask the one we removed.
              if cur_page_nr > 1
                newpage.data["autogen"] = "jekyll-paginate-v2"
              end
              
              # Add the page to the site.
              page_add_lambda.call( newpage )

              # Store the page to the internal list.
              newpages << newpage
            end

            # Now generate the pagination number path, so that the users can have a prev 1 2 3 4 5 next structure on their page
            # simplest is to include all of the links to the pages preceeding the current one
            # (e.g for page 1 you get the list 2, 3, 4.... and for page 2 you get the list 3,4,5...)
            if( config["trail"] && !config["trail"].nil? && newpages.size.to_i > 1 )
              trail_before = [config["trail"]["before"].to_i, 0].max
              trail_after = [config["trail"]["after"].to_i, 0].max
              trail_length = trail_before + trail_after + 1

              if( trail_before > 0 || trail_after > 0 )
                newpages.select do | npage |
                  idx_start = [ npage.pager.page - trail_before - 1, 0].max # Selecting the beginning of the trail
                  idx_end = [idx_start + trail_length, newpages.size.to_i].min # Selecting the end of the trail

                  # Always attempt to maintain the max total of <trail_length> pages in the trail (it will look better if the trail doesn"t shrink).
                  if( idx_end - idx_start < trail_length )
                    # Attempt to pad the beginning if we have enough pages.
                    idx_start = [idx_start - ( trail_length - (idx_end - idx_start) ), 0].max
                    # Never go beyond the zero index.
                  end              

                  # Convert the newpages array into a two dimensional array that has [index, page_url] as items.
                  npage.pager.page_trail = newpages[idx_start...idx_end].each_with_index.map {|ipage,idx| Jekyll::PaginateV2::Generator::PageTrail.new(idx_start+idx+1, ipage.pager.page_path, ipage.data["title"])}

                end
              end
            end

          end
        end

        Jekyll.logger.info "Author Pages:", "Generated autopages for #{finished_pages.size} author(s)"
      end
    end

  end
end