LED_FILES = [
  'led_string.rb',
  'animator.rb',
  'generators.rb',
  'gamma.rb'
]

def reload
  LED_FILES.map{|f| {f => load(f)}}.reduce :merge
end

reload
