# Mello Yello

I'm taking apart a distortion pedal that I own. I bought it at a garage sale in Minneapolis for $20, no tax.
The case is bright yellow (hence the "Yello") and it adds scratchy, high-frequency distortion to anything that passes through it (hence the "Mello" - nobody in our 5-piece folk rock band was a fan).

The innards are hand-soldered and mostly intact, and there's probably fewer than two dozen wires altogether. It seems like a great place to start learning how circuits work. 

## [6 April 2020 - 21 April 2020]
Who knows how circuits work? Not me! I watched some videos to get my head on straight:
 - Pluralsight has [a decent introduction](https://www.pluralsight.com/courses/electronics-fundamentals) to the fundamentals. 
 - Jeremy Blum has an excellent introduction to Eagle, a computer-aided design tool introduced in the Pluralsight course:
   - [Schematic Design](https://www.youtube.com/watch?v=1AXwjZoyNno)
   - [Printed Circuit Board Layout](https://www.youtube.com/watch?v=CCTs0mNXY24)
 - Khan Academy has [a much more thorough introduction](https://www.khanacademy.org/science/electrical-engineering/ee-circuit-analysis-topic) to electrical engineering concepts. 

I took apart the pedal, and got a sense of how everything was connected. I spent a day trying to draw a good circuit
diagram of the thing. It took a few tries, and I'm still not sure what some of the components are, but at least I've
got things sketched out on paper. Take a look [here](https://imgur.com/gallery/sHGTi8P). 

At the moment, I'm working through the Khan Academy videos to better understand how to work out the total resistance
in the circuit. I'll need to do that, and identify a couple of mystery components (which look like resistors, but that
doesn't make electrical sense) before I'm able to figure out the whole circuit. 

Then, I'll be able to:
 - Figure out why the pedal makes the noises it does.
 - Put the whole thing into Eagle. 
 - Finish the project? I'm not sure what "done" looks like yet - perhaps I will:
   - Order and solder my own board through Eagle, and see if it sounds the same. 
   - De-solder and re-solder the whole circuit, to make sure I understand it.
   - Solder additional components on, to change the noise. 

## [23 April 2020]
Aha! Those switches are 2P2T and 3P2T switches.
It doesn't change much, but at least I can draw them correctly
in the schematic now. 

## [26 April 2020]
I bought a digital voltmeter, and learned a few things about the circuit:
 - The potentiometers max out at 10KΩ and 100KΩ, with about 1% variation. 
 - The resistors are 100Ω resistors. 
 - My voltmeter beeps at me when I try to measure resistance on a live circuit, which is great because it would give me terrible readings otherwise. 
 - The whole circuit clocks in at a little over 9V (9.4V) - I'm using a 1 SPOT to power it (rather than a 9V battery), so short of measuring power at the socket, I'm comfortable attributing the variance to that. 

## [3 May 2020]
Next steps for the Mello Yello project:
 - Set up audio in/audio out for my workshop, so I can hear the pedal in action. 
 - I think one of the potentiometers doesn't work - remove it from the circuit, and see if things sound the same. 
 - Re-create the circuit (with 2P2T and 3P2T switches and everything) in Eagle. Then, add it to GitHub - see what it's like to version control a PCB design. 
 
## [5 May 2020]
I set up audio in the workshop, so I can fiddle with the pedal, and understand what's going on. I'm lucky enough to have the [Make Noise 0-coast](http://www.makenoisemusic.com/synthesizers/ohcoast), which I can use to generate pure tones.

Here are my observations for the day:
 - The pedal works in "passthru" mode (3PDT switch does not route to circuit board) with or without power. 
  - This makes sense to me - the passive components will conduct current in to current out, even if there's no power to run the rest of the board. 
 - In "live" mode (3PDT switch routes current through circuit board), the pedal has to have power.
 - In "live" mode, audio in/audio out jacks cannot be switched around.
  - I'm not sure why this is yet. 
  
I set up the 0-coast to make a "ping" noise - a sudden start, with a long tail. I had these additional observations:
 - I can measure the voltage of the "ping" noise, which is pretty cool! 
  - The noise starts at about 0.500V, depending on how loud the 0-coast makes it. 
  - The noise decreases smoothly to about 0.027V, which seems to be a constant low measurement on this circuit. 
  - Voltage seems to correlate to the loudness of the noise produced by the 0-coast (not necessary the loudness of the nosie that makes it to the speaker). 
  
 - At the very end of the noise (from ~0.050V to ~0.027V), there is a sudden clarity of the noise, as though the distortion stopped.
  - Maybe there is a component that doesn't work at these low voltages, or we're routing around a resistor at these low voltages?
 
 - The 100KΩ resistor is basically a volume knob. At full CCW, no sound is produced. 
 - The 100KΩ resistor does not affect voltage in - it only affects voltage out. 
 - For the moment, I do not know how to measure the difference between distorted and non-distored output. 
 
I'll have to read up more on how an electrical current is turned in to an audio signal. I still don't understand what the distortion circuit is doing to change the quality of the noise. 

Further, I think getting everything into Eagle and performing a more thorough circuit analysis will help me understand the unusual behavior between ~0.050V and ~0.027V. 

But, "voltage == loudness" seems like a pretty sensible conclusion to have drawn - the more voltage pouring into the speaker, the stronger the vibrations, the louder the noise. Progress!
