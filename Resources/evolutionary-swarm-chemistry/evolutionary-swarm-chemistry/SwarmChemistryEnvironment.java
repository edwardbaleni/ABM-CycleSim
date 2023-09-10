// SwarmChemistryEnvironment.java
//
// 2006-2015 (c) Copyright by Hiroki Sayama
//
// This file is part of "Evolutionary Swarm Chemistry Simulator",
// which is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// any later version.
//
// "Evolutionary Swarm Chemistry Simulator" is distributed in the hope
// that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE.  See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with "Evolutionary Swarm Chemistry Simulator".  If not, see
// <http://www.gnu.org/licenses/>.
//
// Send any correspondences to:
//   Hiroki Sayama, D.Sc.
//   Director, Center for Collective Dynamics of Complex Systems
//   Associate Professor, Department of Systems Science and Industrial Engineering
//   Binghamton University, State University of New York
//   P.O. Box 6000, Binghamton, NY 13902-6000, USA
//   Tel: +1-607-777-3566
//   Email: sayama@binghamton.edu
//
// For more information about this software, see:
//   http://bingweb.binghamton.edu/~sayama/SwarmChemistry/


import java.awt.*;
import java.util.*;
import java.awt.event.*;


public class SwarmChemistryEnvironment implements ActionListener {
    Frame controlFrame;
    Dimension screenDimension, controlFrameDimension, simulatorDimension;
    Insets screenInsets, controlFrameInsets;
    int numberOfFrames, showroomW, showroomH, defaultFrameSize;
    int initialSpaceSize = 2000;
    TextField numberOfFramesText;
    Checkbox tracking, pausing, mutation, mouseEffect;
    Button undoing, resetting, showing, quitting;
    int maxFrames = 1;

    boolean resettingRequest, numberOfFramesChangeRequest;
    boolean applicationRunning;
    boolean thisIsApplet;

    int numberOfSeeds;
    boolean givenWithSpecificRecipe;
    String givenRecipeText;

    SwarmPopulation[] populations;
    SwarmPopulationSimulator[] sample;
    SwarmPopulationSimulator[] selectedSample = new SwarmPopulationSimulator[2];
    java.util.List<RecipeFrame> recipeFrames;

    long previousTime, currentTime;
    long milliSecPerFrame = 70;

    double populationChangeMagnitude = 0.8;
    double duplicationOrDeletionRatePerParameterSets = 0.1;
    double randomAdditionRatePerRecipe = 0.1;
    double pointMutationRatePerParameter = 0.1;
    double pointMutationMagnitude = 0.5;

    String initcond;

    public SwarmChemistryEnvironment(boolean app, String recipeText) {
	this(app, 1, true, recipeText);
    }

    public SwarmChemistryEnvironment(boolean app, int num) {
	this(app, num, false, "");
    }

