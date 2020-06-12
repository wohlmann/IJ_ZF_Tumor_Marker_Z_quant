	dir1 = getDirectory("Please choose source directory ");
	list1 = getFileList(dir1);
	dir2 = getDirectory("_Please choose destination directory ");
	QC=false;
	batch=false;
	Dialog.create("Analysis options");
	Dialog.addChoice("tumor: ", newArray("C1-", "C2-", "C3-", "C4-", "C5-", "C6-", "not used"),"C1-");
	Dialog.addChoice("marker: ", newArray("C1-", "C2-", "C3-", "C4-", "C5-", "C6-", "not used"),"C2-");
	Dialog.addChoice("DAPI: ", newArray("C1-", "C2-", "C3-", "C4-", "C5-", "C6-", "not used"),"C3-");
	Dialog.addCheckbox("use batch mode ", true);
	Dialog.addCheckbox("remove speckles", false);
//	Dialog.addCheckbox("Save QC images", false);
//	Dialog.addString("name output file: ", "");
	Dialog.show();
	tum=Dialog.getChoice();
	mark=Dialog.getChoice();
	DAP=Dialog.getChoice();
	batch = Dialog.getCheckbox();
	french = Dialog.getCheckbox();
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
	//reset counters
//	N=0;
	//make output dirs / check for write permission (generated dir exists):
	print("Writing output directories:");
	singledir = dir2 + "single_files" + File.separator;
	Resdir = dir2 + "Data" + File.separator;
	QCdir = dir2 + "Qualitycontrol" + File.separator;
	CACHE = dir2 + "CACHE" + File.separator;
	print(singledir);
	File.makeDirectory(singledir);
	if (!File.exists(singledir))
		exit("Unable to create directory - check permissions");
	print(Resdir);
	File.makeDirectory(Resdir);
	if (!File.exists(Resdir))
		exit("Unable to create directory - check permissions");
	if(QC == true){
		print(QCdir);
		File.makeDirectory(QCdir);
			if (!File.exists(QCdir))
				exit("Unable to create directory - check permissions");
	}
	if (batch==true){
		setBatchMode(true);
		print("running in batch mode");
		print("_");
	}
	//extract singlefiles *.tif
	for (j=0; j<list1.length; j++) {
		path1 = dir1+list1[j];
		print("start processing of "+path1+"");
		print("_");
		print("exporting images:");
		run("Bio-Formats Importer", "open=[path1] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT open_all_series");
		selectImage(nImages-nImages+1);
		titleS= getTitle;
		print("converting image:"+titleS+"");
		saveAs("tif", singledir+titleS+".tif");
		close();
	}
	wait(1000);
	list = getFileList(singledir);
	for (i=0; i<list.length; i++) {
		roiManager("reset");
		path = singledir+list[i];
		run("Bio-Formats Windowless Importer", "open=[path]autoscale color_mode=Default view=[Standard ImageJ] stack_order=Default");
		title1= getTitle;
		title2 = File.nameWithoutExtension;
		print("analysing image "+title1+":");
		run("Split Channels");
		selectWindow(""+DAP+""+title1+"");
		close();
		selectWindow(""+tum+""+title1+"");
		setAutoThreshold("Otsu dark");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Otsu background=Dark calculate black");
		run("Analyze Particles...", "size=1000-Infinity add stack");
		selectWindow(""+mark+""+title1+"");
		roiManager("Measure");
		print("saving results to "+Resdir+v+".xls");
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
