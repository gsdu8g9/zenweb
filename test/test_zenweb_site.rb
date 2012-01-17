#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class Zenweb::Site
  attr_accessor :layouts
end

class TestZenwebSite < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site

  def setup
    super

    self.site = Zenweb::Site.new
  end

  def test_categories
    site.scan
    cats = site.categories
    assert_equal %w(blog pages projects), cats.keys.sort

    exp = [["blog/2012-01-02-page1.html.md",
            "blog/2012-01-03-page2.html.md",
            "blog/2012-01-04-page3.html.md"],
           ["projects/zenweb.html.erb"],
           ["pages/nonblogpage.html.md"]]

    assert_equal exp, cats.values.map { |a| a.map(&:path).sort }
  end

  def test_config
    assert_equal "_config.yml", site.config.path
  end

  def test_configs
    site.scan

    exp = %w[_config.yml blog/_config.yml]

    assert_equal exp, site.configs.keys.sort

    exp = [Zenweb::Config]
    assert_equal exp, site.configs.values.map(&:class).uniq
  end

  def test_generate
    skip 'not yet'
  end

  def test_inspect
    # we haven't scanned yet, so fast, but boring
    assert_equal "Site[0 pages, 0 configs]", site.inspect
  end

  def test_layout
    site.scan
    assert_equal "_layouts/post.erb", site.layout("post").path
  end

  def test_method_missing
    assert_equal "Example Website", site.header
  end

  def test_pages
    site.scan

    excludes = %w[Rakefile config.ru]

    exp = Dir["**/*"].
      select { |p| File.file? p }.
      reject! { |p| p =~ /(^|\/)_/ }.
      sort - excludes

    assert_equal exp, site.pages.keys.sort

    exp = [Zenweb::Page]

    assert_equal exp, site.pages.values.map(&:class).uniq
  end

  def test_pages_by_date
    skip "this is a serious bitch of a test to write"
    site.scan

    exp = Dir["**/*.html.*"].
      reject! { |p| p =~ /(^|\/)_/ }.
      sort_by { |p| YAML.load_file(p)["date"] || File.mtime(p) }

    assert_equal exp, site.pages_by_date.map(&:path)

    flunk 'not yet'
  end

  def test_scan # the rest is tested via the other tests
    assert_empty site.pages
    assert_empty site.configs
    assert_empty site.layouts

    site.scan

    refute_empty site.pages
    refute_empty site.configs
    refute_empty site.layouts
  end

  def normalize_path p
    p.sub(/(?:\.(md|erb|less))+$/, '').
      sub(/(\d\d\d\d)-(\d\d)-(\d\d)-/, '\1/\2/\3/')
  end

  def test_wire
    Rake.application = Rake::Application.new
    site.scan
    site.wire
    rake = Rake.application
    tasks = rake.tasks

    # HACK: seems there might be a bug in rake w/o this
    Rake::Task.define_task ""

    assert_tasks do
      assert_task ""
      assert_task ".site"
      assert_task ".site/about"
      assert_task ".site/blog"
      assert_task ".site/blog/2012"
      assert_task ".site/blog/2012/01"
      assert_task ".site/blog/2012/01/02"
      assert_task ".site/blog/2012/01/03"
      assert_task ".site/blog/2012/01/04"
      assert_task ".site/css"
      assert_task ".site/img"
      assert_task ".site/js"
      assert_task ".site/pages"
      assert_task ".site/projects"
      assert_task "extra_wirings"

      # stupid simple deps
      assert_task "_layouts/site.erb",                %w[_config.yml]
      assert_task "atom.xml.erb",                     %w[_config.yml]
      assert_task "blog/_config.yml",                 %w[_config.yml]
      assert_task "css/colors.css.less",              %w[_config.yml]
      assert_task "css/styles.css",                   %w[_config.yml]
      assert_task "css/syntax.css",                   %w[_config.yml]
      assert_task "img/bg.png",                       %w[_config.yml]
      assert_task "js/jquery.js",                     %w[_config.yml]
      assert_task "js/site.js",                       %w[_config.yml]
      assert_task "sitemap.xml.erb",                  %w[_config.yml]

      assert_task ".site/about/index.html",           %w[.site/about           about/index.html.md           _config.yml      _layouts/site.erb].sort
      assert_task ".site/atom.xml",                   %w[.site                 atom.xml.erb                  _config.yml].sort
      assert_task ".site/blog/2012/01/02/page1.html", %w[.site/blog/2012/01/02 blog/2012-01-02-page1.html.md blog/_config.yml _layouts/post.erb].sort
      assert_task ".site/blog/2012/01/03/page2.html", %w[.site/blog/2012/01/03 blog/2012-01-03-page2.html.md blog/_config.yml _layouts/post.erb].sort
      assert_task ".site/blog/2012/01/04/page3.html", %w[.site/blog/2012/01/04 blog/2012-01-04-page3.html.md blog/_config.yml _layouts/post.erb].sort
      assert_task ".site/blog/index.html",            %w[.site/blog            blog/index.html.erb           blog/_config.yml _layouts/site.erb].sort
      assert_task ".site/css/colors.css",             %w[.site/css             css/colors.css.less           _config.yml].sort
      assert_task ".site/css/styles.css",             %w[.site/css             css/styles.css                _config.yml].sort
      assert_task ".site/css/syntax.css",             %w[.site/css             css/syntax.css                _config.yml].sort
      assert_task ".site/img/bg.png",                 %w[.site/img             img/bg.png                    _config.yml].sort
      assert_task ".site/index.html",                 %w[.site                 index.html.erb                _config.yml      _layouts/site.erb].sort
      assert_task ".site/js/jquery.js",               %w[.site/js              js/jquery.js                  _config.yml].sort
      assert_task ".site/js/site.js",                 %w[.site/js              js/site.js                    _config.yml].sort
      assert_task ".site/pages/index.html",           %w[.site/pages           pages/index.html.erb          _config.yml      _layouts/site.erb].sort
      assert_task ".site/pages/nonblogpage.html",     %w[.site/pages           pages/nonblogpage.html.md     _config.yml      _layouts/site.erb].sort
      assert_task ".site/projects/index.html",        %w[.site/projects        projects/index.html.erb       _config.yml      _layouts/site.erb].sort
      assert_task ".site/projects/zenweb.html",       %w[.site/projects        projects/zenweb.html.erb      _config.yml      _layouts/project.erb].sort
      assert_task ".site/sitemap.xml",                %w[.site                 sitemap.xml.erb               _config.yml].sort

      assert_task "_layouts/post.erb",                %w[_config.yml      _layouts/site.erb]
      assert_task "_layouts/project.erb",             %w[_config.yml      _layouts/site.erb]
      assert_task "about/index.html.md",              %w[_config.yml      _layouts/site.erb]
      assert_task "blog/2012-01-02-page1.html.md",    %w[blog/_config.yml _layouts/post.erb].sort
      assert_task "blog/2012-01-03-page2.html.md",    %w[blog/_config.yml _layouts/post.erb].sort
      assert_task "blog/2012-01-04-page3.html.md",    %w[blog/_config.yml _layouts/post.erb].sort
      assert_task "blog/index.html.erb",              %w[blog/_config.yml _layouts/site.erb].sort
      assert_task "index.html.erb",                   %w[_config.yml      _layouts/site.erb]
      assert_task "pages/index.html.erb",             %w[_config.yml      _layouts/site.erb]
      assert_task "pages/nonblogpage.html.md",        %w[_config.yml      _layouts/site.erb]
      assert_task "projects/index.html.erb",          %w[_config.yml      _layouts/site.erb]
      assert_task "projects/zenweb.html.erb",         %w[_config.yml      _layouts/project.erb]

      assert_task "site",                             %w[.site .site/js/site.js .site/_layouts/site .site/pages/nonblogpage.html .site/css/colors.css .site/pages/index.html .site/atom.xml .site/css/syntax.css .site/img/bg.png .site/css/styles.css .site/blog/index.html .site/index.html .site/_layouts/project .site/projects/zenweb.html .site/projects/index.html .site/_layouts/post .site/blog/2012/01/04/page3.html .site/blog/2012/01/02/page1.html .site/sitemap.xml .site/blog/2012/01/03/page2.html .site/js/jquery.js .site/about/index.html].sort

      # TODO: remove these
      assert_task ".site/_layouts/post",              %w[_config.yml _layouts/site.erb]
      assert_task ".site/_layouts/project",           %w[_config.yml _layouts/site.erb]
      assert_task ".site/_layouts/site",              %w[_config.yml]
    end
  end
end
