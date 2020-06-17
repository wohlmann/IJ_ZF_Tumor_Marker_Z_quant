macro "3D affinity marker quantification on xenocraft tumors in zebrafish" {
	setOption("ExpandableArrays", true);
	dir1 = getDirectory("Please choose source directory ");
	list1 = getFileList(dir1);
	dir2 = getDirectory("_Please choose destination directory ");
//	QC=false;
	batch=false;
	Dialog.create("Analysis options");
	Dialog.addChoice("tumor: ", newArray("C1-", "C2-", "C3-", "C4-", "C5-", "C6-", "not used"),"C1-");
	Dialog.addChoice("marker: ", newArray("C1-", "C2-", "C3-", "C4-", "C5-", "C6-", "not used"),"C2-");
	Dialog.addChoice("DAPI: ", newArray("C1-", "C2-", "C3-", "C4-", "C5-", "C6-", "not used"),"C3-");
	Dialog.addChoice("Tumor Thresholding Method: ", newArray("Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"), "Otsu");
//	Dialog.addChoice("Dataset: ", newArray("PARP", "PCNA"),"PARP");
	Dialog.addCheckbox("use batch mode ", false);
	Dialog.addCheckbox("remove all speckles", false);
	Dialog.addCheckbox("remove only ROI speckles", true);
	Dialog.addChoice("Speckle Thresholding Method: ", newArray("Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"), "Triangle");
	Dialog.addSlider("specle size", 1, 300, 30);
	Dialog.addSlider("specle enlargement", 1, 50, 1);
	Dialog.addCheckbox("remove unfocused slices", true);
	Dialog.addCheckbox("manually check cell selection", false);
//	Dialog.addCheckbox("Save QC images", false);
//	Dialog.addString("name output file: ", "");
	Dialog.show();
	tum = Dialog.getChoice();
	mark = Dialog.getChoice();
	DAP = Dialog.getChoice();
	TRm = Dialog.getChoice();								
//	Dat=Dialog.getChoice();
	batch = Dialog.getCheckbox();
	defrench = Dialog.getCheckbox();
	specROI = Dialog.getCheckbox();
	specS = Dialog.getNumber();
	specENL = Dialog.getNumber();
	deitaly	= Dialog.getCheckbox();
	mROI = Dialog.getCheckbox();
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
	if(mROI==true){
		print("using manual cell selection");
	}
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
	print("_");
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
			si = slices;
			s = 1;
			sn = 0;
			while (s <= slices) {
			setSlice(s);
			getRawStatistics(nPixels, mean, min, max, std, histogram);
//			print("slice "+s+" std= "+std+"");
			if (std <= 28.5) {								//18.5 works well for parp - alternative for PCNA??
//				waitForUser("isdel as std= "+std+"");
				sn++;
				print("deleting slice "+sn+s-1+"");
				run("Delete Slice");
				selectWindow(""+mark+""+title1+"");
				Stack.getDimensions(width, height, channels, slices, frames);
				wait(100);
				setSlice(s);
				run("Delete Slice");
				selectWindow(""+tum+""+title1+"");
				Stack.getDimensions(width, height, channels, slices, frames);
//				s = s - 1;
				s--;
				slices = slices;
			    }else {
//			    	waitForUser("nodel as std= "+std+"");
//					print("nodel");	
			    }
			s++;
			}
//			print("_");
			print("deleted "+sn+" out of "+si+" focus slices"); 
//			print("deleted slices are: "+dsA+"");  					//output as array if needed
		}
		if(defrench==true){
			print("removing specles");
			setOption("BlackBackground", true);
			selectWindow(""+mark+""+title1+"");
			run("Enhance Contrast", "saturated=0.35");
			run("Duplicate...", "duplicate");
			titleD= getTitle;
			selectWindow(titleD);
			wait(500);
//			run("Convert to Mask", "method=MaxEntropy background=Dark calculate black"); //WORKS FOR PARP
			run("Convert to Mask", ""+specROI+" background=Dark calculate black");
			run("Analyze Particles...", "size=0.5-"+specS+" include add stack");
			selectWindow(""+mark+""+title1+"");
			wait(500);
			ROIc = roiManager("count");
			spec=ROIc;
			if (ROIc!=0) {
				while (ROIc!=0) {
					roiManager("Show None");
					roiManager("select", 0);
					run("Enlarge...", "enlarge="+specENL+"");
					run("Clear", "slice");
					roiManager("select", 0);
					roiManager("delete");
					ROIc = roiManager("count");
				}
				//second round with different tresholding???
			}
			roiManager("reset");
			print("deleted "+spec+" specles");
			waitForUser("despecling done");
		}
