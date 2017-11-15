# Module to create common dirs. Some modules try to create the same directories leading to conflicts in puppet
# This module can create a list of directories with the required permissions for each directory level to create
# the directories in advance.
# Uses a hieradata hash data structure. See examples. $sysdirs is used to exclude system dirs from being touched.

class local::create_dirs(
  $dirs_path = {},
  $sysdirs   = [ '/etc', '/var', '/usr' ]
) {
  validate_hash($dirs_path)
  if(size(keys($dirs_path)) > 0) {
    $yaml = inline_template('
---
  <% dirs_array = Array.new; @dirs_path.keys.sort.each do |this_path|
     dirs = this_path.split("/")
     unless @dirs_path[this_path].nil? then
       modes = @dirs_path[this_path][0].nil? ? [] : @dirs_path[this_path][0].split("/")
       owner = @dirs_path[this_path][1].nil? ? [] : @dirs_path[this_path][1].split("/")
     else
       modes = []
       owner = []
     end
     dirs.delete_at(0)
     a=""; b = ""
     dirs.each_with_index do |dir, i|
       a = sprintf("%s/%s",a,dir)
       c = i+1
       unless dirs_array.include? a or @sysdirs.include? a
       dirs_array.push(a) %>
<%= a %>:
  ensure: "directory"
  <% if modes[c] then %>
  mode: "<%= modes[c] %>"
  <% end %>
  <% if owner[c] then %>
  owner: "<%= owner[c] %>"
  <% end %>
  <% if b != "" and ! @sysdirs.include? b -%>require: File[<%= b %>] <% end %>
    <% end -%>
      <% b = a -%>
  <% end -%>
<% end %>
   ')

#   notify {"yaml: $yaml":}
    $dirdata = parseyaml($yaml)
#   notify {"topdirs: $topdirdata":}
    create_resources('file', $dirdata)
  }
}
