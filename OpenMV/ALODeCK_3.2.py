#Automated Live Object-recognition Derived Controller Kit (ALODeCK)
#Jeffrey Lee Rhoades, Harvard University, Copyright June 2019

import sensor, image, time, math, pyb, array, gc, micropython
# Color Tracking Thresholds (L Min, L Max, A Min, A Max, B Min, B Max)
# The below thresholds track in general red/green things. You may wish to tune them...
thresholds = [(20, 100, 0, 127, 0, 127), # generic_red_thresholds -> index is 0 so code == (1 << 0)
              (10, 100, 20, 127, -128, -40)] # generic_blue_thresholds -> index is 1 so code == (1 << 1)
              #(20, 100, -128, -5, -128, 127), # generic_green_thresholds -> index is 2 so code == (1 << 2)
              #(20, 100, -54, -1, 7, 53)] # generic_IR_thresholds -> index is 3 so code == (1 << 3)
radius = 5
windowX = 240
windowY = 240
buttColor = 2
headColor = 1
fps = 120
calThresh = [(50, 100, -128, 127, -128, 127)]
calTimeOut = 10000


#SETUP
sensor.reset()
sensor.set_hmirror(True)
sensor.set_vflip(True)
sensor.set_pixformat(sensor.RGB565)
sensor.set_framesize(sensor.QVGA)
sensor.set_windowing((windowX, windowY)) # 240x240 center pixels of VGA
sensor.set_auto_gain(False, gain_db = 20) # must be turned off for color tracking
sensor.set_gainceiling(128)
sensor.set_auto_whitebal(False, rgb_gain_db = (-6.0, -3.0, 2)) # must be turned off for color tracking
#sensor.set_brightness(-1)
sensor.set_saturation(3)
#sensor.set_quality(100)
#sensor.set_auto_exposure(False, 1000)
#sensor.set_contrast(3)
sensor.skip_frames(time = 2000)
clock = time.clock()

#kernel_size = 1 # 3x3==1, 5x5==2, 7x7==3, etc.
#kernel = [-2, -1,  0, \
          #-1,  6,  -1, \
           #0,  -1,  -2]

