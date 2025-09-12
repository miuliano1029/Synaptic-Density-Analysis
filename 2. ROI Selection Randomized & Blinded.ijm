//2025: UPDATE by M.Iuliano. This macro was modified for a few reasons. 
//(1) Scale for length measurements was from a previous correction. Macro now prompts for image scale at the beginning, allowing for use across different images.
//(2) Naming ROIs individually, making it easier to identify the appropriate item if one needs to go back and re-measure lengths.
//(3) This now allow you to set an input folder rather than opening up each file individually. However, you need to start with a folder containing only the TIF files
//(4) Allows for selection of how many channels within the merge. Works with starting images up to 4 channels.
//(5) Does not incorporate measuring length or area; this is done by separate macros. one for length allows for removal/revision of selections within a min/max length
//(6) Image files are randomized and temporarily blinded to reduce bias. Randomized order list is saved in results folder

input = getDirectory("Choose folder for starting images");
ROIdir = getDirectory("Choose folder for ROI files");
File.setDefaultDir(ROIdir);
list = getFileList(input);
list = Array.sort(list);
suffix = ".tif";

Dialog.create("Experiment Info");
		Dialog.addString("Title","Experiment Title",10);
		Dialog.addNumber("Pixel Scale:", 0.10049847,8,5,"(um/pixel)");
		Dialog.addMessage("0.10049847 = 2048x2048 60x on the dragonfly");
//additional commonly used scale values can be included here for convenience
Dialog.show();
experiment = Dialog.getString();
scale = Dialog.getNumber();
print("\\Clear")
roiManager("reset");
Dialog.create("Channel Info");
	choices = newArray("rectangle","polygon","freehand");
//choices2=newArray("length","area","both");
	Dialog.addChoice("What shape ROI?",choices,"polygon");
//Dialog.addChoice("Record",choices2,"length");
	Dialog.addNumber("How many starting channels?",4,0,1,"channel/s");
	Dialog.addNumber("How many final channels?",4,0,1,"channel/s");
Dialog.show();
choice = Dialog.getChoice();
//choice2 = Dialog.getChoice();
numChan = Dialog.getNumber();
mergeChan= Dialog.getNumber();
Dialog.create("Assign Colors to Each Channel");
	channels = newArray("Cyan","Green","Blue","Red");
	chan= newArray("C1","C2","C3","C4");
	color=Array.trim(channels, numChan);
	for(n=0;n<numChan;n++){
		Dialog.addChoice("Channel "+(n+1),color,color[n]);
		Dialog.addString("", "");
		Dialog.addCheckbox("Visualize in composite view?", 0);
	}
			Dialog.addMessage("Merged file order channels to R-G-B-C");
			Dialog.addMessage("2=RG 3=RGB 4=RGBC");
		
Dialog.show();
chanArray = newArray();
signalArray=newArray();
compviewArray=newArray();
for(n=0;n<numChan;n++) {
	chanArray = Array.concat(chanArray,Dialog.getChoice());
	signalArray = Array.concat(signalArray,Dialog.getString());
	compviewArray=Array.concat(compviewArray,Dialog.getCheckbox());
	if(File.exists(input+chanArray[n])!=1) {
		File.makeDirectory(ROIdir+File.separator+chanArray[n]+" - "+signalArray[n]);
	}
}
compview= String.join(compviewArray, "");
print(compview);


oldchan = "Channel Organization\n";
		for(n=0;n<numChan;n++) {
			oldchan =oldchan+chanArray[n]+" = "+signalArray[n]+"\n";
		}		
getdateandtime();
print(oldchan);
print("Merged file order channels to R-G-B-C");
print("2 Channel=RG 3 Channel=RGB 4 Channel=RGBC");

merge = ROIdir+"Merge";
File.makeDirectory(merge);

zipfile = ROIdir+"ROIs";
File.makeDirectory(zipfile);

processFolder(input);
selectWindow("Log");
saveAs("Text", ROIdir+experiment+" Channel_Info.csv");