    public SwarmChemistryEnvironment(boolean app, int num, boolean given, String recipeText) {
	int howManySelected;

	//*** added 11/10/2010 ***

	int steadyEnvironmentLength = 1950;
	int perturbationLength = 50;
	boolean isUnderPerturbation = false;
	int elapsedTime = 0;
	String compfunc = "majority-relative";

	//*** end addition ***

	if (given) initcond = "designed";
	else initcond = "random";

	thisIsApplet = app;
	recipeFrames = Collections.synchronizedList(new ArrayList<RecipeFrame>());

	numberOfFrames = 1; //num;
	numberOfSeeds = num;
	givenWithSpecificRecipe = given;
	givenRecipeText = recipeText;

	constructControlFrame();
	determineFrameArrangement();
	createPopulations();

	applicationRunning = true;

	while (applicationRunning) {

	    int timestep = 0;
	    int endtime = 30000;
	    int imageoutputinterval = 10;

	    // Simulating the current generation

	    createFrames();

	    howManySelected = 0;
	    resettingRequest = numberOfFramesChangeRequest = false;

	    //previousTime = System.currentTimeMillis();

	    while (howManySelected < 2 &&
		   !resettingRequest &&
		   !numberOfFramesChangeRequest) {

		//currentTime = System.currentTimeMillis();
		//		if (currentTime - previousTime > milliSecPerFrame)
		//		    previousTime = currentTime;
		for (int i = 0; i < numberOfFrames; i ++) {
		    if (sample[i].isDisplayable()) {
			//if (currentTime == previousTime) {
			    if (!pausing.getState()) {
				sample[i].simulateSwarmBehavior(compfunc);
				sample[i].updateStates();
			    }
			    timestep ++;
			    if (timestep % imageoutputinterval == 0) {
				sample[i].displayStates();
				sample[i].saveImage(initcond, timestep);
				//				System.out.println(timestep);
			    }
			    if (timestep >= endtime) {
				//System.out.println("Simulation finished");
				System.exit(0);
			    }

			    //*** added 11/10/2010 ***

			    elapsedTime ++;

			    if (isUnderPerturbation) {
				if (elapsedTime >= perturbationLength) {
				    isUnderPerturbation = false;
				    elapsedTime = 0;
				    compfunc = "majority-relative";
				}
			    }

			    else {
				if (elapsedTime >= steadyEnvironmentLength) {
				    isUnderPerturbation = true;
				    elapsedTime = 0;
				    double r = Math.random();
				    if (r < 0.25) compfunc = "leftfaster";
				    else if (r < 0.5) compfunc = "rightfaster";
				    else if (r < 0.75) compfunc = "leftslower";
				    else compfunc = "rightslower";
				}
			    }

			    //*** end addition ***

			    //			}
			if (sample[i].isSelected && sample[i].notYetNoticed) {
			    sample[i].notYetNoticed = false;
			    selectedSample[howManySelected] = sample[i];
			    howManySelected ++;
			}
			else if (!sample[i].isSelected && !sample[i].notYetNoticed) {
			    sample[i].notYetNoticed = true;
			    howManySelected --;
			}
		    }
		    else {
			if (sample[i].isSelected && !sample[i].notYetNoticed) {
			    sample[i].isSelected = false;
			    sample[i].notYetNoticed = true;
			    howManySelected --;
			}
		    }
		}
	    }

	    disposeFrames();

	    // Creating the next generation

	    if (resettingRequest) createPopulations();

	    else if (numberOfFramesChangeRequest) {
		int n = Integer.parseInt(numberOfFramesText.getText());

		SwarmPopulation[] newPopulations = new SwarmPopulation[n];
		for (int i = 0; i < n; i ++) {
		    if (i < numberOfFrames) newPopulations[i] = populations[i];
		    else newPopulations[i] = new SwarmPopulation((int) (Math.random() * SwarmParameters.numberOfIndividualsMax) + 1, "Randomly generated");
		}
		numberOfFrames = n;
		populations = newPopulations;
		determineFrameArrangement();
	    }

	    else for (int i = 0; i < numberOfFrames; i ++) {

		if (i == 0)
		    populations[i] = new SwarmPopulation(selectedSample[0].population, "Previously selected");
		
		else if (i == 1 && selectedSample[0] != selectedSample[1])
		    populations[i] = new SwarmPopulation(selectedSample[1].population, "Previously selected");

		else if (i == numberOfFrames - 1 && numberOfFrames > 3) {
		    populations[i] = new SwarmPopulation((int) (Math.random() * SwarmParameters.numberOfIndividualsMax) + 1, "Randomly generated");
		}

		else {
		    if (selectedSample[0] == selectedSample[1]) {

			// Population perturbation

			populations[i] = new SwarmPopulation(selectedSample[0].population, "Perturbed");
			populations[i].perturb(populationChangeMagnitude, initialSpaceSize);
		    }

		    else {

			// Physical mixing

			populations[i] = new SwarmPopulation(selectedSample[0].population, selectedSample[1].population, Math.random() * 0.6 + 0.2, "Mixed");
		    }

		    if (mutation.getState()) {
			boolean mutated = false;

			// Obtain a recipe from population

			Recipe tempRecipe = new Recipe(populations[i].population);
			int numberOfIngredients = tempRecipe.parameters.size();

			// Insertions, duplications and deletions

			for (int j = 0; j < numberOfIngredients; j ++) {
			    if (Math.random() < duplicationOrDeletionRatePerParameterSets) {
				if (Math.random() < .5) { // Duplication
				    mutated = true;
				    tempRecipe.parameters.add(j + 1, tempRecipe.parameters.get(j));
				    tempRecipe.popCounts.add(j + 1, tempRecipe.popCounts.get(j));
				    numberOfIngredients ++;
				    j ++;
				}
				else { // Deletion
				    if (numberOfIngredients > 1) {
					mutated = true;
					tempRecipe.parameters.remove(j);
					tempRecipe.popCounts.remove(j);
					numberOfIngredients --;
					j --;
				    }
				}
			    }
			}

			if (Math.random() < randomAdditionRatePerRecipe) { // Addition
			    mutated = true;
			    tempRecipe.parameters.add(new SwarmParameters());
			    tempRecipe.popCounts.add(new Integer((int) (Math.random() * SwarmParameters.numberOfIndividualsMax * 0.5) + 1));
			}

			// Then Point Mutations

			SwarmParameters tempParam;

			for (int j = 0; j < numberOfIngredients; j ++) {
			    tempParam = new SwarmParameters(tempRecipe.parameters.get(j));
			    tempParam.inducePointMutations(
							   pointMutationRatePerParameter,
							   pointMutationMagnitude
							   );
			    if (!tempRecipe.parameters.get(j).equals(tempParam)) {
				mutated = true;
				tempRecipe.parameters.set(j, tempParam);
			    }
			}

			tempRecipe.boundPopulationSize();
			populations[i].population = tempRecipe.createPopulation(defaultFrameSize, defaultFrameSize);

			// Check if mutation happened

			if (mutated) {
			    populations[i].title = populations[i].title + " & mutated";
			}
		    }
		}
	    }
	}
    }

