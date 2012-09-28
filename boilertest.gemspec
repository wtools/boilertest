Gem::Specification.new do |s|
  s.name        = 'boilertest'
  s.version     = '0.0.0'
  s.date        = '2012-08-28'
  s.summary     = "Common functional tests made easy"
  s.description = "Common functional tests made easy"
  s.authors     = ["Johan VAN RYSEGHEM", "Cédric NÉHÉMIE"]
  s.email       = 'nick@quaran.to'
  s.files       = ["lib/boilertest.rb"]
  # s.homepage    =
    # 'http://rubygems.org/gems/hola'
  s.add_dependency('factory_girl_rails', '>= 4.0.0')
end