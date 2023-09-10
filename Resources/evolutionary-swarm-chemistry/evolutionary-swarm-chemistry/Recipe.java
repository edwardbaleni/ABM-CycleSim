// Recipe.java
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

public class Recipe {

    ArrayList<SwarmParameters> parameters;
    ArrayList<Integer> popCounts;
    String recipeText;

    public double populationChangeMagnitude = 0.8;
    public double duplicationOrDeletionRatePerParameterSets = 0.1;
    public double randomAdditionRatePerRecipe = 0.5; //*** increased from 0.1 to 0.5 (11/7/2010)
    public double pointMutationRatePerParameter = 0.1;
    public double pointMutationMagnitude = 0.5;

    public Recipe(String text) {
	setFromText(text);
    }

    public Recipe(ArrayList<SwarmIndividual> sol) {
	setFromPopulation(sol);
    }

    public boolean setFromText(String text) {
	char ch;
	int numberOfIngredients, numberOfIndividuals;
	double neighborhoodRadius, normalSpeed, maxSpeed, c1, c2, c3, c4, c5;
	//,
	//	    minLocationDifference, maxLocationDifference,
	//	    minVelocityDifference, maxVelocityDifference;

	StringBuffer recipeProcessed = new StringBuffer(text.length());
	for (int i = 0; i < text.length(); i ++) {
	    ch = text.charAt(i);
	    if ((ch >= '0' && ch <= '9') || (ch == '.')) recipeProcessed.append(ch);
	    else if (recipeProcessed.length() > 0) {
		if (recipeProcessed.charAt(recipeProcessed.length() - 1) != ' ')
		    recipeProcessed.append(' ');
	    }
	}

	StringTokenizer st = new StringTokenizer(recipeProcessed.toString(), " ");

	if (st.countTokens() % 9 != 0) {
	    recipeText = "*** Formatting error ***\n" + text;
	    parameters = null;
	    popCounts = null;
	    return false;
	}

	numberOfIngredients = st.countTokens() / 9;
	if (numberOfIngredients == 0) {
	    recipeText = "*** No ingredients ***\n" + text;
	    parameters = null;
	    popCounts = null;
	    return false;
	}
	if (numberOfIngredients > SwarmParameters.numberOfIndividualsMax)
	    numberOfIngredients = SwarmParameters.numberOfIndividualsMax;

	parameters = new ArrayList<SwarmParameters>();
	popCounts = new ArrayList<Integer>();

	try {
	    for (int i = 0; i < numberOfIngredients; i ++) {
		numberOfIndividuals = Integer.parseInt(st.nextToken());
		if (numberOfIndividuals < 1) numberOfIndividuals = 1;
		st.nextToken(); st.nextToken(); st.nextToken(); st.nextToken();
		st.nextToken(); st.nextToken(); st.nextToken(); st.nextToken();
		//		st.nextToken(); st.nextToken(); st.nextToken(); st.nextToken();
	    }

	    st = new StringTokenizer(recipeProcessed.toString(), " ");

	    for (int i = 0; i < numberOfIngredients; i ++) {
		numberOfIndividuals = Integer.parseInt(st.nextToken());
		if (numberOfIndividuals < 1) numberOfIndividuals = 1;
		neighborhoodRadius = Double.parseDouble(st.nextToken());
		normalSpeed = Double.parseDouble(st.nextToken());
		maxSpeed = Double.parseDouble(st.nextToken());
		c1 = Double.parseDouble(st.nextToken());
		c2 = Double.parseDouble(st.nextToken());
		c3 = Double.parseDouble(st.nextToken());
		c4 = Double.parseDouble(st.nextToken());
		c5 = Double.parseDouble(st.nextToken());
		//		minLocationDifference = Double.parseDouble(st.nextToken());
		//		maxLocationDifference = Double.parseDouble(st.nextToken());
		//		minVelocityDifference = Double.parseDouble(st.nextToken());
		//		maxVelocityDifference = Double.parseDouble(st.nextToken());
		parameters.add(new SwarmParameters(neighborhoodRadius, normalSpeed, maxSpeed, c1, c2, c3, c4, c5)); //, minLocationDifference, maxLocationDifference, minVelocityDifference, maxVelocityDifference));
		popCounts.add(new Integer(numberOfIndividuals));
	    }
	} catch (NumberFormatException nfe) {
	    recipeText = "*** Formatting error ***\n" + text;
	    parameters = null;
	    popCounts = null;
	    return false;
	}

	//boundPopulationSize();
	//setFromPopulation(createPopulation(300, 300));
	return true;
    }

