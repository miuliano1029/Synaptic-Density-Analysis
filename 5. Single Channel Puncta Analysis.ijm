//set raw result folder. rawdir contains multiple subfolders, each subfolder contains multiple raw images
// result folder should be empty.
rawdir=getDirectory("Choose Starting Images Folder");
index=lastIndexOf(rawdir, File.separator);
foldername=substring(rawdir,0,index);
index2=lastIndexOf(foldername, File.separator);
file=substring(foldername,index2+1);
resultdir=getDirectory("Choose Result Folder");
maskdir = resultdir+File.separator+"Mask";
File.makeDirectory(maskdir);
roidir = resultdir+File.separator+"ROI";
File.makeDirectory(roidir);
//variable setup
var indvthreshold, noise, areapercent, scale, minsize, maxsize, name, noise, count, axonlength, axonflag, name, experiment;
var string, j, d, sum, indexstring, indexnum, tvalue, Label2Array, resultlist, FolderCreate, foldername, LabelArray, CS, nindex, length, axonlength;
// input parameter
run("Set Measurements...", "area perimeter integrated area_fraction limit redirect=None decimal=5");
getdateandtime();
// function, available in ImageJ 1.34n or later.
  parameterinput();
run("Clear Results");
print("Raw_Folder:	"+rawdir);
print("Result_Folder:	"+resultdir+" \n");

print("ChannelThreshold	PixelScale(um/pixel)	Min_Puncta_Size	Max_Puncta_Size	Prominence	Measurement");
print(indvthreshold+"	"+scale+"	"+minsize+"	"+maxsize+"	"+noise+"	"+length+" \n");

filelist=getFileList(rawdir);
    sum="Filename,Threshold,#Puncta,Length,TotalArea,IntDen,RawIntDen,		,Puncta_10um,AvgSize,AvgInt_AU\n";
	string="Filename,Coverslip,File,#,Area,Perim,IntDen,RawIntDen\n";

    for(d=0;d<filelist.length;d++)
        {
        // initialize :  open file
        initialize();
        // create mask images and roi files
        mask();
        }
   	File.saveString(string, resultdir+File.separator+experiment+" "+file+" Individual_Puncta.csv");
    File.saveString(sum, resultdir+File.separator+experiment+" "+file+" Average Puncta.csv"); 
    selectWindow("Log");
saveAs("Text", resultdir+File.separator+experiment+" "+file+" Puncta Analysis.csv");
selectWindow("Log"); run("Close");
selectWindow("Results"); run("Close");
selectWindow("ROI Manager"); run("Close");
selectWindow("Summary"); run("Close");
close("Length");
close("Threshold");
run("Close All");
//the following functions are listed in order of use in the macro
//thresholding parameters are generally the only ones that need changing, but all can be modified
 //print day and time of macro
 
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
 
 //macro parameters including scale, thresholding, etc
  function parameterinput()
    {
    Dialog.create("Parameters");
        Dialog.addString("Title","Experiment Title",10);
       	Dialog.addNumber("Pixel Scale (um/pixel):", 0.10048828);
        Dialog.addNumber("Min Puncta Size (pixel):", 10);
        Dialog.addNumber("Max Puncta Size (pixel):", 250);
        Dialog.addNumber("Noise tolerance/prominence", 50);
        Dialog.addMessage("!!Double check appropriate scaling/expected puncta size/prominence values!!");
    Dialog.show();
    experiment=Dialog.getString();
    scale = Dialog.getNumber();  
    minsize = Dialog.getNumber();  
    maxsize = Dialog.getNumber();
   	noise = Dialog.getNumber();
   	Dialog.create("Measurements");
   	  Dialog.addCheckbox("Length Measurements Available?", 1);
   	   Dialog.addCheckbox("Thresholding Measurements Available?", 1);
   	  Dialog.show();
   	  length = Dialog.getCheckbox();
   	  tvalue= Dialog.getCheckbox();
	
	  if(length == 1){
		path = File.openDialog("Select a .csv of length/area measurements");
 		Table.open(path);
 		Table.rename(Table.title, "Length");
	LabelArray=newArray();
	LabelArray=Table.getColumn("File");
    }
    if(length == 0){
axonlength=1;
    }
    if(tvalue == 1){
    	path2 = File.openDialog("Select a .csv of threshold measurements");
    	Table.open(path2);
 		Table.rename(Table.title, "Threshold");
 			Label2Array=newArray();
	Label2Array=Table.getColumn("File");
    }
        if(tvalue ==0){
Dialog.create("Set Thresholding");
			Dialog.addNumber("Threshold:", 1000);
			Dialog.show;
indvthreshold=Dialog.getNumber();
}
   	  
    }
    
