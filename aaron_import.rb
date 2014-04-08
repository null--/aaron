#
# $Id$
# $Revision$
#

=begin
GPLv3:

This file is part of aaron.
aaron is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

aaron is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License
along with Graviton.  If not, see http://www.gnu.org/licenses/.
=end

#TODO

module Msf

###
#
# add your hosts to metasploit database
#
###

class Plugin::AARON_IMPORT < Msf::Plugin

  ###
  #
  # This class implements a socket communication tracker
  #
  ###

  def initialize(framework, opts)
    super
  end

  def cleanup
  end

  def name
    "aaron_import"
  end

  def desc
    "import hosts from a aaron project file"
  end

end
end
