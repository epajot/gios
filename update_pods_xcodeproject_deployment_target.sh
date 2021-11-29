#!/bin/bash

# .pbxproj : update IPHONEOS_DEPLOYMENT_TARGET 

perl -pi.bak -e "s/IPHONEOS_DEPLOYMENT_TARGET = 8.0;/IPHONEOS_DEPLOYMENT_TARGET = 10.0;/g" Pods/Pods.xcodeproj/project.pbxproj
