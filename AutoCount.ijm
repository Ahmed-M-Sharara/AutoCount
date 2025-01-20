/*
Primary purpose: Count the number of cells in each image
Created by Ahmed Sharara
Added to and revised by Casey Kraft

Need (before running this macro):
1. The to-be-analyzed fluorescent images in an accessible directory

Inputs:
1. Folder with to-be-analyzed images ("image series")

Parameters requiring one-time user optimization for entire image series:
1. Prominence value
2. Threshold min
3. Particle size min

Output:
1. Summary table with cell count in second column for entire image series
*/

waitForUser("Prepare Image Series Folder","BEFORE clicking \"OK\":\n1. Ensure the images you want to analyze (e.g. all your green channel images collected under similar conditions) are all in a folder that contains no other files.\n    The images in this folder are defined as the \"image series\".\n2. Ensure that this folder is named either \"blue\", \"green\", or \"red\" in correspondance with the channel color.\nNote: The first image alphabetically in this folder will be used for determining parameter values (rename as desired).\nIn the NEXT PROMPT, you will press \"Select\" on this folder.\nPress \"OK\" when this folder is ready."); 

  // Step 1: Obtain the first image and split it
  dirInput=getDirectory("Choose image series folder.");
  color=substring(dirInput,lengthOf(dirInput)-4,lengthOf(dirInput)-1);
  imagesList=getFileList(dirInput);
  nFiles=lengthOf(imagesList);
  open(dirInput+imagesList[0]);
  title0=getTitle();
  run("Split Channels");
  if(color=="een"){
    color="green";
    selectWindow(title0+" (blue)");
    run("Close");
    selectWindow(title0+" (red)");
    run("Close");
  } else {
    if(color=="red"){
      selectWindow(title0+" (blue)");
      run("Close");
      selectWindow(title0+" (green)");
      run("Close");
    } else {
      color="blue";
      selectWindow(title0+" (green)");
      run("Close");
      selectWindow(title0+" (red)");
      run("Close");
    }
  }
  title=getTitle();

  // Step 2: Enhance contrast of the image by 0.35%
  selectWindow(title);
  run("Enhance Contrast...", "saturated=0.35");

  // Step 3: Duplicate the image and rename duplicates
  run("Duplicate...", "title=Mask1");
  selectWindow(title);
  run("Duplicate...", "title=Mask2");

  // Step 4: Prompt user to define prominence for Find Maxima function
  waitForUser("One-Time User Optimization #1 of 3","BEFORE clicking \"OK\", you must determine the image series-specific prominence value in the Find Maxima function. To do so:\n1. Click \"Process\" then \"Find Maxima...\".\n2. Change \"Output type\" to \"Segmented Particles\".\n3. Keep the following unchecked: \"Strict\", \"Exclude edge maxima\", \"Light background\".\n4. Place check marks for the following: \"preview point selection\".\n5. Adjust prominence value (top number) with consultation to whichever image has crosshairs on it (each crosshair corresponds to 1 identified cell)\n    to achieve counting of all discernible cells while minimizing apparent overcounting (i.e. err on the side of a lower value).\n6. Once done, remember this number (and/or record it in a spreadsheet). You will enter it in the NEXT PROMPT.\n7. Click \"Cancel\" on the \"Find Maxima\" window and click \"OK\" on this window.");
  prominence=getNumber("Prominence value for this image series:", 20);

  // Step 5: Apply Find Maxima function with specified prominence on Mask1
  selectWindow("Mask1");
  run("Find Maxima...", "prominence="+prominence+" output=[Segmented Particles]");
  //run("Find Maxima...", "prominence="+prominence+" exclude output=[Segmented Particles]");//to exclude on edges
  selectWindow("Mask1");
  run("Close");

  // Step 6: Prompt user to edit threshold min value for Mask2
  waitForUser("One-Time User Optimization #2 of 3","BEFORE clicking \"OK\", you must determine the image series-specific min value in the Threshold function. To do so:\n1. Select Mask 2.\n2. Press Ctrl+Shift+T.\n3. Leave the following unchecked: \"Stack histogram\", \"Don't reset range\".\n4. Keep the following checked: \"Dark background\".\n5. Keep the following settings: \"255\" as the max value (second number from the top), \"Default\", \"Red\".\n6. Adjust the min value (top number) with consultation to Mask 2 to capture all cell area (given by a red color)\n    while minimizing inclusion of non-cell area (i.e. err on the side of a lower value).\n7. Once done, remember this number (and/or record it in a spreadsheet). You will enter it in the NEXT PROMPT.\n8. Click \"Reset\" on the \"Threshold\" window, exit out of the \"Threshold\" window, and click \"OK\" on this window.");
  minThresh=getNumber("Enter min value for Threshold function:", 20);

  // Step 7: Apply Threshold function with specified min on Mask2
  selectWindow("Mask2");
  //setAutoThreshold("Default dark"); //May be necessary to include a line like this to ensure "Dark background" is checked
  setThreshold(minThresh, 255);
  run("Convert to Mask");

  // Step 8: Use Image Calculator to combine Mask1 Segmented and Mask2 with AND function
  imageCalculator("AND create", "Mask1 Segmented","Mask2");
  selectWindow("Mask2");
  run("Close");
  selectWindow("Mask1 Segmented");
  run("Close");

  // Step 9: Count the combined image
  run("Set Measurements...", "limit display redirect=["+title+"] decimal=3");   
  //run("Set Measurements...", "area mean perimeter shape feret's integrated limit display redirect=["+title+"] decimal=3"); //if more info is desired
  titleCond=substring(title,0,indexOf(title,".tif"));
  selectWindow("Result of Mask1 Segmented");
  rename(titleCond+"_segmented");
  waitForUser("One-Time User Optimization #3 of 3","BEFORE clicking \"OK\", you must determine the image series-specific min particle size in the Analyze Particles function. To do so:\n1.  Click \"Analyze\", then \"Analyze Particles...\".\n     Note: You must first select the segmented image if this is not the active window.\n2.  Keep all unchecked.\n3.  Keep circularity as \"0.00-1.00\".\n4.  For \"Show\", select \"Outlines\".\n5.  Enter the min particle size (top number to the left of \"-Infinity\"). This number should be equal to the area (in um^2) of the smallest cell in this image.\n     Note: An estimate is acceptable (see Steps 8-9). \n6. Once done, remember this number (and/or record it in a spreadsheet). You may enter it in the NEXT PROMPT.\n7.  Click \"OK\".\n8.  Double-check that this parameter value is acceptable by comparing the pop-up image of outlines (each enclosure, i.e. \"outline\", in this image gives a counted cell) to a corresponding image of the cells.\n     To gauge undercounting, find the smallest-area cell and determine if this is being outlined.\n     To gauge overcounting, find the smallest-area outline and determine if this is a cell.\n     If there is an unacceptable level of undercounting/overcounting, exit out of the outlines window, return to Step 1, and in Step 5, input a lower min size for undercounting or a higher min size for overcounting.\n9.  Once done, remember this number (and/or record it in a spreadsheet). You will enter it in the NEXT PROMPT.\n     Note: you may manually SAVE this outlines window for your records.\n10. Exit out of the outlines window and click \"OK\" on this window.");
  minSize=getNumber("Enter min particle size for Analyze Particles function:", 200);
  selectWindow(titleCond+"_segmented");
  run("Analyze Particles...", "size="+minSize+"-Infinity show=Nothing summarize");
  //run("Analyze Particles...", "size="+minSize+"-Infinity show=Nothing exclude summarize"); //to exclude on edges
  //run("Analyze Particles...", "size="+minSize+"-Infinity show=Outlines display clear summarize"); //if more info is desired
  close("*");

  // Step 10: Repeat using same min and prominence values for all images in the series
  for(j=1; j<nFiles; j++){
    open(dirInput+imagesList[j]);
    title0=getTitle();
    run("Split Channels");
    if(color=="green"){
      selectWindow(title0+" (blue)");
      run("Close");
      selectWindow(title0+" (red)");
      run("Close");
    } else {
      if(color=="red"){
        selectWindow(title0+" (blue)");
        run("Close");
        selectWindow(title0+" (green)");
        run("Close");
      } else {
        selectWindow(title0+" (green)");
        run("Close");
        selectWindow(title0+" (red)");
        run("Close");
      }
    }
    title=getTitle();
    selectWindow(title);
    run("Enhance Contrast...", "saturated=0.35");
    run("Duplicate...", "title=Mask1");
    selectWindow(title);
    run("Duplicate...", "title=Mask2");
    selectWindow("Mask1");
    run("Find Maxima...", "prominence="+prominence+" output=[Segmented Particles]");
    //run("Find Maxima...", "prominence="+prominence+" exclude output=[Segmented Particles]");//to exclude on edges
    selectWindow("Mask1");
    run("Close");
    selectWindow("Mask2");
    //setAutoThreshold("Default dark"); //May be necessary to include a line like this to ensure "Dark background" is checked
    setThreshold(minThresh, 255);
    run("Convert to Mask");
    imageCalculator("AND create", "Mask1 Segmented","Mask2");
    selectWindow("Mask2");
    run("Close");
    selectWindow("Mask1 Segmented");
    run("Close");
    run("Set Measurements...", "limit display redirect=["+title+"] decimal=3"); 
    //run("Set Measurements...", "area mean perimeter shape feret's integrated limit display redirect=["+title+"] decimal=3"); //if more info is desired
    titleCond=substring(title,0,indexOf(title,".tif"));
    selectWindow("Result of Mask1 Segmented");
    rename(titleCond);
    run("Analyze Particles...", "size="+minSize+"-Infinity show=Nothing summarize");
    //run("Analyze Particles...", "size="+minSize+"-Infinity show=Nothing exclude summarize"); //to exclude on edges
    //run("Analyze Particles...", "size="+minSize+"-Infinity show=Outlines display clear summarize"); //if more info is desired
    close("*");
  }
waitForUser("The counting is finished for this image series. We recommend copying data from the \"Summary\" table and pasting into a spreadsheet.\nNote: if more info is desired (e.g. cell perimeter), the user is encouraged to modify the \"Set Measurements...\" and \"Analyze Particles...\" lines in the code.");
