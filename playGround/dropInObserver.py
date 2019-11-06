# LED Control Example
#
# This example shows how to control your OpenMV Cam's built-in LEDs. Use your
# smart phone's camera to see the IR LEDs.

import time, sensor
from pyb import LED

red_led   = LED(1)
green_led = LED(2)
blue_led  = LED(3)
ir_led    = LED(4)

#Set LED to use here:
red_led.on()
#green_led.on()
#blue_led.on()
#ir_led.on()

#SETUP
sensor.reset()
sensor.set_hmirror(True)
sensor.set_vflip(True)
sensor.set_pixformat(sensor.RGB565)
sensor.set_framesize(sensor.QQVGA)
sensor.set_auto_gain(True) # must be turned off for color tracking
sensor.set_auto_whitebal(True)
#sensor.set_quality(100)
sensor.set_auto_exposure(True)
#sensor.set_contrast(3)
sensor.skip_frames(time = 2000)

while(True):
    img = sensor.snapshot()#.histeq(adaptive=True, clip_limit=2.5)
    time.sleep(30)