    public void constructControlFrame() {
	controlFrame = new Frame("Swarm Chemistry Simulator");
	controlFrame.setVisible(true);
	controlFrame.setBackground(Color.white);
	controlFrame.addWindowListener(new WindowAdapter() {
		public void windowClosing(WindowEvent e) {
		    if (thisIsApplet) {
			for (int i = 0; i < numberOfFrames; i ++) {
			    sample[i].dispose();
			    sample[i] = null;
			}
			for (int i = 0; i < recipeFrames.size(); i ++)
			    recipeFrames.get(i).dispose();
			recipeFrames.clear();
			controlFrame.dispose();
			applicationRunning = false;
			System.gc();
		    }
		    else System.exit(0);
		}
	    });

	controlFrame.setLayout(new FlowLayout());
	controlFrame.add(new Label("# of frames:"));
	controlFrame.add(numberOfFramesText = new TextField(Integer.toString(numberOfFrames)));
	controlFrame.add(new Label(" "));
	numberOfFramesText.addActionListener(this);
	controlFrame.add(tracking = new Checkbox("Automatic zoom", false));
	controlFrame.add(pausing = new Checkbox("Pause", false));
	controlFrame.add(mutation = new Checkbox("Mutation", false));
	controlFrame.add(mouseEffect = new Checkbox("Interaction w. mouse cursor", false));
	controlFrame.add(undoing = new Button("Undo selection"));
	undoing.addActionListener(this);
	controlFrame.add(resetting = new Button("Randomize all swarms"));
	resetting.addActionListener(this);
	controlFrame.add(showing = new Button("Bring all windows to front"));
	showing.addActionListener(this);
	controlFrame.add(quitting = new Button("Quit"));
	quitting.addActionListener(this);

	screenDimension = controlFrame.getToolkit().getScreenSize();
	screenInsets = controlFrame.getToolkit().getScreenInsets(controlFrame.getGraphicsConfiguration());
	controlFrameInsets = controlFrame.getInsets();
	controlFrame.setSize(screenDimension.width, 40 + controlFrameInsets.top + controlFrameInsets.bottom);
	controlFrame.setLocation(0, screenInsets.top);
	controlFrame.setVisible(true);
	controlFrameDimension = controlFrame.getSize();
    }

