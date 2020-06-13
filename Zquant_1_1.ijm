macro "3D affinity marker quantification on xenocraft tumors in zebrafish" {
	dir1 = getDirectory("Please choose source directory ");
	list1 = getFileList(dir1);
	dir2 = getDirectory("_Please choose destination directory ");
//	QC=false;
	batch=false;
	Dialog.create("Analysis options");
	Dialog.addChoice("tumor: ", newArray("C1-", "C2-", "C3-", "C4-", "C5-", "C6-", "not used"),"C1-");
	Dialog.addChoice("marker: ", newArray("C1-", "C2-", "C3-", "C4-", "C5-", "C6-", "not used"),"C2-");
	Dialog.addChoice("DAPI: ", newArray("C1-", "C2-", "C3-", "C4-", "C5-", "C6-", "not used"),"C3-");
	Dialog.addChoice("Dataset: ", newArray("PARP", "PCNA"),"PARP");
	Dialog.addCheckbox("use batch mode ", false);
	Dialog.addCheckbox("remove speckles", false);
	Dialog.addCheckbox("remove unfocused slices", false);
//	Dialog.addCheckbox("Save QC images", false);
//	Dialog.addString("name output file: ", "");
	Dialog.show();
	tum=Dialog.getChoice();
	mark=Dialog.getChoice();
	DAP=Dialog.getChoice();
	Dat=Dialog.getChoice();
	batch = Dialog.getCheckbox();
	defrench = Dialog.getCheckbox();
	deitaly	= Dialog.getCheckbox();
//	QC = Dialog.getCheckbox();
//	v=Dialog.getString();
	//reset system:
	run("Close All");
	print("\\Clear");
	print("Reset: log, Results, ROI Manager");
	run("Clear Results");
	updateResults;
	roiManager("reset");
	setOption("BlackBackground", true);
  	setBackgroundColor(0,0,0);
  	setForegroundColor(255,255,255);
	while (nImages>0) {
		selectImage(nImages);
		close();
	}
	print("_");
	getDateAndTime(year, month, week, day, hour, min, sec, msec);
	print("Starting analysis at: "+day+"/"+month+"/"+year+" :: "+hour+":"+min+":"+sec+"");
	print("_");
	//make output dirs / check for write permission (generated dir exists):

	print("Writing output directory:");
//	singledir = dir2 + "single_files" + File.separator;
	Resdir = dir2 + "Data" + File.separator;
//	QCdir = dir2 + "Qualitycontrol" + File.separator;
	print(Resdir);
	File.makeDirectory(Resdir);
	if (!File.exists(Resdir))
		exit("Unable to create directory - check permissions");
//	if(QC == true){
//		print(QCdir);
//		File.makeDirectory(QCdir);
//			if (!File.exists(QCdir))
//				exit("Unable to create directory - check permissions");
//	}
	if (batch==true){
		setBatchMode(true);
		print("running in batch mode");
		print("_");
	}
	list=list1;
	for (i=0; i<list.length; i++) {
		roiManager("reset");
		path1 = dir1+list1[i];
		run("Bio-Formats Importer", "open=[path1] color_mode=Default view=Hyperstack stack_order=XYCZT series_1");
		title1= getTitle;
		title2 = File.nameWithoutExtension;
		print("analysing image "+title1+":");
		run("Split Channels");
		selectWindow(""+DAP+""+title1+"");
		close();
		if(deitaly==true){
			print("removing out of focus slices");
			selectWindow(""+tum+""+title1+"");
			run("Enhance Contrast", "saturated=0.35");
			Stack.getDimensions(width, height, channels, slices, frames);
			s = 1;
			while (s <= slices) {
			setSlice(s);
			getRawStatistics(nPixels, mean, min, max, std, histogram);
			print("slice "+s+" std= "+std+"");
			if (std <= 18.5) {
			//	waitForUser("isdel");
				print("del");
				run("Delete Slice");
				selectWindow(""+mark+""+title1+"");
				Stack.getDimensions(width, height, channels, slices, frames);
				setSlice(s);
				run("Delete Slice");
				s = s - 1;
				selectWindow(""+tum+""+title1+"");
				Stack.getDimensions(width, height, channels, slices, frames);
			    }else {
			    	//waitForUser("nodel as std= "+std+"");
					print("nodel");	
			    }
			s++;
			}
		}
		if(defrench==true){
			selectWindow(""+mark+""+title1+"");
			setOption("BlackBackground", true);
			run("Convert to Mask", "method=MaxEntropy background=Dark calculate black");
			run("Analyze Particles...", "size=0-4 add stack");
			ROIc = roiManager("count");
			if (ROIc!=0) {
				while (ROIc!=0) {
					roiManager("select", 0);
					run("Enhance Contrast", "saturated=0.35");
					run("Clear", "slice");
					roiManager("select", 0);
					roiManager("delete");
					ROIc = roiManager("count");
				}
			}
			roiManager("reset");
		}
		if(Dat=="PARP"){
			selectWindow(""+tum+""+title1+"");
			setOption("BlackBackground", true);
			run("Convert to Mask", "method=Otsu background=Dark calculate black");
			run("Analyze Particles...", "size=100.00-infinity add stack");
			run("Enhance Contrast", "saturated=0.35");
//			waitForUser("ROI ok?");
			selectWindow(""+mark+""+title1+"");
			roiManager("Select", newArray());
			run("Enhance Contrast", "saturated=0.35");
			roiManager("Measure");
			roiManager("Show None");
			roiManager("Show All");
			waitForUser("Measured");
		}else if (Dat=="PCNA"){
		////////////////////////////////////////////////////////	
		}
		print("saving results to "+Resdir+title1+".xls");
		selectWindow("Results");
		saveAs("txt", Resdir+title1+".xls");
		print("_");
		run("Close All");
		run("Clear Results");
		updateResults;
		while (nImages>0) {
		selectImage(nImages);
		close();
		}
	}
}