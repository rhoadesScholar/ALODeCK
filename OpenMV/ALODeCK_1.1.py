#Automated Live Object-recognition Derived Controller Kit (ALODeCK)
#Jeffrey Lee Rhoades, Harvard University, Copyright June 2019

import sensor, image, time, math
# Color Tracking Thresholds (L Min, L Max, A Min, A Max, B Min, B Max)
# The below thresholds track in general red/green things. You may wish to tune them...
thresholds = [(32, 71, 49, 127, -128, 127), # generic_red_thresholds -> index is 0 so code == (1 << 0)
              (24, 86, -128, -18, 28, 127), # generic_green_thresholds -> index is 1 so code == (1 << 1)
              (0, 100, -128, 127, -128, -44)] # generic_blue_thresholds -> index is 2 so code == (1 << 2)
# You may pass up to 16 thresholds above. However, it's not really possible to segment any
# scene with 16 thresholds before color thresholds start to overlap heavily.

#SETUP
sensor.reset()
sensor.set_pixformat(sensor.RGB565)
sensor.set_framesize(sensor.QVGA)
sensor.skip_frames(time = 2000)
sensor.set_auto_gain(False) # must be turned off for color tracking
sensor.set_auto_whitebal(False) # must be turned off for color tracking
clock = time.clock()

circles = []
variance = [100.0, 100.0, 100.0]
while(sum(variance) > 18 or len(circles) < 10):
    img = sensor.snapshot()
    # Circle objects have four values: x, y, r (radius), and magnitude. The
    # magnitude is the strength of the detection of the circle. Higher is
    # better...

    # `threshold` controls how many circles are found. Increase its value
    # to decrease the number of circles detected...

    # `x_margin`, `y_margin`, and `r_margin` control the merging of similar
    # circles in the x, y, and r (radius) directions.

    # r_min, r_max, and r_step control what radiuses of circles are tested.
    # Shrinking the number of tested circle radiuses yields a big performance boost.

    for c in img.find_circles(threshold = 6000, x_margin = 50, y_margin = 50, r_margin = 50,
        r_min = 50, r_max = 500, r_step = 2):
        img.draw_circle(c.x(), c.y(), c.r(), color = (255, 0, 0), thickness = 3)
        print(c)
        circles.append([c.x(), c.y(), c.r()])

    avg = [sum(subl[subj] for subl in circles)/len(circles) for subj in range(0, len(circles[0]))]
    print(avg)

    variance = [sum(math.pow(subl[subj] - avg[subj], 2) for subl in circles)/len(circles) for subj in range(0, len(avg))]
    print(variance)

ring = img.find_circles(threshold = 6000, x_margin = 50, y_margin = 50, r_margin = 50, r_min = round(avg[2]*.9), r_max = round(avg[2]*1.1), r_step = 2)
print(ring)
#ring['x', 'y', 'r'] = [round(num) for num in avg]
ring = ring[0]

# Only blobs that with more pixels than "pixel_threshold" and more area than "area_threshold" are
# returned by "find_blobs" below. Change "pixels_threshold" and "area_threshold" if you change the
# camera resolution. Don't set "merge=True" becuase that will merge blobs which we don't want here.

#MAIN LOOP
while(True):
    clock.tick()
    img.draw_circle(ring.x(), ring.y(), ring.r(), color = (255, 0, 0))
    img.draw_cross(ring.x(), ring.y(), color = (255, 0, 0))
    img = sensor.snapshot()
    string = ''
    maxButt = 0
    maxHead = 0
    out = [0, 0]
    for blob in img.find_blobs(thresholds, pixels_threshold=50, area_threshold=80):
        # T values are stable all the time.
        # img.draw_rectangle(blob.rect())
        # img.draw_cross(blob.cx(), blob.cy())
        # Note - the blob rotation is unique to 0-180 only.
        if blob.code() == 1 and blob.compactness() > maxButt: #butt
            maxButt = blob.compactness()*blob.pixels()
            butt = blob
        if blob.code() == 2 and blob.compactness() > maxHead: #head
            maxHead = blob.compactness()*blob.pixels()
            head = blob
        img.draw_keypoints([(blob.cx(), blob.cy(), int(math.degrees(blob.rotation())))], size=20)
        # print(blob)

    if maxButt*maxHead > 0:
        img.draw_string(butt.x() + 2, butt.y() + 2, "butt")
        img.draw_string(head.x() + 2, head.y() + 2, "head")
        v1 = [head.cxf() - ring.x(), head.cyf() - ring.y()]
        img.draw_line(ring.x(), ring.y(), ring.x() + round(v1[0]), ring.y() + round(v1[1]), color = (50, 50, 0), thickness = 3)
        mag1 = math.sqrt(sum([math.pow(v, 2) for v in v1]))
        v2 = [head.cxf() - butt.cxf(), head.cyf() - butt.cyf()]
        img.draw_line(butt.cx(), butt.cy(), butt.cx() + round(v2[0]), butt.cy() + round(v2[1]), color = (0, 50, 50), thickness = 3)
        dot = sum([a*b for a,b in zip(v1, v2)])
        if mag1 > ring.r() and dot > 0:
            theta = math.atan(v1[1]/v1[0])
            magP = dot/math.sqrt(sum([math.pow(v, 2) for v in v2])) - ring.r()
            out = [math.copysign(magP*math.cos(theta), v1[0]), math.copysign(magP*math.sin(theta), v1[1])]
            img.draw_line(ring.x(), ring.y(), ring.x() + round(out[0]), ring.y() + round(out[1]), color = (0, 255, 0), thickness = 3)
            print(dot)
            print(out)
            print(theta)
            print(magP)
        print(v1)
        print(v2)

    print(clock.fps())
