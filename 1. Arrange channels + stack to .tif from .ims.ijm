//this macro was redesigned in 2024 by M. Iuliano
//starting with raw image files, this allows for batch opening & processing
//for all z-projection types (MAX MIN AVG MED STD SUM) while also re-ordering channels
//DEFAULT: working with .ims files and pulling from bioformat importer

input = getDirectory("Select folder containing raw images");
output = getDirectory("Select folder to save images in");
print("\\Clear");
//Parameters for the z-stack
//You are able to choose what kind of projection you want, the order/number of the channels in the final image, 
//what type of files you are starting with, and if you want RGB output
stack = newArray("MAX","MIN","AVG","SUM","SD","MED","");
	Dialog.create("Arrange Channels");
		Dialog.addNumber("Number of initial channels",4,0,1,"channel/s");
		Dialog.addNumber("Number of channels in final image",4,0,1,"channel/s");
		Dialog.addString("Starting image type", ".ims");
		Dialog.addString("Final image as a flat RGB? ","no");
		Dialog.addChoice("Z-stack",stack);
	Dialog.show();
	numChan = Dialog.getNumber();
	finChan = Dialog.getNumber();
	suffix= Dialog.getString();
	flat = Dialog.getString();
	ztack = Dialog.getChoice();
	Dialog.create("starting channels & staining");
		channels =newArray("C1","C2","C3","C4");
		color = newArray("Cyan","Green","Red","Blue");
		signalchannel = newArray("405","488","568","647");
		for(n=0;n<numChan;n++){
			Dialog.addChoice(channels[n],signalchannel,signalchannel[n]);
			Dialog.addString("", "antibody/signal",20);
		
		}
	Dialog.show();
	signalArray=newArray();
	chanArray = newArray();
	for(n=0;n<numChan;n++) {
		chanArray = Array.concat(chanArray,Dialog.getChoice());
		signal=Dialog.getString();
		signalArray = Array.concat(signalArray,signal);
		list=List.set((n+1), signal);
	}
//setting up and reordering your channels
	Dialog.create("Arrange Channels");
		oldchan = "Starting Channels\n";
		for(n=0;n<numChan;n++) {
			oldchan = oldchan+" "+(n+1)+" = "+chanArray[n]+" "+signalArray[n]+"\n";
		}		
		print(oldchan);

		Dialog.addMessage(oldchan);
		finArray = newArray();
		newchan = "New Channel Order\n";
		Dialog.addMessage(newchan);
			for(n=0;n<finChan;n++) {
						Dialog.setInsets(30, 0,0);
			Dialog.addNumber("Channel "+(n+1),(n+1),0,1,"");
}
			Dialog.show();
	c="";
	for(n=0;n<finChan;n++) {
		channum=Dialog.getNumber();
		finArray = Array.concat(finArray,channum);
		c=c+d2s(finArray[n],0);
		new=List.get(channum);
		newchan = newchan+" "+(n+1)+" = "+new+"\n";

	}
		print(newchan);

processFolder(input);
selectWindow("Log");
saveAs("Text", output+"Channel_Summary.csv");

// function to scan folders/subfolders/files to find files with correct suffix
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
//function macro
function processFile(input, output, file) {
//bioformats will automatically revert to previous settings, but you can include specific parameters here
		path = input + File.separator +filelist[i];
		run("Bio-Formats Windowless Importer", "open=[path]");
	//brackets needed because if the files have spaces in them, you will get an error
	rename(file);
	title=getTitle();
	selectWindow(title);
	run("Arrange Channels...", "new="+c);
	rename("close_me");
	if(ztack == "AVG") {
		run("Z Project...", "projection=[Average Intensity]");
		selectWindow("close_me");
		close();
	}
	if(ztack == "MAX") {
		run("Z Project...", "projection=[Max Intensity]");
		selectWindow("close_me");
		close();
	}
	if(ztack == "MIN") {
		run("Z Project...", "projection=[Min Intensity]");
		selectWindow("close_me");
		close();
	}
	if(ztack == "SUM") {
		run("Z Project...", "projection=[Sum Slices]");
		selectWindow("close_me");
		close();
	}
	if(ztack == "SD") {
		run("Z Project...", "projection=[Standard Deviation]");
		selectWindow("close_me");
		close();
	}
	if(ztack == "MED") {
		run("Z Project...", "projection=[Median Intensity]");
		selectWindow("close_me");
		close();
	}
	if(ztack == "") {
		selectWindow("close_me");
		rename(ztack+"_close_me");
	}
	projection = ztack+"_close_me";
	selectImage(projection);
	Stack.getDimensions(width, height, nochannels, slices, frames);
	for(s=0;s<nochannels;s++) {
		setSlice(s+1);
		resetMinAndMax();
	}
	selectImage(projection);
	rename(title);
	title = getTitle();
	dotIndex = indexOf(title, suffix );
	name= substring(title, 0, dotIndex);
	if (flat == "yes") {
		run("Stack to RGB", "slices");
		if(slices==1){
			selectImage(title +" (RGB)");
		}
		else {
			selectImage(title);
		}
		saveAs("Tiff",output+name+" "+ztack);
		close();
		if(slices==1){
			selectImage(title);
			close();
		}
	} else {
		saveAs("Tiff", output + name+" "+ztack);
		close();
	}
}