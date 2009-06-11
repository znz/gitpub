Gem::Specification.new do |s|
  s.name = "gitpub"
  s.version = "0.1.1"
  s.date = "2009-06-11"
  s.summary = "web application to publish static files based on git and rack"
  s.email = "zn@mbf.nifty.com"
  s.homepage = "http://github.com/znz/gitpub"
  s.has_rdoc = true
  s.authors = ["Kazuhiro NISHIYAMA"]
  s.require_paths = ["."]
  s.files = ["README", "gitpub.rb", "gitpub_spec.rb", "linux-2.6.ru"]
  s.add_dependency("rack", ["> 0.9.0"])
end