while(True):
    usb = pyb.USB_VCP() # This is a serial port object that allows you to
    # communciate with your computer. While it is not open the code below runs.
    led = pyb.LED(1) # Switch to using the red LED.
    led.on()
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
    img.draw_circle(round(windowX/2), round(windowY/2), radius, thickness = 2, color = (0, 0, 255))
    maxMag = 0
    for c in img.find_circles(threshold = 500, x_margin = 50, y_margin = 50, r_margin = 50,
        r_min = radius - 1, r_max = radius + 1, r_step = 1):
        if maxMag < c.magnitude():
            maxMag = c.magnitude()
            ring = c
            print(c)
            usb.write(str('Getting ring...\n'))
    led.off()

    #FIND MAX AMPLITUDE OF DISPLACEMENT

    led1 = pyb.LED(1) # Red LED = 1, Green LED = 2, Blue LED = 3, IR LEDs = 4.
    led2 = pyb.LED(3)
    led1.on()
    led2.on()

    maxAmp = []
    variance = [1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0]
    clock.tick()
    while(sum(variance) > 400 or len(maxAmp) < 10) and (gc.mem_free() > 2) and (clock.avg() < calTimeOut):
        img = sensor.snapshot().histeq(adaptive=True, clip_limit=2.5)
        #img.morph(kernel_size, kernel) # Run the kernel on every pixel of the image.
        usb.write(str('Finding max amp...\n'))
        maxCal = 0
        for blob in img.find_blobs(calThresh, pixels_threshold=6, area_threshold=8):
            if (blob.area())  > maxCal:
                maxCal = blob.area()
                cal = blob
                img.draw_keypoints([(blob.cx(), blob.cy(), int(math.degrees(blob.rotation())))], size=20)

        if maxCal > 0:
            img.draw_string(cal.x() + 2, cal.y() + 2, "calibrator")

            calV = [cal.cxf() - ring.x(), cal.cyf() - ring.y()]
            calMag = math.sqrt(sum([math.pow(v, 2) for v in calV]))
            calMagO = max([calMag - ring.r(), 0])
            calTheta = math.atan(calV[1]/calV[0])
            calVO = [math.copysign(calMagO*math.cos(calTheta), calV[0]), math.copysign(calMagO*math.sin(calTheta), calV[1])]
            img.draw_line(cal.cx(), cal.cy(), cal.cx() - round(calV[0]), cal.cy() - round(calV[1]), color = (50, 50, 0), thickness = 3)

            #dot = sum([a*b for a,b in zip(headVO, bodyV)])
            #magP = dot/bodyMag
            maxAmp.append([calVO[0], calVO[1], calV[0], calV[1], 1, 1])

            avg = [sum(subl[subj] for subl in maxAmp)/len(maxAmp) for subj in range(0, len(maxAmp[0]))]
            #print(avg)

            variance = [sum(math.pow(subl[subj] - avg[subj], 2) for subl in maxAmp)/len(maxAmp) for subj in range(0, len(avg))]
            #print(variance)
    #print(maxAmp)
    if (sum(variance) > 400 or len(maxAmp) < 10):
        calV = [windowX - ring.x(), windowY - ring.y()]
        calMag = math.sqrt(sum([math.pow(v, 2) for v in calV]))
        calMagO = max([calMag - ring.r(), 0])
        calTheta = math.atan(calV[1]/calV[0])
        calVO = [math.copysign(calMagO*math.cos(calTheta), calV[0]), math.copysign(calMagO*math.sin(calTheta), calV[1])]
        maxAmp = [calVO[0], calVO[1], calV[0], calV[1], 1, 1]
        usb.write(str('Max amp inferred.\n'))
        gc.collect()
    else:
        maxAmp = [math.fabs(a) for a in avg]
    led = pyb.LED(2) # Switch to using the green LED.
    led.on()
    time.sleep(150)
    led.off()


    #MAIN LOOP
    #out = array.array('d', [0, 0, 0, 0, 0, 0])
    clock.tick()
    while(usb.isconnected()):
        #img.draw_circle(ring.x(), ring.y(), ring.r(), color = (255, 0, 0))
        # img.draw_cross(ring.x(), ring.y(), color = (255, 0, 0))
        gc.collect()
        sensor.snapshot().histeq(adaptive=True, clip_limit=2.5)
        #img.morph(kernel_size, kernel) # Run the kernel on every pixel of the image.

        maxButt = 0
        maxHead = 0
        for blob in sensor.get_fb().find_blobs(thresholds, pixels_threshold=6, area_threshold=10):
            if blob.code() == buttColor and (blob.area())  > maxButt: #butt
                maxButt = blob.area()
                butt = blob
                #img.draw_keypoints([(blob.cx(), blob.cy(), int(math.degrees(blob.rotation())))], size=20)
            if blob.code() == headColor and (blob.area())  > maxHead: #head
                maxHead = blob.area()
                head = blob
                #img.draw_keypoints([(blob.cx(), blob.cy(), int(math.degrees(blob.rotation())))], size=20)

        if maxButt*maxHead > 0:
            #img.draw_string(butt.x() + 2, butt.y() + 2, "butt")
            #img.draw_string(head.x() + 2, head.y() + 2, "head")

            headV = [head.cxf() - ring.x(), head.cyf() - ring.y()]
            headMag = math.sqrt(sum([math.pow(v, 2) for v in headV]))
            headMagO = max([headMag - ring.r(), 0])

            buttV = [butt.cxf() - ring.x(), butt.cyf() - ring.y()]
            buttMag = math.sqrt(sum([math.pow(v, 2) for v in buttV]))
            buttMagO = max([buttMag - ring.r(), 0])
            #img.draw_line(butt.cx(), butt.cy(), butt.cx() - round(buttV[0]), butt.cy() - round(buttV[1]), color = (0, 50, 50), thickness = 3)

            if headMagO*1.05 > buttMagO:
                headTheta = math.atan(headV[1]/headV[0])
                headVO = [math.copysign(headMagO*math.cos(headTheta), headV[0]), math.copysign(headMagO*math.sin(headTheta), headV[1])]
                #img.draw_line(head.cx(), head.cy(), head.cx() - round(headV[0]), head.cy() - round(headV[1]), color = (50, 50, 0), thickness = 3)
                bodyV = [head.cxf() - butt.cxf(), head.cyf() - butt.cyf()]
                #img.draw_line(butt.cx(), butt.cy(), butt.cx() + round(bodyV[0]), butt.cy() + round(bodyV[1]), color = (0, 50, 50), thickness = 3)
                dot = sum([a*b for a,b in zip(headVO, bodyV)])
                bodyMag = math.sqrt(sum([math.pow(v, 2) for v in bodyV]))
                magP = dot/bodyMag
                temp = [math.copysign(magP*math.cos(headTheta), headV[0]), math.copysign(magP*math.sin(headTheta), headV[1]), headV[0], headV[1], bodyV[0], bodyV[1]]
                out = array.array('d', [a/b for a,b in zip(temp, maxAmp)])
                #out[0] /= maxAmp[0]
                #out[1] /= maxAmp[1]
                #NOTE: out = [radially adjusted normalized X, radially adjusted normalized Y, raw normalized X, raw normalized Y, body vector X, body vector Y)
                #img.draw_line(head.cx(), head.cy(), head.cx() - round(headV[0]), head.cy() - round(headV[1]), color = (0, 0, 250), thickness = 3)
                #img.draw_line(ring.x(), ring.y(), ring.x() + round(out[0]), ring.y() + round(out[1]), color = (0, 255, 0), thickness = 3)
                print(out)
                usb.send(out, timeout = round(1000/fps))
                #usb.write(out, timeout = round(1000/fps))
        while clock.avg() < 1000/fps:
            pyb.udelay(500)
        clock.tick( )
