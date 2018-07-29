Copyright (c) 2012 Erik M. Buck

#COLLADAViewer2
An instructional OS X application to load/display COLLADA Models and export to compact binary representations.

COLLADA is a royalty-free XML schema that enables digital asset exchange within the interactive 3D industry. COLLADA is the best way to import complex 3D models into your own applications. Almost every popular 3D modeling tool these days supports export to COLLADA format. As you may suspect, the COLLADA format specification is huge and complex to support just about every kind of information 3D modeling tools might generate.

Apple introduced the new Scene Kit framework in OS X 10.8, "Mountain Lion." Scene Kit is an Objective-C framework for building 3D scenes composed of imported COLLADA 3D models, cameras, lights, and meshes. I highly recommend playing with the new framework including its integration with Xcode 4.2+.

Scene Kit doesn't exist for iOS as of version 6.0, and the framework is probably too "heavyweight" for mobile devices at this time. Apple recommends using off-line tools to convert "heavyweight" data types such as COLLADA models into compact binary representations for use with iOS. Unfortunately, Scene Kit neither provides a conversion capability nor supplies source code you could use as the basis of your own conversion tool.

The "Learning OpenGL ES for iOS" sample code at cosmicthump.com/learning-opengl-es-sample-code/ includes a rudimentary Mac OS X COLLADAViewer.app application with source code in the Chapter 7 examples. COLLADAViewer.app reads and displays a subset of COLLADA models and saves them in a compact binary representation suited for the book's examples. COLLADAViewer.app implements a small portion of the overall COLLADA Specification (pdf), but even with COLLADAViewer.app 's numerous constraints, it still operates as a handy conversion tool to achieve the desirable "compact binary representation" for use in iOS applications.

After the publication of "Learning OpenGL ES for iOS", the limits of COLLADAViewer.app started to become a bit too constraining for my own projects. I started work on a COLLADAViewer2.app application that I'm excited to provide as a new "alpha" version sample with source code.

This repository contians an Xcode project with source code to parse COLLADA XML files and supports a much greater subset of the COLLADA Specification than COLLADAViewer.app. The sample is useful as a demonstration of Apple's Objective-C XML parsing classes in general as well as the specific challenges of COLLADA. The alpha version of COLLADAViewer2 should correctly display almost any COLLADA model that Apple's Preview application can display. Exporting compact binary "modelplist" files from COLLADAViewer2 produces the same result as COLLADAViewer and suffers the same limitations. The next planned improvement to COLLADAViewer2 introduces a new more flexible "compact binary representation" for use in iOS applications.

Everything here is licensed under the permissive MIT License: http://opensource.org/licenses/mit-license.php
