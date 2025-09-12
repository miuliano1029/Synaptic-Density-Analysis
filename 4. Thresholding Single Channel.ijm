//This macro allows you to open a single-channel images within a folder to record or set threshold values
//Record: macro will save manually set thresholds for each image into csv, but there is an option to also export masks and rois of images at that threshold.each will be deposited into a nested folder in output
//Set: if you have a set/flat thresholding value, you can run this macro on a folder of single channel images. Also have the option to extract ROIs as well
//Files will append thresholding value to the end of the image
//NOTE: typical error states "Image does not have an active selection." This means no pixels within the image were above the set threshold

input = getDirectory("Select folder containing starting images");
File.setDefaultDir(input);
output = getDirectory("Select folder to save file/s");

Dialog.create("Get Started");
	Dialog.addString("Title","Experiment Title",10);
	options = newArray("Record Threshold","Set Threshold");
	Dialog.addChoice("Which Function?",options);
	image = newArray("8-bit", "16-bit");
	Dialog.addChoice("Image type",image,"16-bit");
	Dialog.show;
	experiment=Dialog.getString();
	macros = Dialog.getChoice;
	images = Dialog.getChoice();

if (macros == "Record Threshold"){
	Dialog.create("Record Threshold");
	Dialog.addCheckbox("Auto", 0);
	Dialog.addCheckbox("Save mask", 0);
	Dialog.addCheckbox("Save ROI", 0);
Dialog.show;
auto=Dialog.getCheckbox();
savet=Dialog.getCheckbox();
saver=Dialog.getCheckbox();
	print("\\Clear");
	print("File	"+ "Threshold");
	if (savet == true){
	maskdir=output+"Masks";
	File.makeDirectory(maskdir);
	}
	if (saver == true){
	ROIdir=output+"ROIs";
	File.makeDirectory(ROIdir);
	}
	processFolder(input);
	selectWindow("Log");
	saveAs("Text", output+experiment+" Thresholding.csv");
	close("Log");
}

if (macros == "Set Threshold") {
	Dialog.create("Parameter");
    Dialog.addNumber("Threshold:", 1000);
    Dialog.addCheckbox("Generate ROI?", 0);
    Dialog.show();
	threshold = Dialog.getNumber();
    ROI = Dialog.getCheckbox();
    maskdir=output+"Mask "+threshold;
	File.makeDirectory(maskdir);
	if(ROI==1) {
	File.makeDirectory(output + "ROIs");
	}
	processFolder(input);
	}
	
function processFolder(input) {
list = getFileList(input);
list = Array.sort(list);
shuffleArray(list);
// Create a new Results Table
Table.create("Results");

// Add array values as line items
for (i = 0; i < list.length; i++) {
    Table.set("File", i, list[i]); // Add each array value to the "Value" column
}
selectWindow("Results");
saveAs("Text", ROIdir +experiment+" Randomized File List.csv");

for (i = 0; i < list.length; i++) {
	if(File.isDirectory(input + File.separator + list[i]))
		processFolder(input + File.separator + list[i]);
	if(endsWith(list[i],".tif"))
		processFile(input, output, list[i]);
 }
}

function processFile(input, output, file) {
	x=0;
	if(images == "8-bit"){
	a=255;}
	if(images == "16-bit"){
	a=65535;}
	open(input + file);
	if (macros == "Record Threshold"){
		title=getTitle();
rename("BLIND");
			run("Grays");
			setAutoThreshold("Default dark");
			wait(10);
			run("Threshold...");
			if(auto == 0){
			waitForUser("set and record threshold");
			}
			getThreshold(x,a);
			selectImage("BLIND");
		if ( savet== true){
			setThreshold(x,a);
			run("Convert to Mask");
			saveAs("Tiff", maskdir+File.separator+title+" T"+x+".tif");
			}
			if (saver== true){
				run("Create Selection");
				roiManager("Add");
				roiManager("Select", 0);
				roiManager("Rename", title);
				roiManager("save", ROIdir+File.separator+title+" T"+x+"_ROI.zip")
				roiManager("Delete");
			}
			print(title+"	" + x);
			close();
			}		
	
	
	if (macros == "Set Threshold"){
	run("Select All");
	setThreshold(threshold, a);
	run("Convert to Mask");
	rename(output+file+"_mask");
	saveAs("TIFF", maskdir+File.separator+file+" Threshold "+threshold);
	if(ROI==1) {
	run("Create Selection");
	roiManager("Add");
	roiManager("Select", 0);
	roiManager("Rename", file);
	roiManager("save", output + "ROIs"+File.separator+file+" Threshold "+threshold+"_ROI.zip")
	roiManager("Delete");
	}
	close();
	}
}

  function shuffleArray(a) {
    for (i = a.length - 1; i > 0; i--) {
        j = floor(random() * (i + 1));
        temp = a[i];
        a[i] = a[j];
        a[j] = temp;
    }
  }