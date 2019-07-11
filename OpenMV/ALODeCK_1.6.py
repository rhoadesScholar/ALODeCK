#Automated Live Object-recognition Derived Controller Kit (ALODeCK)
#Jeffrey Lee Rhoades, Harvard University, Copyright June 2019

import sensor, image, time, math, pyb, array
# Color Tracking Thresholds (L Min, L Max, A Min, A Max, B Min, B Max)
# The below thresholds track in general red/green things. You may wish to tune them...
thresholds = [(30, 100, 0, 127, -128, 127), # generic_red_thresholds -> index is 0 so code == (1 << 0)
              (30, 100, -128, -5, -128, 127), # generic_green_thresholds -> index is 1 so code == (1 << 1)
              (16, 40, 0, 96, -128, -44), # generic_blue_thresholds -> index is 2 so code == (1 << 2)
              (50, 100, 4, 20, -128, 7)] # generic_IR_thresholds -> index is 3 so code == (1 << 3)
radius = 40
windowX = 240
windowY = 240
buttColor = 2
headColor = 1

#SETUP
sensor.reset()
sensor.set_pixformat(sensor.RGB565)
sensor.set_framesize(sensor.QVGA)
sensor.set_windowing((windowX, windowY)) # 240x240 center pixels of VGA
sensor.skip_frames(time = 2000)
sensor.set_auto_gain(False) # must be turned off for color tracking
sensor.set_auto_whitebal(False)#, rgb_gain_db = (0.0, 0.0, 0.0)) # must be turned off for color tracking
sensor.set_brightness(-3)
sensor.set_saturation(3)
#sensor.set_contrast(-1)
clock = time.clock()
led = pyb.LED(1) # Red LED = 1, Green LED = 2, Blue LED = 3, IR LEDs = 4.

kernel_size = 1 # 3x3==1, 5x5==2, 7x7==3, etc.
kernel = [-2, -1,  0, \
          -1,  1,  1, \
           0,  1,  2]

