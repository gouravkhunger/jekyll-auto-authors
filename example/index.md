---
layout: home
---

This example jekyll site has {{ site.data.authors | size }} authors:
{% for author in site.data.authors %}<a href="/author/{{author[0] }}">{{ author[1].name }}</a>{% if forloop.last != true %}, {% endif %}{% endfor %}.
{% for author in site.data.authors %}
{% assign posts = site.posts | where_exp:"item", "item.author == author[0]" | size %}
{{ author[1].name }} has {{ posts }} posts.
{% endfor %}

The pagination setting in [`_config.yml`](https://github.com/gouravkhunger/jekyll-auto-authors/tree/main/example/_config.yml) is set to 5 posts per page. Hence, the author pages show their respective posts and when the number exceeds the per page limit, a pagination trail is shown for navigation.

This is done using the [`jekyll-auto-authors`](https://github.com/gouravkhunger/jekyll-auto-authors) plugin. Please read the [setup article](http://genicsblog.com/gouravkhunger/adding-multiple-authors-to-a-jekyll-blog-got-easier#2-using-my-plugin-jekyll-auto-authors) to learn more.

<br />