    public void boundPopulationSize() {
	int totalPopulation = 0;
	double rescalingRatio;

	int numberOfIngredients = parameters.size();

	for (int i = 0; i < numberOfIngredients; i ++)
	    totalPopulation += popCounts.get(i).intValue();

	if (totalPopulation > SwarmParameters.numberOfIndividualsMax)
	    rescalingRatio = (double) (SwarmParameters.numberOfIndividualsMax - numberOfIngredients) / (totalPopulation == numberOfIngredients ? 1.0 : (double) (totalPopulation - numberOfIngredients));

	else rescalingRatio = 1;

	if (rescalingRatio != 1)
	    for (int i = 0; i < numberOfIngredients; i ++)
		popCounts.set(i, new Integer(1 + (int) Math.floor((double) (popCounts.get(i).intValue() - 1) * rescalingRatio)));
    }

    public void setFromPopulation(ArrayList<SwarmIndividual> sol) {
	parameters = new ArrayList<SwarmParameters>();
	popCounts = new ArrayList<Integer>();

	SwarmParameters tempParam;

	for (int i = 0; i < sol.size(); i ++) {
	    tempParam = sol.get(i).genome;

	    boolean alreadyInParameters = false;
	    for (int j = 0; j < parameters.size(); j ++) {
		if (parameters.get(j).equals(tempParam)) {
		    alreadyInParameters = true;
		    popCounts.set(j, new Integer(popCounts.get(j).intValue() + 1));
		}
	    }
	    if (alreadyInParameters == false) {
		parameters.add(tempParam);
		popCounts.add(new Integer(1));
	    }
	}

	setRecipeText();
    }

    private void setRecipeText() {
	SwarmParameters tempParam;

	recipeText = "";

	for (int i = 0; i < parameters.size(); i ++) {
	    tempParam = parameters.get(i);
	    recipeText += "" + popCounts.get(i).intValue() + " * ("
		+ shorten(tempParam.neighborhoodRadius) + ", "
		+ shorten(tempParam.normalSpeed) + ", "
		+ shorten(tempParam.maxSpeed) + ", "
		+ shorten(tempParam.c1) + ", "
		+ shorten(tempParam.c2) + ", "
		+ shorten(tempParam.c3) + ", "
		+ shorten(tempParam.c4) + ", "
		+ shorten(tempParam.c5) // + ", "
		//		+ shorten(tempParam.minLocationDifference) + ", "
		//		+ shorten(tempParam.maxLocationDifference) + ", "
		//		+ shorten(tempParam.minVelocityDifference) + ", "
		//		+ shorten(tempParam.maxVelocityDifference)
		+ ")\n";
	}
    }

    private double shorten(double d) {
	return Math.round(d * 100.0) / 100.0;
    }

    public ArrayList<SwarmIndividual> createPopulation(int width, int height) {
	if (parameters == null) return null;

	ArrayList<SwarmIndividual> newPopulation = new ArrayList<SwarmIndividual>();
	SwarmParameters tempParam;
	
	/*
	for (int i = 0; i < parameters.size(); i ++) {
	    tempParam = parameters.get(i);
	    for (int j = 0; j < popCounts.get(i).intValue(); j ++)
		newPopulation.add(new SwarmIndividual(Math.random() * width, Math.random() * height, Math.random() * 10 - 5, Math.random() * 10 - 5, new SwarmParameters(tempParam), this));
	}
	*/
	newPopulation.add(new SwarmIndividual(150, 150, Math.random() * 10 - 5, Math.random() * 10 - 5, new SwarmParameters(randomlyPickParameters()), this));

	return newPopulation;
    }

    public SwarmParameters randomlyPickParameters() {
	int totalPopulation = 0;
	int numberOfIngredients = parameters.size();

	for (int i = 0; i < numberOfIngredients; i ++)
	    totalPopulation += popCounts.get(i).intValue();
	
	int r = (int) Math.floor(Math.random() * totalPopulation);

	int j = 0;
	for (int i = 0; i < numberOfIngredients; i ++) {
	    if (r >= j && r < j + popCounts.get(i)) return parameters.get(i);
	    else j += popCounts.get(i);
	}

	return parameters.get(0);
    }

    public Recipe mutate() {
	setRecipeText();
	Recipe tempRecipe = new Recipe(recipeText);

	int numberOfIngredients = tempRecipe.parameters.size();

	// Insertions, duplications and deletions

	for (int j = 0; j < numberOfIngredients; j ++) {
	    if (Math.random() < duplicationOrDeletionRatePerParameterSets) {
		if (Math.random() < .5) { // Duplication
		    tempRecipe.parameters.add(j + 1, tempRecipe.parameters.get(j));
		    tempRecipe.popCounts.add(j + 1, tempRecipe.popCounts.get(j));
		    numberOfIngredients ++;
		    j ++;
		}
		else { // Deletion
		    if (numberOfIngredients > 1) {
			tempRecipe.parameters.remove(j);
			tempRecipe.popCounts.remove(j);
			numberOfIngredients --;
			j --;
		    }
		}
	    }
	}

	if (Math.random() < randomAdditionRatePerRecipe) { // Addition
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
		tempRecipe.parameters.set(j, tempParam);
	    }
	}

	//tempRecipe.boundPopulationSize();
	
	return tempRecipe;
    }
}
