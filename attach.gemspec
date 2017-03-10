require File.expand_path('../lib/attach/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = "attach"
  s.description   = %q{Attach documents & files to Active Record models}
  s.summary       = s.description
  s.homepage      = "https://github.com/adamcooke/attach"
  s.version       = Attach::VERSION
  s.files         = Dir.glob("{lib}/**/*")
  s.require_paths = ["lib"]
  s.authors       = ["Adam Cooke"]
  s.email         = ["me@adamcooke.io"]
  s.licenses      = ['MIT']
  s.add_runtime_dependency("records_manipulator", ">= 1.0", "< 2.0")
end