//		if(Dat=="PARP"){
			run("Set Measurements...", "area mean integrated redirect=None decimal=1");
			selectWindow(""+tum+""+title1+"");
			run("Duplicate...", "duplicate");
			roiManager("reset");
			setOption("BlackBackground", true);
			run("Convert to Mask", "method="+TRm+" background=Dark calculate black");
			run("Analyze Particles...", "size=100.00-infinity add stack");
			selectWindow(""+tum+""+title1+"");
			run("Enhance Contrast", "saturated=0.35");
//			waitForUser("ROI ok?");
			if(mROI==true){
				delROI=0;
				aROI=nROI = parseInt(roiManager("count"));
				print("detected "+nROI+" tumor areas");
				for (i=0; i<nROI; i++) {
					roiManager("deselect");
					roiManager("Show None");
					roiManager("Select", i);
					delR = getBoolean("Use selection for analysis?", "Yes [Y-button]", "No, delete [N-button]");
						if(delR==false){
							roiManager("delete");
							delROI++;
							nROI = (roiManager("count"));
							i--;
						}
				}
				print("manual selection: using "+aROI-delROI+" out of "+aROI+" tumor areas for analysis");
			}
			//combine rois of same slice
			comROI = (roiManager("count"));
			same = newArray(0);
			ist1=1;
			slen=0;
			for (i=0; i<comROI; i++) {
//				print("start");
//				Array.print(same);
//				print("slen="+slen+"");
				roiManager("deselect");
				roiManager("Show None");
				roiManager("Select", i);
				ist=parseInt(substring(Roi.getName, 1, 4));
//				print("ist= "+ist+" =? "+ist1+"");
				if(ist==ist1){
					same[i]=parseInt(i);
					slen=same.length;
//					print("assign");
//					Array.print(same);
//					print("slen="+slen+"");
				}
				else if ((ist!=ist1)&&(slen>=2)) {
					roiManager("select", same);
					roiManager("combine"); 
					roiManager("Add");
					roiManager("deselect");
					roiManager("select", same);
					roiManager("delete");
					roiManager("deselect");
					i=0;
					same = newArray(0);
					same[0]=0;
					slen=same.length;
//					print("after fuse");
//					Array.print(same);
//					print("slen="+slen+"");
					ist1++;
					comROI = (roiManager("count"));
				}
				else if((ist>ist1)&&(slen<2)){
					roiManager("select", 0);
					roiManager("Add");
					roiManager("deselect");
					roiManager("select", 0);
					roiManager("delete");
					roiManager("deselect");
					i=0;
					ist1++;
					same = newArray(0);
					same[0]=0;
					slen=same.length;
//					Array.print(same);
//					print("slen="+slen+"");
				}
			}
			roiManager("deselect");
			roiManager("Show None");	
			selectWindow(""+mark+""+title1+"");
			if(specROI==true){
				despecROI=0;
				despecaROI=tumROI = parseInt(roiManager("count"));
//				waitForUser("start?");
				setOption("BlackBackground", true);
				selectWindow(""+mark+""+title1+"");
				run("Enhance Contrast", "saturated=0.35");
				run("Duplicate...", "duplicate");
				titleD= getTitle;
				selectWindow(titleD);
				print("deleting speckels in "+tumROI+" tumor areas");
				for (i=0; i<tumROI; i++) {
					roiManager("deselect");
					roiManager("Show None");
					roiManager("Select", i);
					run("Clear Outside", "slice");
					roiManager("deselect");
					roiManager("Show None");
				}
//				print("tumROI="+tumROI+"");
				selectWindow(titleD);
				run("Convert to Mask", ""+specROI+" background=Dark calculate black");
//				waitForUser("masked");
				run("Analyze Particles...", "size=0.5-"+specS+" include add stack");
				despecROI= parseInt(roiManager("count"));
//				print("despecROI="+despecROI+"");
					selectWindow(""+mark+""+title1+"");
//					wait(500);
					for (i = tumROI+1; i < despecROI; i++) {
						ROIco=(roiManager("count"));
						while(i<ROIco){
							roiManager("Show None");
							roiManager("select", i);
							run("Enlarge...", "enlarge="+specENL+"");
							run("Clear", "slice");
							roiManager("select", i);
							roiManager("delete");
							ROIco=(roiManager("count"));
						}
//						despecROI--;
					}
//					waitForUser("check ROIS");
						//second round with different tresholding???			
					//delR = getBoolean("Use selection for analysis?", "Yes [Y-button]", "No, delete [N-button]");
					//	if(delR==false){
					//		roiManager("delete");
					//		delROI++;
					//		despecnROI = (roiManager("count"));
					//		i--;
					//	}
				//}
				print("deleted "+despecROI+" specles in "+tumROI+" areas");
			}
			roiManager("Select", newArray());
			run("Enhance Contrast", "saturated=0.35");
			roiManager("Measure");
			roiManager("Show None");
			roiManager("Show All");
//			waitForUser("Measured");
//		}else if (Dat=="PCNA"){
//		//alternative tresholding?
//		}
		print("saving results to "+Resdir+title1+".txt");
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
		roiManager("reset");
	}
}