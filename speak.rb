#!/usr/bin/env ruby

require 'yaml'

def remove_specific_instruction_type_from_end menu_position, instruction_type
  reversed = menu_position.reverse
  new_menu_position = []
  counter = 0
  reversed.each do |item|
    if item == instruction_type
      counter += 1
    else
      break
    end
  end
  return reversed[counter..-1].reverse
end

def check_if_possible menu, menu_position
  current_menu = menu
  previous_menu = menu
  sub_menu = menu
  sub_menu_name = ''
  menu_position.each do |item|
    sub_menu_name = ''
    previous_menu = current_menu
    case item
    when 'left'
      raise "There shouldn't be #{item} in the menu position."
    when 'up'
      current_menu = [sub_menu[-1]]
      menu_position = menu_position[0..-2]
      menu_position += ['down']*(sub_menu.length-1)
    when 'right'
      if current_menu[0]['sub_menu']
        sub_menu_name = 'menu '+current_menu[0]['name']
        sub_menu = current_menu[0]['sub_menu']
      end
      current_menu = current_menu[0]['sub_menu']
    when 'down'
      current_menu = current_menu[1..-1]
    end
  end
  # We chose a submenu but there's no submenu here
  if !current_menu
    current_menu = previous_menu
    menu_position = menu_position[0..-2]
  end
  # We're at the lower end of the menu
  if !current_menu[0]
    # puts 'end of menu'
    current_menu = sub_menu
    # Remove all the 'down's, jump to top of menu again.
    # Should be disabled if set top box doesn't jump to the top when
    # the bottom of the menu is reached.
    menu_position = remove_specific_instruction_type_from_end menu_position, 'down'
  end
  puts "\n"
  if sub_menu_name != ''
    thing_to_say = sub_menu_name+' '+current_menu[0]['name']
  else
    thing_to_say = current_menu[0]['name']
  end
  puts thing_to_say
  return thing_to_say, menu_position
end

file_name = ARGV.shift || 'menu.yaml'

if (/darwin/ =~ RUBY_PLATFORM) != nil
  program = 'say'
else
  program = 'espeak'
end

menu = YAML.load_file file_name

puts menu

menu_position = []

`#{program} main menu`
`#{program} #{menu[0]['name']}`
while instruction = gets.chomp
  last_element = menu_position[-1]
  case instruction
  when 'left'
    if menu_position.include? 'right'
      # Remove all the 'down's
      menu_position = remove_specific_instruction_type_from_end menu_position, 'down'
      # Remove 'right' item from menu position
      menu_position = menu_position[0..-2]
      `#{program} back`
    end
  when 'up'
    if last_element == 'down'
      menu_position = menu_position[0..-2]
    else 
      menu_position.push instruction
    end
  when 'down', 'right'
    menu_position.push instruction
  else
    STDERR.puts "Unknown instruction '#{instruction}'"
  end
  item_to_speak, menu_position = check_if_possible menu, menu_position
  `#{program} #{item_to_speak}`
end
