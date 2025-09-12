//This macro allows to generate length measurments within an ROI
//Also allows to set minimum and maximum length values. Those under minimum will be excluded, while those over the max will be prompted to select a shorter length and generate a new image.
//Images for inclusion are saved in a new folder, and length measurements are recorded in a .csv
input = getDirectory("Choose folder for starting images");
output = getDirectory("Choose folder for output");
File.setDefaultDir(output);
list = getFileList(input);
list = Array.sort(list);
suffix = ".tif";

Dialog.create("Experiment Info");
		Dialog.addString("Title","Experiment Title",10);
		Dialog.addNumber("Pixel Scale:", 0.10049847,8,5,"(um/pixel)");
		Dialog.addNumber("Min Length", 0);
		Dialog.addNumber("Max Length", 100);
		Dialog.addMessage("0.10049847 = 2048x2048 60x on the dragonfly");
//additional commonly used scale values can be included here for convenience
Dialog.show();
experiment=Dialog.getString();
scale = Dialog.getNumber();
min=Dialog.getNumber();
max=Dialog.getNumber();
print("\\Clear")
print("File"+"	"+"Length"+"	"+"Min-Max "+min+"-"+max);
roiManager("reset");

processFolder(input);
run("Clear Results");
selectWindow("Log");
saveAs("Text", output+File.separator+experiment+" Lengths.csv");

function processFolder(input) {
filelist = getFileList(input);
filelist = Array.sort(filelist);

for (i = 0; i < filelist.length; i++) {
	if(File.isDirectory(input + File.separator + filelist[i]))
		processFolder(input + File.separator + filelist[i]);
	if(endsWith(input + File.separator + filelist[i], suffix))
		processFile(input, output, filelist[i]);
 }
}
function processFile(input, output, file)  {
open(input+file);
setMinAndMax(0, 65535);
run("Enhance Contrast", "saturated=0.35");
run("Set Measurements...", "display redirect=None decimal=5");
run("Properties...", "slices=1 frames=1 unit=micron pixel_width="+scale+" pixel_height="+scale+"");
	title = getTitle();
	roiManager("reset");
	run("Clear Results");
	run("Out [-]");
		title = getTitle();
		setTool("freeline");
		waitForUser ("Measure dendrite length");
		roiManager("Add");
		run("Measure");
		length = getResult("Length",0);	
	if (length < min){
			roiManager("reset");
			close();
	}
	else{
	if(length >=min || length<= max){
		saveAs("Tiff", output+File.separator+title);
		adj=" ";
	}
	if (length>40){
		while (length < min || length > max) {
		roiManager("reset");
		run("Clear Results");
		setTool("freeline");
		waitForUser ("ROI length out of range: Make new dendrite length");
		roiManager("Add");
		run("Measure");
		length = getResult("Length",0);
		}
		adj="adjusted";
		roiManager("select", 0);
		Roi.getBounds(x, y, width, height);
		makeRectangle(x, y, width, height);
		roiManager("Add");
		run("Copy");
		run("Internal Clipboard");
		selectWindow("Clipboard");
		run("Properties...", "slices=1 frames=1 unit=micron pixel_width="+scale+" pixel_height="+scale+"");
		close("\\Others");
		saveAs("Tiff", output+File.separator+title);
	}
	print(title+"	"+length+"	"+adj);
	close();
}
}
