#
# Because GST on OSX doesn't provide support for enumerating the audio
# devices, we do it ourselves. 
#

import logging

from xl import settings
from xl.nls import gettext as _

logger = logging.getLogger(__name__)

import ctypes
import ctypes.util

from ctypes import byref, c_uint32, c_void_p, POINTER, sizeof, Structure

_coreaudio = ctypes.cdll.LoadLibrary(ctypes.util.find_library("coreaudio"))
_corefoundation = ctypes.cdll.LoadLibrary(ctypes.util.find_library("corefoundation"))

_corefoundation.CFStringGetCStringPtr.restype = ctypes.c_char_p
_corefoundation.CFStringGetCStringPtr.argtypes = [ctypes.c_void_p, ctypes.c_int]

_corefoundation.CFRelease.argtypes = [c_void_p]

#
# structures
#

class AudioObjectPropertyAddress(Structure):
    _fields_ = [('mSelector', c_uint32),
                ('mScope', c_uint32),
                ('mElement', c_uint32)]
    
class AudioBuffer(Structure):
    _fields_ = [('mNumberChannels', c_uint32),
                ('mDataByteSize', c_uint32),
                ('mData', c_void_p)]
    
class AudioBufferList(Structure):
    _fields_ = [('mNumberBuffers', c_uint32),
                ('mBuffers', AudioBuffer * 1)]

def __setup_coreaudio():
    # setup coreaudio functions
    fns = [
        ('AudioObjectGetPropertyDataSize', c_uint32, (c_uint32, c_void_p, c_uint32, c_void_p, POINTER(c_uint32))),
        ('AudioObjectGetPropertyData', c_uint32, (c_uint32, c_void_p, c_uint32, c_void_p, POINTER(c_uint32), c_void_p))
    ]
    
    for name, restype, argtypes in fns:
        fn = getattr(_coreaudio, name)
        fn.restype = restype
        fn.argtypes = argtypes


def strord(s):
    if len(s) != 4:
        raise ValueError("Invalid character string")
    
    return ord(s[0])*0x01000000 + ord(s[1])*0x00010000 + ord(s[2])*0x00000100 + ord(s[3])*0x00000001

#
# Constants
#

kAudioHardwareNoError = 0
    
kAudioObjectSystemObject = 1

kAudioHardwarePropertyDevices = strord('dev#')

kAudioObjectPropertyName = strord('lnam')
kAudioObjectPropertyScopeGlobal = strord('glob')
kAudioObjectPropertyScopeOutput = strord('outp')
kAudioDevicePropertyStreamConfiguration = strord('slay')

kAudioObjectPropertyElementMaster = 0


def get_devices():
    '''
        Returns a list of audio devices present on a machine running OSX.
        
        Only tested on Mountain Lion x64, but I have no reason to believe
        it couldn't work on other versions of OSX
    '''
    
    devices = []
    dataSize = ctypes.c_uint32()
    
    # query the number of devices on the system first
    propertyAddress = AudioObjectPropertyAddress()
    propertyAddress.mSelector = kAudioHardwarePropertyDevices
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal
    propertyAddress.mElement = kAudioObjectPropertyElementMaster

    status = _coreaudio.AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, ctypes.byref(propertyAddress), 0, None, dataSize)
    if status != kAudioHardwareNoError:
        return None
    
    # allocate an array for the device ids
    audioDevices = (c_uint32 * (dataSize.value/4))()
    
    # get the data   
    status = _coreaudio.AudioObjectGetPropertyData(kAudioObjectSystemObject, ctypes.byref(propertyAddress), 0, None, dataSize, audioDevices)
    if status != kAudioHardwareNoError:
        return None
    
    # now we have the device ids, get strings associated with them
    # and get rid of useless devices
    
    propertyAddress.mSelector = kAudioObjectPropertyName
    for deviceId in audioDevices:
        
        # get number of output channels
        propertyAddress.mSelector = kAudioDevicePropertyStreamConfiguration
        propertyAddress.mScope = kAudioObjectPropertyScopeOutput
        status = _coreaudio.AudioObjectGetPropertyDataSize(deviceId, byref(propertyAddress), 0, None, dataSize)
        
        if status != kAudioHardwareNoError:
            continue
        
        addr = ctypes.create_string_buffer('', dataSize.value)
        buffer_list = AudioBufferList.from_address(ctypes.addressof(addr))
        status = _coreaudio.AudioObjectGetPropertyData(deviceId, byref(propertyAddress), 0, None, dataSize, byref(buffer_list))
        
        if status != kAudioHardwareNoError:
            continue
        
        # if zero, we don't care
        channels = 0
        for i in xrange(buffer_list.mNumberBuffers):
            channels += buffer_list.mBuffers[i].mNumberChannels 
            
        if channels == 0:
            continue
        
        # get name
        
        namep = c_void_p()
        dataSize.value = sizeof(namep)
        
        propertyAddress.mSelector = kAudioObjectPropertyName
        propertyAddress.mScope = kAudioObjectPropertyScopeGlobal
        
        status = _coreaudio.AudioObjectGetPropertyData(deviceId, byref(propertyAddress), 0, None, dataSize, byref(namep))
        if status != kAudioHardwareNoError:
            continue
        
        name = _corefoundation.CFStringGetCStringPtr(namep, 0)
        _corefoundation.CFRelease(namep)
        
        devices.append((deviceId, name.strip()))
      
    return devices
         

__setup_coreaudio()


def load_osxaudiosink(presets):
    
    preset = {
        "name"          : _("OSX CoreAudio"),
        "pipe"          : "osxaudiosink",
        "get_devices"   : get_devices,
    }
    
    presets["osxaudiosink"] = preset
    
    # make this default if there is no default
    if settings.get_option('player/audiosink', None) == None:
        settings.set_option('player/audiosink', 'osxaudiosink')

