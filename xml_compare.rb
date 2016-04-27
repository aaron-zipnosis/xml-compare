#!/usr/bin/env ruby

require 'nokogiri/diff'
require 'pry'

def get_file(file)
  Nokogiri::XML(open(file))
end

def compare_elements(old_xml, new_xml, type)
  puts "\n\n==============================#{type.capitalize}s==============================\n\n"

  found_new_elements = []
  missing_old_elements = []
  non_matching_elements = []

  old_elements = get_old_elements(old_xml, type)
  new_elements = get_new_elements(new_xml, type)

  old_elements.each do |old_element|
    new_element = new_elements.find do |new_element|
      new_element.xpath('./zid').text == old_element.xpath('./id').text
    end

    if new_element.nil?
      missing_old_elements << old_element.xpath('./id').text
    else
      found_new_elements << new_element.xpath('./zid').text
      # elements don't match
      unless send("#{type}_matches?", old_element, new_element)
        non_matching_elements << { old: old_element, new: new_element }
      end
    end
  end

  missing_new_elements = new_elements.map { |t| t.xpath('./zid').text } - found_new_elements
  puts "Old #{type}s count: #{old_elements.count}"
  puts "New #{type}s count: #{new_elements.count}"
  puts "#{missing_old_elements.count} missing old #{type}s from new xml: #{missing_old_elements}"
  puts "#{missing_new_elements.count} missing new #{type}s from old xml: #{missing_new_elements}"
  puts "Non Matching ids: #{non_matching_elements.map{|ele|ele[:new].xpath('./zid').text}}"

  puts "#{non_matching_elements.count} different xmls: "
  non_matching_elements.each do |element|
    puts "Old #{type}: "
    puts "    #{element[:old]}"
    puts "\nNew #{type}: "
    puts "    #{element[:new]}"
    puts "\n\n"
  end
end

def thought_matches?(old_thought, new_thought)
  flag = true
  flag = false unless old_thought.xpath('./comment').children.text == new_thought.xpath('./comment-str').children.text

  if old_thought.xpath('./be-seen').children.text == 'on' # Be Seen On
    flag = false unless "!#{old_thought.xpath('./formula').children.text}" == new_thought.xpath('./formula').children.text
    flag = false unless new_thought.xpath('./be-seen').children.text == 'true'
  else #No Be Seen
    flag = false unless old_thought.xpath('./formula').children.text == new_thought.xpath('./formula').children.text
    flag = false unless new_thought.xpath('./be-seen').children.text == ''
  end
  flag
end

def assessment_matches?(old_assessment, new_assessment)
  flag = true
  # flag = false unless old_assessment.xpath('./order').text == new_assessment.xpath('./order-float').text
  flag = false unless old_assessment.xpath('./comment').text == new_assessment.xpath('./comment-str').text
  flag = false unless old_assessment.xpath('./icd').text == new_assessment.xpath('./icd').text
  flag = false unless old_assessment.xpath('./thought').text == new_assessment.xpath('./thought-id').text
  flag = false unless old_assessment.xpath('./points').text == new_assessment.xpath('./points').text
  flag
end

def option_matches?(old_option, new_option)
  flag = true
  # flag = false unless old_option.xpath('./order').text == new_option.xpath('./order-float').text
  flag = false unless old_option.xpath('./fragment').text == new_option.xpath('./fragment').text
  flag = false unless old_option.xpath('./choice').text == new_option.xpath('./choice').text
  flag = false unless old_option.xpath('./comment').text == new_option.xpath('./comment-str').text
  flag = false unless old_option.xpath('./question').text == new_option.xpath('./question-id').text
  flag = false unless old_option.xpath('./value').text == new_option.xpath('./value').text
  flag
end

def fragment_matches?(old_fragment, new_fragment)
    # binding.pry if new_fragment.xpath('./zid').text == '1'
  flag = true
  # flag = false unless old_fragment.xpath('./order').text == new_fragment.xpath('./order-float').text
  flag = false unless old_fragment.xpath('./text').text == new_fragment.xpath('./text-str').text
  flag = false unless old_fragment.xpath('./formula').text == new_fragment.xpath('./formula').text
  flag = false unless old_fragment.xpath('./fragment').text == new_fragment.xpath('./fragment-id').text
  flag
end

def question_matches?(old_question, new_question)
  # binding.pry if new_question.xpath('./zid').text == '15'
  flag = true
  flag = false unless old_question.xpath('./layout').text == new_question.xpath('./layout/name').text
  flag = false unless old_question.xpath('./thought').text == new_question.xpath('./thought-id').text
  flag = false unless old_question.xpath('./comment').text == new_question.xpath('./comment-str').text
  flag = false unless old_question.xpath('./label').text == new_question.xpath('./label').text
  # flag = false unless old_question.xpath('./order').text == new_question.xpath('./order-float').text
  flag
end

def compare_documents(old_xml, new_xml)
  compare_medical_content(old_xml, new_xml)
  compare_elements(old_xml, new_xml, 'thought')
  compare_elements(old_xml, new_xml, 'assessment')
  compare_elements(old_xml, new_xml, 'question')
  compare_elements(old_xml, new_xml, 'fragment')
  compare_elements(old_xml, new_xml, 'option')
end

def get_document(xml)
  xml.document
end

def get_medical_content(xml)
  get_document(xml).elements[0]
end

def get_old_elements(xml, type)
  get_medical_content(xml).xpath("./#{type}")
end

def get_new_elements(xml, type)
  xml.xpath(".//#{type}s/#{type}")
end

old_xml = get_file ARGV[0]
new_xml = get_file ARGV[1]

compare_documents(old_xml, new_xml)

exit 0