function processFolder(input) {
filelist = getFileList(input);
filelist = Array.sort(filelist);
shuffleArray(filelist);
// Create a new Results Table
Table.create("Results");

// Add array values as line items
for (i = 0; i < filelist.length; i++) {
    Table.set("File", i, filelist[i]); // Add each array value to the "Value" column
}
selectWindow("Results");
saveAs("Text", ROIdir +experiment+" Randomized File List.csv");


for (i = 0; i < filelist.length; i++) {
	if(File.isDirectory(input + File.separator + filelist[i]))
		processFolder(input + File.separator + filelist[i]);
	if(endsWith(input + File.separator + filelist[i], suffix))
		processFile(input, ROIdir, filelist[i]);
 }
}
function processFile(input, ROIdir, file)  {
open(input+file);
title = getTitle();
rename("BLIND");
setMinAndMax(0, 65535);
run("Channels Tool...");
Property.set("CompositeProjection", "Sum");
Stack.setDisplayMode("composite");
Stack.setActiveChannels(compview);
Stack.setChannel(1);
run("Color Balance...");
run("Enhance Contrast", "saturated=0.35");
run("Enhance Contrast", "saturated=0.35");
run("Enhance Contrast", "saturated=0.35");
Stack.setChannel(4);
run("Enhance Contrast", "saturated=0.35");
run("Enhance Contrast", "saturated=0.35");
run("Enhance Contrast", "saturated=0.35");
run("Properties...", "channels="+numChan+" slices=1 frames=1 unit=micron pixel_width="+scale+" pixel_height="+scale+"");

	//allows you to check the image before committing to selection
	waitForUser ("Check Image");
	//creates a loop for multiple rois in one image
	roiManager("reset");
	repeat=	getBoolean("Do you have a new ROI in frame?");
while (repeat==1) {
    // Code to execute if the user clicked "Yes"
  		run("Original Scale");
		//this is the function, see the bottom of the macro
    	run("Set Measurements...", "display redirect=None decimal=5");
	setTool(choice);
	selectWindow("BLIND");
	waitForUser ("Select ROI then hit OK");
	roiManager("Add");
	roiManager("Show All");
	count = roiManager("count");
	roiManager("Select", count-1);
    roiManager("Rename", title+" ROI "+count);
	selectWindow("BLIND");
	c=0;
	for(l=0;l<numChan;l++) {	
		setSlice(l+1);
		run("Copy");
		run("Internal Clipboard");
		selectWindow("Clipboard");
		run(chanArray[l]);
		count = roiManager("count");
		saveAs("Tiff", ROIdir+File.separator+chanArray[l]+" - "+signalArray[l]+File.separator+title+" "+count+" "+chanArray[l]+" "+signalArray[l]);
		rename(chanArray[l]);
		selectWindow("BLIND");
		c=c+1;
	}
if (mergeChan == 2){
	run("Merge Channels...", "c1=Red c2=Green create ignore");
	saveAs("Tiff", merge+File.separator+title+" "+count);
	close();
}
if (mergeChan == 3){
	run("Merge Channels...", "c1=Red c2=Green c3=Blue create ignore");
	saveAs("Tiff", merge+File.separator+title+" "+count);
	close();
}
if (mergeChan == 4){
	run("Merge Channels...", "c1=Red c2=Green c3=Blue c4=Cyan create ignore");
	saveAs("Tiff", merge+File.separator+title+" "+count);
	close();
}

	selectWindow("BLIND");
	close("\\Others");
	
	repeat=	getBoolean("Do you have a new ROI in frame?");
	}
	if(repeat !=1) {
		run("ROI Manager...");
		if(roiManager("count") > 0) {
			roiManager("Save", zipfile+File.separator+title+"_ROI.zip");
			close();
			roiManager("reset");
		}
		else {
			close();
			roiManager("reset");
		}
	}
}

function getdateandtime() {
     MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
     DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
     getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
     TimeString ="Date: "+DayNames[dayOfWeek]+" ";
     if (dayOfMonth<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+"\nTime: ";
     if (hour<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+hour+":";
     if (minute<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+minute+":";
     if (second<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+second;
       print(TimeString);
  }
  
  function shuffleArray(a) {
    for (i = a.length - 1; i > 0; i--) {
        j = floor(random() * (i + 1));
        temp = a[i];
        a[i] = a[j];
        a[j] = temp;
    }
  }