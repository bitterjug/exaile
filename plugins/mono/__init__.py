# mono - Downmix Exaile's audio to one channel
# Copyright (C) 2013  Johannes Sasongko <sasongko@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# The developers of the Exaile media player hereby grant permission
# for non-GPL compatible GStreamer and Exaile plugins to be used and
# distributed together with GStreamer and Exaile. This permission is
# above and beyond the permissions granted by the GPL license by which
# Exaile is covered. If you modify this code, you may extend this
# exception to your version of the code, but you are not obligated to
# do so. If you do not wish to do so, delete this exception statement
# from your version.


import gst
import xl.providers
from xl.player.pipe import ElementBin


class Mono(ElementBin):
    index = 90
    name = 'mono'
    def __init__(self, player):
        ElementBin.__init__(self, player, name=self.name)
        self.elements[50] = gst.element_factory_make('audioconvert')
        self.elements[60] = cf = gst.element_factory_make('capsfilter')
        cf.props.caps = gst.Caps('audio/x-raw-int, channels=1', 'audio/x-raw-float, channels=1')
        self.setup_elements()


def enable(exaile):
    xl.providers.register('stream_element', Mono)

def disable(exaile):
    xl.providers.unregister('stream_element', Mono)


# vi: et sts=4 sw=4 tw=80
