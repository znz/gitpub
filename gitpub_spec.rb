# -*- coding: utf-8 -*-
#!/usr/bin/env spec
require "gitpub"
require "rack"
require "tempfile"

describe GitPub, "with linux-2.6" do
  before do
    @git_dir = File.expand_path("linux-2.6/.git")
  end

  it "list all tags without PATH_INFO" do
    gitpub = GitPub.new(@git_dir)
    code, headers, res = gitpub.call({'PATH_INFO' => nil})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    body = res.body.to_s
    /\.\./.should_not =~ body
    /<pre>/.should_not =~ body
  end

  it "list all tags with PATH_INFO=/" do
    gitpub = GitPub.new(@git_dir)
    code, headers, res0 = gitpub.call({'PATH_INFO' => nil})
    code, headers, res1 = gitpub.call({'PATH_INFO' => "/"})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    res0.body.should == res1.body
    body = res1.body.to_s
    /\.\./.should_not =~ body
    /<pre>/.should_not =~ body
  end

  it "list all tags with PATH_INFO=/invalid-tag" do
    gitpub = GitPub.new(@git_dir)
    code, headers, res0 = gitpub.call({'PATH_INFO' => nil})
    code, headers, res1 = gitpub.call({'PATH_INFO' => "/invalid-tag"})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    res0.body.should == res1.body
    body = res1.body.to_s
    /\.\./.should_not =~ body
    /<pre>/.should_not =~ body
  end

  it "list no files with PATH_INFO=/invalid-tag/" do
    gitpub = GitPub.new(@git_dir)
    code, headers, res0 = gitpub.call({'PATH_INFO' => nil})

    temp_stderr = Tempfile.new("stderr")
    orig_stderr = STDERR.dup
    STDERR.reopen(temp_stderr)
    code, headers, res1 = gitpub.call({'PATH_INFO' => "/invalid-tag/"})
    STDERR.reopen(orig_stderr)
    temp_stderr.rewind
    error = temp_stderr.read
    temp_stderr.close
    error.should == "fatal: Not a valid object name invalid-tag:\n"

    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    res0.body.should_not == res1.body
    body = res1.body.to_s
    /\.\./.should =~ body
    /<pre>/.should_not =~ body
  end

  it "list pub tags only without PATH_INFO" do
    gitpub = GitPub.new(@git_dir)
    code, headers, res = gitpub.call({'PATH_INFO' => nil})
    all_tags_length = headers["Content-Length"].to_i
    gitpub = GitPub.new(@git_dir, /\Av2\.6\.\d+\z/)
    code, headers, res = gitpub.call({'PATH_INFO' => nil})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    headers["Content-Length"].to_i.should < all_tags_length
    body = res.body.to_s
    /\.\./.should_not =~ body
    /<pre>/.should_not =~ body
  end

  it "list pub tags only with PATH_INFO=/" do
    gitpub = GitPub.new(@git_dir)
    code, headers, res = gitpub.call({'PATH_INFO' => "/"})
    all_tags_length = headers["Content-Length"].to_i
    gitpub = GitPub.new(@git_dir, /\Av2\.6\.\d+\z/)
    code, headers, res = gitpub.call({'PATH_INFO' => "/"})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    headers["Content-Length"].to_i.should < all_tags_length
    body = res.body.to_s
    /\.\./.should_not =~ body
    /<pre>/.should_not =~ body
  end

  it "list pub tags with PATH_INFO=/invalid-tag/" do
    gitpub = GitPub.new(@git_dir, /\Av2\.6\.\d+\z/)
    code, headers, res0 = gitpub.call({'PATH_INFO' => nil})
    code, headers, res1 = gitpub.call({'PATH_INFO' => "/invalid-tag/"})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    res0.body.should == res1.body
    body = res1.body.to_s
    /\.\./.should_not =~ body
    /<pre>/.should_not =~ body
  end

  it "list no files with PATH_INFO=/v2.6.10/" do
    gitpub = GitPub.new(@git_dir, /\Av2\.6\.\d+\z/)

    temp_stderr = Tempfile.new("stderr")
    orig_stderr = STDERR.dup
    STDERR.reopen(temp_stderr)
    code, headers, res = gitpub.call({'PATH_INFO' => "/v2.6.10/"})
    STDERR.reopen(orig_stderr)
    temp_stderr.rewind
    error = temp_stderr.read
    temp_stderr.close
    error.should == "fatal: Not a valid object name v2.6.10:\n"

    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    res.body.to_s.scan(/<li>/).size.should == 1
    body = res.body.to_s
    /\.\./.should =~ body
    /<pre>/.should_not =~ body
  end

  it "list files with PATH_INFO=/v2.6.11/" do
    gitpub = GitPub.new(@git_dir, /\Av2\.6\.\d+\z/)
    code, headers, res = gitpub.call({'PATH_INFO' => "/v2.6.11/"})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    body = res.body.to_s
    body.scan(/<li>/).size.should > 1
    /\.\./.should =~ body
    /<pre>/.should_not =~ body
  end

  it "list files with PATH_INFO=/v2.6.11/" do
    gitpub = GitPub.new(@git_dir, /\Av2\.6\.\d+\z/)
    code, headers, res = gitpub.call({'PATH_INFO' => "/v2.6.11/"})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    body = res.body.to_s
    body.scan(/<li>/).size.should > 1
    /\.\./.should =~ body
    /<pre>/.should_not =~ body
  end

  it "show file with PATH_INFO=/v2.6.11/COPYING" do
    gitpub = GitPub.new(@git_dir, /\Av2\.6\.\d+\z/)
    code, headers, res = gitpub.call({'PATH_INFO' => "/v2.6.11/COPYING"})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    body = res.body.to_s
    /<pre>/.should =~ body
    /GNU GENERAL PUBLIC LICENSE/.should =~ body
  end

  it "list files with PATH_INFO=/v2.6.11/Documentation/" do
    gitpub = GitPub.new(@git_dir, /\Av2\.6\.\d+\z/)
    code, headers, res = gitpub.call({'PATH_INFO' => "/v2.6.11/Documentation/"})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    body = res.body.to_s
    body.scan(/<li>/).size.should > 1
    /\.\./.should =~ body
    /<pre>/.should_not =~ body
  end

  it "show file with PATH_INFO=/v2.6.11/Documentation/CodingStyle" do
    gitpub = GitPub.new(@git_dir, /\Av2\.6\.\d+\z/)
    code, headers, res = gitpub.call({'PATH_INFO' => "/v2.6.11/Documentation/CodingStyle"})
    code.should == 200
    headers["Content-Type"].should == "text/html; charset=utf-8"
    headers["Content-Length"].should be_instance_of String
    headers["Content-Length"].to_i.should > 0
    body = res.body.to_s
    /<pre>/.should =~ body
    /Linux kernel coding style/.should =~ body
  end

end
