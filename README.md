# Jekyll::AutoAuthors

This plugin integrates with the `jekyll-paginate-v2` gem to provide seamless multiple authors support for jekyll powered publications.

Supporting multiple authors inside a jekyll plugin has been a challenge from long. Here are some references to the issue dating to a long time ago:

- [Author archive pages in Jekyll](https://stackoverflow.com/q/9027527/9819031)
- [Trying to generate author pages in Jekyll plugin for pagination](https://stackoverflow.com/q/23439944/9819031)
- [How to paginate posts by author](https://stackoverflow.com/q/51744240/9819031)

I faced similar problems while managing multiple authors at [Genics Blog](https://genicsblog.com), so I came up with this plugin that solves the problem!

## When to use it?

If you want to achieve any of the following:

- Show author pages that list an author's details.
  
  The details can be anything, like name, bio, portfolio website, social media links, etc.

- Show a list of posts by that author.

  The posts must be paginated. This means if there are a lot of posts, we want to show next and previous buttons for navigation.

- You don't want to manually write anything implementation for the generated pages.
- You just want to drop in a `author: username` to the frontmatter of post and it should add the post to the author's page.

The plugin does exactly this!

## Installation

Add this line to your application's Gemfile inside the `jekyll_plugins` group:

```ruby
group :jekyll_plugins do
    # other gems
    gem "jekyll-paginate-v2"
    gem "jekyll-auto-authors"
end
```

Then, enable the plugin by adding it to the plugins section in the `_config.yml` file:

```yml
plugins:
    # - other plugins
    - jekyll-paginate-v2
    - jekyll-auto-authors
```

And then execute:

    $ bundle install

**Note**: This project depends on utilities inside the [`jekyll-paginate-v2`](https://github.com/sverrirs/jekyll-paginate-v2) plugin to override the autopage and pagination behaviour. Please make sure to install and enable it first.

## Usage

This plugin fits well inside the configuration for `jekyll-paginate-v2` plugin.

First, you need to set pagination configuration inside `_config.yml` file. This is similar to what the pagination plugin does.

```yml
pagination:
  enabled: true
  per_page: 9
  permalink: '/page/:num/'
  title: ':title - page :num'
  sort_field: 'date'
  sort_reverse: true
```

This configuration will be used for the pagination on the generated author pages. The above example defines that each page should get 9 posts at max. The permalink of first page is same, but the later pages get `/page/:num` appended to it. `:num` gets converted to the page number.

To learn more about the pagination setup, please refer to the [pagionation guide](https://github.com/sverrirs/jekyll-paginate-v2/blob/master/README-GENERATOR.md) of `jekyll-paginate-v2` plugin.

Now we'll define the autopages config for authors. `jekyll-paginate-v2` has autopage support for tags, categories and collections by default. [Read more on Autopages](https://github.com/sverrirs/jekyll-paginate-v2/blob/master/README-AUTOPAGES.md).

But it doesn't support autopages for authors. Adding the `jekyll-auto-authors` plugin makes it possible!

Define an `autopages` block to set up author autopages:

```yml
autopages:

  # Other autopage configs stay the same
  enabled: true

  categories:
    enabled: false
  tags:
    enabled: false
  collections:
    enabled: false

  # Add this block
  authors:
    enabled: true
    data: '_data/authors.yml' # Data file with the author details
    # Uncomment the line below to force exclude certain authors from autopage generation.
    # exclude: [ "author1", "author2" ]
    layouts: 
      - 'author.html' # We'll define this layout later
    title: 'Posts by :author'
    permalink: '/author/:author/'
    slugify:
      mode: 'default' # choose from [raw, default, pretty, ascii or latin]
      cased: true # if true, the uppercase letters in slug will be converted to lowercase ones.
```

That's it for the autopages and pagination configuration.

### Optional

You might want to render additional details for each author other than the username.

For an example, let's take a minimal `_data/authors.yml` file. Usernames should be defined at the top level. The plugin provides you the freedom to define particular author's data as you want.

Once you define the usernames, all the data for an author is passed on to the liquid template inside `page.pagination.author_data` variable so you can render it as you wish!

```yml
username1:
  name: 'User 1'
  bio: 'Bio of user 1'
  website: 'http://user1.com'
  socials:
    twitter: '@user1'
    github: 'user1'

username2:
  name: 'User 2'
  bio: 'Bio of user 2'
  website: 'http://user2.com'
  socials:
    twitter: '@user2'
    github: 'user2'

test:
  exclude: true # Skips author from autopage generation only if they have no post assigned.
  name: 'Test user'
  bio: 'Bio of test user'
  website: 'http://test.com'
  socials:
    twitter: '@test'
    github: 'test'

# and so on
```

Let's define a basic template for the `author.html` layout so you get a gist of how to use it:

```html
<!DOCTYPE html>
<html lang="en">

<!-- This has the username of author. The one that you set with "author: name" in front-matter-->
{% assign author_username = page.pagination.author %}

<!-- Use page.pagination.author_data only if you have data file setup correctly -->
{% assign author = page.pagination.author_data %}
<!--
  Now you can use the author variable anyhow.
  It has all the data as defined inside _data/authors.yml for the current username.
-->

  <head>
    <!-- See how we can use values inside the author variable. -->
    <meta name="description" content={{ author.bio }}>
    <!-- other stuff -->
  </head>

  <body>
    <h1>{{ author.name }}</h1>
    <p>{{ author.bio }}</p>
    <a href="{{ author.website }}">Portfolio</a>
    {% assign links = author.socials %}
    <a href="{{ link.twitter }}">Twitter</a>
    <a href="{{ link.github }}">GitHub</a>

    <!--
      The main logic for rendering an author's posts resides here.
      The plugin exposes a paginator object that you can use to loop through the post.
      It handles all the pagination logic for you.
    -->
    {% for post in paginator.posts %}
      {% include postbox.html %}
    {% endfor %}

    <!--
      If there are more pages rendered for current author's posts, show
      "Previous" / "Next" links for navigation
    -->
    {% if paginator.total_pages > 1 %}
    <ul>
      {% if paginator.previous_page %}
      <li>
        <a href="{{ paginator.previous_page_path | prepend: site.baseurl }}">Previous</a>
      </li>
      {% endif %}

      {% if paginator.next_page %}
      <li>
        <a href="{{ paginator.next_page_path | prepend: site.baseurl }}">Next</a>
      </li>
      {% endif %}
    </ul>
    {% endif %}
  </body>

</html>
```

That's it for the prehand configuration!

Now, you can go to any post and just drop in the username to the frontmatter of the post.

```yml
---
# other configs
author: username2
---

A random post.
```

Once you run the build, you'll see the author page for `username2` come inside the `_site/author/username2/` directory. If there are a lot of posts by username2, it will generate pagination pages as defined in the `pagination` block of `_config.yml` file.

## How does it work?

The `jekyll-paginate-v2` plugin does a great job at paginating tags, categories and collections. But it doesn't include support for author pagination and autopages. And the project hasn't received much of updates lately, and the existing issues and PRs are stale because of which I decided to make an extension plugin for it.

This plugin uses the utilty classes and functions from the `jekyll-paginate-v2` plugin to add custom logic for author page generation.

When you run the site, the plugin will go through the unique authors in the site, generating an initial temporary author page for them. Then it loops through the generated authro pages and processes the page for pagination. Simultaneously, it also passes the author data from the data file to the page to render the author details.

Once the pagination pages are generated, they are written to the `_site` folder with the permalink structure you define.

## Need some inspiration?

We are using this plugin to generate the author pages at [Genics Blog](https://genicsblog.com). Have a look at our [`_config.yml`](https://github.com/genicsblog/theme-files/blob/main/_config.yml) file to see how it works.

## The Author

I am a self-taught software developer from India! I am a passionate app developer working on a lot of different kind of projects. If you like this plugin, let me know by supporting me!

The easiest no-brainer way would be to :star2: this plugin by pressing the button on the top right of this page, and [follow me](https://github.com/gouravkhunger) on GitHub. Or consider [buying me a coffee](https://paypal.me/gouravkhunger)!

I write frequent programming related content on [Genics Blog](https://genicsblog.com/author/gouravkhunger/). You can contact me through [our Discord server](https://discord.genicsblog.com).

## Contributing

[Bug reports](https://github.com/gouravkhunger/jekyll-auto-authors/issues) and [pull requests](https://github.com/gouravkhunger/jekyll-auto-authors/pulls) are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/gouravkhunger/jekyll-auto-authors/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/gouravkhunger/jekyll-auto-authors/blob/main/LICENSE).
