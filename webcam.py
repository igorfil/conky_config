#! /usr/bin/python
# coding=UTF-8

#
#	Downloads random webcam image. Can be used to show webcam images in Conky
#
#

from random import choice
from subprocess import Popen, PIPE
import os

save_path = "/tmp/webcam.jpg"

def loadImage(url):
	"""	
		str -> void
	"""
	command = "wget "+ url + " --output-document=" + save_path

	try:
		p = Popen(command, shell=True,stdout=PIPE, stderr=PIPE)
		out, err = p.communicate()
	except:
		print( "Fail!" )
		return 0

	return 1

webcams = list([
	#put your array of webcams here
	#["ulr","description"],
])

tries = 5
while tries > 0:
	webcam =  choice(webcams)
	if loadImage(webcam[0]) > 0 and os.path.getsize(save_path) > 0:
		break
	tries-=1


print( str(webcam[1]) )