while(True):
    usb = pyb.USB_VCP() # This is a serial port object that allows you to
    # communciate with your computer. While it is not open the code below runs.
    while(not usb.isconnected()):
        led.on()
        time.sleep(150)
        led.off()
        time.sleep(100)
        led.on()
        time.sleep(150)
        led.off()
        time.sleep(600)

    led = pyb.LED(3) # Switch to using the blue LED.
    led.on()

    #MAKE RING
    img = sensor.snapshot()
    img.clear()
    img.draw_circle(round(windowX/2), round(windowY/2), radius, color = (0, 0, 255), thickness = 2)
    maxMag = 0
    for c in img.find_circles(threshold = 500, x_margin = 50, y_margin = 50, r_margin = 50,
        r_min = radius - 1, r_max = radius + 1, r_step = 1):
        if maxMag < c.magnitude():
            maxMag = c.magnitude()
            ring = c
            print(c)
            usb.write(str('Getting ring...'))
    led.off()

    #FIND MAX AMPLITUDE OF DISPLACEMENT

    maxAmp = []
    variance = [1000.0, 1000.0]
    while(sum(variance) > 80 or len(maxAmp) < 10):
        img = sensor.snapshot()#.histeq(adaptive=True, clip_limit=1)
        #img.morph(kernel_size, kernel) # Run the kernel on every pixel of the image.
        usb.write(str('Finding max amp...'))
        maxButt = 0
        maxHead = 0
        for blob in img.find_blobs(thresholds, pixels_threshold=4, area_threshold=4):
            if blob.code() == buttColor and blob.compactness() > maxButt: #butt
                maxButt = blob.compactness()#*blob.pixels()
                butt = blob
                img.draw_keypoints([(blob.cx(), blob.cy(), int(math.degrees(blob.rotation())))], size=20)
            if blob.code() == headColor and blob.compactness() > maxHead: #head
                maxHead = blob.compactness()#*blob.pixels()
                head = blob
                img.draw_keypoints([(blob.cx(), blob.cy(), int(math.degrees(blob.rotation())))], size=20)

        if maxButt*maxHead > 0:
            img.draw_string(butt.x() + 2, butt.y() + 2, "butt")
            img.draw_string(head.x() + 2, head.y() + 2, "head")

            headV = [head.cxf() - ring.x(), head.cyf() - ring.y()]
            headMag = math.sqrt(sum([math.pow(v, 2) for v in headV]))
            headMagO = max([headMag - ring.r(), 0])
            headTheta = math.atan(headV[1]/headV[0])
            headVO = [math.copysign(headMagO*math.cos(headTheta), headV[0]), math.copysign(headMagO*math.sin(headTheta), headV[1])]
            img.draw_line(head.cx(), head.cy(), head.cx() - round(headV[0]), head.cy() - round(headV[1]), color = (50, 50, 0), thickness = 3)

            buttV = [butt.cxf() - ring.x(), butt.cyf() - ring.y()]
            buttMag = math.sqrt(sum([math.pow(v, 2) for v in buttV]))
            buttMagO = max([buttMag - ring.r(), 0])
            img.draw_line(butt.cx(), butt.cy(), butt.cx() - round(buttV[0]), butt.cy() - round(buttV[1]), color = (0, 50, 50), thickness = 3)

            bodyV = [head.cxf() - butt.cxf(), head.cyf() - butt.cyf()]
            img.draw_line(butt.cx(), butt.cy(), butt.cx() + round(bodyV[0]), butt.cy() + round(bodyV[1]), color = (0, 50, 50), thickness = 3)

            if headMagO > buttMagO:
                dot = sum([a*b for a,b in zip(headVO, bodyV)])
                bodyMag = math.sqrt(sum([math.pow(v, 2) for v in bodyV]))
                magP = dot/bodyMag
                maxAmp.append([math.copysign(magP*math.cos(headTheta), headV[0]), math.copysign(magP*math.sin(headTheta), headV[1])])
                img.draw_line(head.cx(), head.cy(), head.cx() - round(headV[0]), head.cy() - round(headV[1]), color = (0, 0, 250), thickness = 3)

                avg = [sum(subl[subj] for subl in maxAmp)/len(maxAmp) for subj in range(0, len(maxAmp[0]))]
                #print(avg)

                variance = [sum(math.pow(subl[subj] - avg[subj], 2) for subl in maxAmp)/len(maxAmp) for subj in range(0, len(avg))]
                #print(variance)
    #print(maxAmp)
    maxAmp = avg
    led = pyb.LED(2) # Switch to using the green LED.
    led.on()
    time.sleep(150)
    led.off()

    # Only blobs that with more pixels than "pixel_threshold" and more area than "area_threshold" are
    # returned by "find_blobs" below. Change "pixels_threshold" and "area_threshold" if you change the
    # camera resolution. Don't set "merge=True" becuase that will merge blobs which we don't want here.

    #MAIN LOOP
    while(usb.isconnected()):
        clock.tick()
        img.draw_circle(ring.x(), ring.y(), ring.r(), color = (255, 0, 0))
        img.draw_cross(ring.x(), ring.y(), color = (255, 0, 0))
        img = sensor.snapshot()#.histeq(adaptive=True, clip_limit=3)

        #img.morph(kernel_size, kernel) # Run the kernel on every pixel of the image.

        maxButt = 0
        maxHead = 0
        out = array.array('d', [0, 0])
        for blob in img.find_blobs(thresholds, pixels_threshold=4, area_threshold=4):
            if blob.code() == buttColor and blob.compactness() > maxButt: #butt
                maxButt = blob.compactness()#*blob.pixels()
                butt = blob
                #img.draw_keypoints([(blob.cx(), blob.cy(), int(math.degrees(blob.rotation())))], size=20)
            if blob.code() == headColor and blob.compactness() > maxHead: #head
                maxHead = blob.compactness()#*blob.pixels()
                head = blob
                #img.draw_keypoints([(blob.cx(), blob.cy(), int(math.degrees(blob.rotation())))], size=20)

        if maxButt*maxHead > 0:
            img.draw_string(butt.x() + 2, butt.y() + 2, "butt")
            img.draw_string(head.x() + 2, head.y() + 2, "head")

            headV = [head.cxf() - ring.x(), head.cyf() - ring.y()]
            headMag = math.sqrt(sum([math.pow(v, 2) for v in headV]))
            headMagO = max([headMag - ring.r(), 0])
            headTheta = math.atan(headV[1]/headV[0])
            headVO = [math.copysign(headMagO*math.cos(headTheta), headV[0]), math.copysign(headMagO*math.sin(headTheta), headV[1])]
            #img.draw_line(head.cx(), head.cy(), head.cx() - round(headV[0]), head.cy() - round(headV[1]), color = (50, 50, 0), thickness = 3)

            buttV = [butt.cxf() - ring.x(), butt.cyf() - ring.y()]
            buttMag = math.sqrt(sum([math.pow(v, 2) for v in buttV]))
            buttMagO = max([buttMag - ring.r(), 0])
            #img.draw_line(butt.cx(), butt.cy(), butt.cx() - round(buttV[0]), butt.cy() - round(buttV[1]), color = (0, 50, 50), thickness = 3)

            bodyV = [head.cxf() - butt.cxf(), head.cyf() - butt.cyf()]
            #img.draw_line(butt.cx(), butt.cy(), butt.cx() + round(bodyV[0]), butt.cy() + round(bodyV[1]), color = (0, 50, 50), thickness = 3)

            if headMagO > buttMagO:
                dot = sum([a*b for a,b in zip(headVO, bodyV)])
                bodyMag = math.sqrt(sum([math.pow(v, 2) for v in bodyV]))
                magP = dot/bodyMag
                out = array.array('d', [math.copysign(magP*math.cos(headTheta), headV[0]), math.copysign(magP*math.sin(headTheta), headV[1])])
                out[0] /= maxAmp[0]
                out[1] /= maxAmp[1]
                #img.draw_line(head.cx(), head.cy(), head.cx() - round(headV[0]), head.cy() - round(headV[1]), color = (0, 0, 250), thickness = 3)
                #img.draw_line(ring.x(), ring.y(), ring.x() + round(out[0]), ring.y() + round(out[1]), color = (0, 255, 0), thickness = 3)
        print(out)
        usb.write(out)
        #print(clock.fps())