    public void determineFrameArrangement() {
	/*
	int screenW, screenH, estimatedFrameSize;

	screenW = screenDimension.width - screenInsets.left - screenInsets.right;
	screenH = screenDimension.height - screenInsets.top - screenInsets.bottom - controlFrameDimension.height;

	defaultFrameSize = 1;
	for (showroomH = 1; showroomH <= maxFrames; showroomH ++) {
	    showroomW = (int) Math.ceil((double) numberOfFrames / (double) showroomH);
	    estimatedFrameSize = Math.min(screenW / showroomW - controlFrameInsets.left - controlFrameInsets.right, screenH / showroomH - controlFrameInsets.top - controlFrameInsets.bottom);
	    if (defaultFrameSize > estimatedFrameSize) {
		showroomH --;
		showroomW = (int) Math.ceil((double) numberOfFrames / (double) showroomH);		break;
	    }
	    else defaultFrameSize = estimatedFrameSize;
	}
	*/
	showroomH = showroomW = 1;
	defaultFrameSize = 400;
    }

    public void createPopulations() {
	populations = new SwarmPopulation[numberOfFrames];
	for (int i = 0; i < numberOfFrames; i ++) {
	    if (givenWithSpecificRecipe) {
		givenWithSpecificRecipe = false;
		populations[i] = new SwarmPopulation(givenRecipeText, "Created from a given recipe"); // revised!!
	    }
	    else {
		populations[i] = new SwarmPopulation(numberOfSeeds, "Randomly generated");
	    }
	}
    }

    public void createFrames() {
	sample = new SwarmPopulationSimulator[numberOfFrames];

	for (int i = 0; i < numberOfFrames; i ++) {
	    int x = i % showroomW;
	    int y = (i - x) / showroomW;
	    sample[i] = new SwarmPopulationSimulator(defaultFrameSize, initialSpaceSize, populations[i], populations, i, tracking, mouseEffect, recipeFrames);
	    simulatorDimension = sample[i].getSize();
	    sample[i].setLocation(simulatorDimension.width * x + (screenDimension.width - screenInsets.left - screenInsets.right - simulatorDimension.width * showroomW) / 2, simulatorDimension.height * y + screenInsets.top + controlFrameDimension.height);
	}
    }

    public void disposeFrames() {
	for (int i = 0; i < numberOfFrames; i ++) {
	    if (sample[i].displayedRecipe != null) {
		sample[i].displayedRecipe.orphanize();
	    }
	    sample[i].dispose();
	}
    }

    public void actionPerformed(ActionEvent e) {
	if (e.getSource() == numberOfFramesText) {
	    int n;
	    try {
		n = Integer.parseInt(numberOfFramesText.getText());
	    }
	    catch(NumberFormatException nfe) {
		n = numberOfFrames;
	    }
	    if (n < 1) n = 1;
	    else if (n > maxFrames) n = maxFrames;
	    numberOfFramesText.setText(Integer.toString(n));

	    if (n != numberOfFrames) {
		numberOfFramesChangeRequest = true;
	    }
	}

	else if (e.getSource() == undoing) {
	    for (int i = 0; i < numberOfFrames; i ++)
		sample[i].isSelected = false;
	}

	else if (e.getSource() == resetting) {
	    resettingRequest = true;
	}

	else if (e.getSource() == showing) {
	    for (int i = 0; i < numberOfFrames; i ++) {
		if (sample[i].isDisplayable()) {
		    sample[i].setState(Frame.NORMAL);
		    sample[i].toFront();
		}
	    }

	    RecipeFrame rcf;
	    for (int i = 0; i < recipeFrames.size(); i ++) {
		rcf = recipeFrames.get(i);
		rcf.setState(Frame.NORMAL);
		rcf.toFront();
	    }
	    controlFrame.toFront();
	}

	else if (e.getSource() == quitting) {
	    if (thisIsApplet) {
		for (int i = 0; i < numberOfFrames; i ++) {
		    sample[i].dispose();
		    sample[i] = null;
		}
		for (int i = 0; i < recipeFrames.size(); i ++)
		    recipeFrames.get(i).dispose();
		recipeFrames.clear();
		controlFrame.dispose();
		applicationRunning = false;
		System.gc();
	    }
	    else System.exit(0);
	}
    }
}
