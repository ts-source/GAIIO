#  this script sets the pod property for all repositories that match a certain abbrv (passed in) in the organization
#  the pod property must be pre-created in the org if it's not

require 'octokit'
owner = 'dv'
owner = 'ts-source'

# The abbreviation and full name from command line arguments
abbrv = ARGV[0]
full_name = ARGV[1]

if abbrv.nil? || full_name.nil?
  puts "Please provide both the abbreviation and full name as command line arguments."
  exit
end

# Create a new Octokit client
client = Octokit::Client.new(access_token: ENV['GH_PAT'])
client.auto_paginate = true

# print out all scopes my PAT has access to
puts client.scopes.join(", ") + "\n====\n"

# get all repos for the org
repos = client.org_repos(owner)

matching_repos = repos.select { |repo| repo.name.downcase.start_with?(abbrv.downcase) }

if matching_repos.empty?
  puts "No repositories matching the abbreviation '#{abbrv}' found."
  exit
end

green="\e[32m"
normal="\e[0m"

puts "\nAbout to set the pod value of #{full_name} for these repos:\n#{green}  " + matching_repos.map(&:name).join(', ') + "#{normal}\n"

# puts "\nAre you sure you want to continue? (Y/N)"
# confirmation = STDIN.gets.chomp.downcase
# if confirmation != 'y'
#   puts "Operation cancelled."
#   exit
# end

matching_repos.each do |repo|
  puts repo.name
  begin
    client.patch "/orgs/#{owner}/properties/values", {
      org: owner,
      repository_names: [repo.name],
      properties: [{ property_name: 'pod', value: full_name }],
      headers: {
        'X-GitHub-Api-Version': '2022-11-28'
      }
    }
  rescue Octokit::UnprocessableEntity
    puts "Has the 'pods' property been created at the organization level yet?"
  end # begin (rescue block)
end # matching_repos.each
