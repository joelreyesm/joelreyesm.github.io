---
layout: page
permalink: /repositories/
title: repositories
description: Code for my research, courses and side projects.
nav: true
nav_order: 4
---

{% if site.data.repositories.github_users %}

<div class="repo-grid">
  {% for user in site.data.repositories.github_users %}
    {% include repository/repo_user.liquid username=user %}
  {% endfor %}
</div>
{% endif %}

{% if site.data.repositories.github_repos %}

## GitHub Repositories

<div class="repo-grid">
  {% for repo in site.data.repositories.github_repos %}
    {% include repository/repo.liquid repository=repo %}
  {% endfor %}
</div>
{% endif %}