//this function opens the appropriate image from the appropriate folder in the raw data folder
//gets the name, standardizes the properties of the image, splits the channels and discards the blue channel as "axon" to be saved elsewhere
function initialize()
 {
    open(rawdir+filelist[d]);
    name=getInfo("image.filename"); 
   
  if(length == 1){
  	for (i = 0; i < lengthOf(LabelArray); i++) {
        if (startsWith(LabelArray[i],name)) {
        	selectWindow("Length");
           axonlength=Table.get("Length", i);
        }
  }
  }
    if(tvalue == 1){
  	for (i = 0; i < lengthOf(Label2Array); i++) {
        if (startsWith(Label2Array[i],name)) {
        selectWindow("Threshold");
        indvthreshold=Table.get("Threshold", i);
        }
  }
  }
    roiManager("reset");
    getDimensions(width, height, channels, slices, frames);
    run("Properties...", "channels=1 slices=1 frames=1 unit=um pixel_width="+scale+" pixel_height="+scale+" voxel_depth=1");
 }
//this function creates a mask for the selected color channel (green or red). 
//it takes the threshold indicated in the parameter input, uses it to point out the maxima 
//and then runs "analyze particles" within the specified puncta size, saves the number of puncta as a string, saves the ROI, 
//and saves the mask
function mask()	{
	selectImage(name);
		setThreshold(indvthreshold, 65535);
		run("Find Maxima...", "prominence="+noise+" above output=[Segmented Particles]");
//this find the maximum pixel value within the thresholded area in order to segment into separate particles.
//Prominence is a noise tolerance setting, where a maxima can only be 
//Included prominence customixation in 2024, seems 10 is suited for 8bit, 100+ best for 16bit segmentation
	selectWindow(name+" Segmented");  
	run("Analyze Particles...", "size="+minsize+"-"+maxsize+" pixel show=Masks summarize add");
   selectWindow("Mask of "+name+" Segmented");  
	run("Grays");
	saveAs("Tiff", maskdir+File.separator+name+"_mask.tif");
	selectWindow(name);
	run("Clear Results");
	roiManager("Measure");	
	selectWindow("Results");
		
		for (i = 0; i < nResults; i++) {

		string = string+name+","+i+1+","+getResult("Area",i)+","+getResult("Perim.",i)+","+getResult("IntDen",i)+","+getResult("RawIntDen",i)+"\n";
			       	}
	run("Clear Results");
	selectImage(name+" Segmented"); close();
		count = roiManager("Count");
	selectImage(name+"_mask.tif");
	rename(name+" mask");
	
	if( roiManager("Count") > 0 )
		{
		roiManager("Save",roidir+File.separator+name+"_ROI.zip");
		run("Clear Results");	
		selectImage(name);
		roiManager("Combine");
		roiManager("Add");
		countss=roiManager("count");
		roiManager("select", countss-1);
		roiManager("measure");
		selectWindow("Results");
			for(j=0;j<nResults;j++) {
			sum = sum+name+","+indvthreshold+","+count+","+axonlength+","+getResult("Area",j)+","+getResult("IntDen",j)+","+getResult("RawIntDen",j)+","+"	"+","+(count/axonlength)*10+","+(getResult("Area",j)/count)+","+(getResult("RawIntDen",j)/getResult("Area",j))+"\n";
					}
	roiManager("reset");
	}
		close("*"); 
}
	