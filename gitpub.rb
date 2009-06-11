#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# = gitpub.rb
#
# Web application to publish static files based on git and rack.
#
# Pub means 'publish' and supporting only static files like publicfile of DJB.
#
# == Example Usage
#
# execute some commands:
#  gem install rack
#  git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux-2.6.git
#  rackup -d linux-2.6.ru
# and open http://localhost:9292/ with your browser.
#
# linux-2.6.ru is:
#  require 'gitpub'
#  run GitPub.new('linux-2.6/.git', /\Av2\.6\.\d+\z/)
#
#
# == License (The MIT License)
#
# Copyright (c) 2009 Kazuhiro NISHIYAMA
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#


require 'erb'
require 'rack/mime'

class GitPub
  include ERB::Util

  # path to git command
  GIT_BIN = "git"

  # Create GitPub instance.
  #
  # git_dir :: path to .git or git bare repository.
  # pub_tag_regexp :: Regexp of publish tag.
  #                   Recommends use \A and \z instead of ^ and $.
  # title :: HTML title prefix. Default is repository's directory name.
  def initialize(git_dir, pub_tag_regexp=/\A([^\/:]+)\z/, title=nil)
    @git_dir = git_dir
    @pub_tag_regexp = pub_tag_regexp
    unless title
      title = File.basename(git_dir)
      if title == ".git"
        title = File.basename(File.dirname(git_dir))
      end
    end
    @title = title
  end

  # Wrapper of git command.
  def git(*args)
    IO.popen("-", "r") do |io|
      if io
        yield io
      else
        #STDERR.puts [GIT_BIN, "--git-dir", @git_dir, *args].inspect
        exec(GIT_BIN, "--git-dir", @git_dir, *args)
      end
    end
  end
  private :git

  # List public tags.
  def list_pub_tag(env, res)
    tags = []
    git("tag") do |io|
      io.each_line do |line|
        line.chomp!
        if @pub_tag_regexp =~ line
          tags << $&
        end
      end
    end
    tags.sort!
    E_list_pub_tag.result(binding)
  end

  # ERB template of list_pub_tag.
  E_list_pub_tag = ERB.new(<<-ERUBY, 1, '-')
<html>
<head>
<title><%=h @title %></title>
</head>
<body>
<h1><%=h @title %></h1>
<ul>
<%- tags.each do |tag| -%>
<li><a href="<%=h tag %>/"><%=h tag %></a></li>
<%- end -%>
</ul>
</body>
</html>
  ERUBY

  # List files in the blob (tag or directory)
  def list_files(env, res, tag, path)
    files = []
    git("ls-tree", "-z", "#{tag}:#{path}") do |io|
      io.each_line("\0") do |line|
        line.chomp!("\0")
        #STDERR.puts line
        info, file = line.split(/\t/, 2)
        mode, type, object = info.split(/ /)
        files << {
          :mode => mode,
          :type => type,
          :object => object,
          :file => file,
        }
      end
    end
    files = files.sort_by{|h| h[:file] }
    E_list_files.result(binding)
  end

  # ERB template of list_files.
  E_list_files = ERB.new(<<-ERUBY, 1, '-')
<html>
<head>
<title><%=h @title %> <%=h tag %>:<%=h path %></title>
</head>
<body>
<h1><%=h @title %> <%=h tag %>:<%=h path %></h1>
<ol>
<li><a href="..">..</a></li>
<%- files.each do |h| -%>
  <%- case h[:type] -%>
  <%- when "tree" -%>
<li><a href="<%=h h[:file] %>/"><%=h h[:file] %>/</a></li>
  <%- when "blob" -%>
<li><a href="<%=h h[:file] %>"><%=h h[:file] %></a></li>
  <%- else -%>
<li><%=h h[:file] %></li>
  <%- end -%>
<%- end -%>
</ol>
</body>
</html>
  ERUBY

  # Show file content of object.
  # Content-Type choose by Rack::Mime.mime_type of file extension.
  # Default is text/plain.
  def show_file(env, res, tag, path)
    body = "(empty)"
    git("show", "#{tag}:#{path}") do |io|
      body = io.read
    end
    mime_type = Rack::Mime.mime_type(File.extname(path), "text/plain")
    if mime_type != "text/plain"
      res.write body
      res['Content-Type'] = mime_type
      return
    end
    E_show_file.result(binding)
  end

  # ERB template of show_file.
  E_show_file = ERB.new(<<-ERUBY, 1, '-')
<html>
<head>
<title><%=h @title %> <%=h tag %>:<%=h path %></title>
</head>
<body>
<h1><%=h @title %> <%=h tag %>:<%=h path %></h1>
<p><a href=".">back</a><p>
<pre><%=h body %></pre>
</body>
</html>
  ERUBY

  # Rack interface.
  def call(env)
    res = Rack::Response.new
    body = nil
    if /\A\/([^\/:]+)\// =~ env['PATH_INFO']
      tag, rest = $1, $'
    end
    if tag && @pub_tag_regexp =~ tag
      if /\/\z/ =~ env['PATH_INFO']
        body = list_files(env, res, tag, rest)
      else
        body = show_file(env, res, tag, rest)
      end
    else
      body = list_pub_tag(env, res)
    end
    if body
      res.write body
      res['Content-Type'] = 'text/html; charset=utf-8'
    end
    res.finish
  end
end
