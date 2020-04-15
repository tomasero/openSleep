# OpenSleep

The development of the hardware and software for this system started and most of it was done during my first semester at the Fluid Interfaces Group of the MIT Media Lab. This technology was used for many projects, [Dormio](https://www.media.mit.edu/projects/sleep-creativity/ovewview) being the most notable. This project is part of a larger iniatiative called Engineering Dreams, which seeks to build technology that interfaces with the sleeping mind.

![Dormio](/images/dormio.jpg)


## Hardware

### Components

| Qty | Value | Device  | Where |
|:---:|:-----:| -------:| ----- |
|  2  | .1uF  | CAP_CERAMIC0603 | Digikey: [399-1095-1-ND](https://www.digikey.com/product-detail/en/kemet/C0603C104K8RACTU/399-1095-1-ND/411370) |
|  1  |  1uF  | CAP_CERAMIC0603 | Digikey: [399-5090-1-ND](https://www.digikey.com/product-detail/en/kemet/C0603C105K4PACTU/399-5090-1-ND/1465624) | 
|  1  |  1K   | R-US_0503       | Digikey: [YAG1237CT-ND](https://www.digikey.com/product-detail/en/yageo/RT0603BRD071KL/YAG1237CT-ND/4340590) | 
|  2  | 100K  | R-US_R0603      | Digikey: [YAG1235CT-ND](https://www.digikey.com/product-detail/en/yageo/RT0603BRD07100KL/YAG1235CT-ND/4340588) |
|  3  |  1x2  | 1X2-SMD-HEADER  | Digikey: [S1113E-36-ND](https://www.digikey.com/product-detail/en/sullins-connector-solutions/GEC36SBSN-M89/S1113E-36-ND/862247) |
|  1  |  1x3  | 1X3-SMD-HEADER  | Digikey: [S1113E-36-ND](https://www.digikey.com/product-detail/en/sullins-connector-solutions/GEC36SBSN-M89/S1113E-36-ND/862247) |
|  1  |  1x5  | 1X5-SMD-HEADER  | Digikey: [S1113E-36-ND](https://www.digikey.com/product-detail/en/sullins-connector-solutions/GEC36SBSN-M89/S1113E-36-ND/862247) |
|  1  |       | RFD22301        | Digikey: [1562-1016-ND](https://www.digikey.com/product-detail/en/rf-digital-corporation/RFD22301/1562-1016-ND/5056363) |
|  1  | SPDT  | SLIDE-SWITCH    | Digikey: [401-2014-1-ND](https://www.digikey.com/product-detail/en/c-k/AYZ0103AGRLC/401-2014-1-ND/1640123) |
|  1  | Color | LED-1206-SMD    | Digikey: [516-1436-1-ND](https://www.digikey.com/product-detail/en/broadcom-limited/HSMR-C150/516-1436-1-ND/637760) |
|  1  |       | HR-SENSOR       | Adafruit: [1093](https://www.adafruit.com/product/1093) |
|  1  |       | FLEX-SENSOR     | Adafruit: [1070](https://www.adafruit.com/product/1070) |
|  2  |       | EDA-ELECTRODE-CABLE | [OpenBCI](https://shop.openbci.com/collections/frontpage/products/emg-ecg-snap-electrode-cables?variant=32372786958) |
| 2   |       | EDA-ELECTRODE   | [OpenBCI](https://shop.openbci.com/collections/frontpage/products/skintact-f301-pediatric-foam-solid-gel-electrodes-30-pack?variant=29467659395) |

### PCB

#### Design

##### Schematic

![Schematic](/images/design_schematic.png)

##### Layout 

![Layout](/images/design_board.png)


#### Fabrication

You can either mill the PCB yourself using a CNC mill, or buy one from a PCB manufacturer.

##### Mill it

The original PCB for Doormio was made using a Roland MDX-20. All the PNG files used to mill the board can be found in the following folder:

    /hardware/PNG

##### Order it

[Oshpark!](https://oshpark.com/shared_projects/I6SkyNbt)

## Software

### Web App

Run the app:

    node web_app/app.js

Open the app:

    http://localhost:3000

### Mobile App

## Acknowledgements 

[Adam Horowitz](https://www.media.mit.edu/people/adamjhh/overview/) led the experiment design and execution to validate the system, [Oscar Rosello](https://www.media.mit.edu/people/rosello/overview/) the interaction and form factor, and  [Eyal Perry](https://www.media.mit.edu/people/eyalp/overview/) the iOS app development, signal processing and classification (and great mustache).
