// SwarmPopulationSimulator.java
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
import java.awt.image.BufferedImage;
import java.io.*;
import com.sun.image.codec.jpeg.*;

public class SwarmPopulationSimulator extends Frame {
    private SwarmPopulationSimulator myself;
    private int width, height, originalWidth, originalHeight;
    private Insets ins;
    private Graphics img, sfg;

    private Checkbox tracking, mouseEffect;

    private double currentMidX, currentMidY, currentScalingFactor;
    private double swarmRadius = 3; // radius of nodes
    private double swarmDiameter;
    private int mouseX, mouseY;
    private int weightOfMouseCursor = 20;
    private boolean isMouseIn;

    public int frameNumber;
    public RecipeFrame displayedRecipe;
    public SwarmPopulation population;
    private SwarmPopulation[] originalPopulationList;
    private java.util.List<RecipeFrame> recipeFrames;

    public Image im;
    public ArrayList<SwarmIndividual> swarmInBirthOrder, swarmInXOrder, swarmInYOrder;
    public boolean isSelected, notYetNoticed;

    public double mutationRateAtTransmission = 0.1; // *** to be modified ***
    public double mutationRateAtNormalTime = 0.001; // *** to be modified ***

    public SwarmPopulationSimulator(int frameSize, int spaceSize, SwarmPopulation sol, SwarmPopulation[] solList, int num, Checkbox tr, Checkbox mo, java.util.List<RecipeFrame> rcfs) {
	super("Swarm #" + (num + 1) + ": " + sol.title);
	myself = this;

	frameNumber = num;
	displayedRecipe = null;
	recipeFrames = rcfs;
	population = sol;
	originalPopulationList = solList;

	width = height = frameSize;
	originalWidth = originalHeight = spaceSize;
	tracking = tr;
	mouseEffect = mo;
	setVisible(true);
	ins = getInsets();

	setSize(width + ins.left + ins.right, height + ins.top + ins.bottom);
	setBackground(Color.white);
	while (sfg == null) sfg = getGraphics();

	synchronized(this) {
	    while (im == null) im = createImage(width, height);
	    while (img == null) img = im.getGraphics();
	}
	clearImage();

	addWindowListener(new WindowAdapter() {
		public void windowClosing(WindowEvent e) {
		    if (displayedRecipe != null) {
			displayedRecipe.orphanize();
		    }
		    dispose();
		}
	    });

	addComponentListener(new ComponentAdapter() {
		public void componentResized(ComponentEvent e) {
		    ins = getInsets();
		    width = getWidth() - ins.left - ins.right;
		    height = getHeight() - ins.top - ins.bottom;
		    synchronized(myself) {
			im = null;
			img = null;
			while (im == null) im = createImage(width, height);
			while (img == null) img = im.getGraphics();
		    }
		    redraw();
		}
	    });

	addMouseListener(new MouseAdapter() {
		public void mouseClicked(MouseEvent me) {
		    if (me.getModifiers() == InputEvent.BUTTON3_MASK) {
			outputRecipe();
		    }
		    else if (isSelected == false) isSelected = true;
		    else notYetNoticed = true;
		}
		public void mouseEntered(MouseEvent me) {
		    isMouseIn = true;
		}
		public void mouseExited(MouseEvent me) {
		    isMouseIn = false;
		}
	    });

	mouseX = mouseY = -100;

	addMouseMotionListener(new MouseMotionAdapter() {
		public void mouseDragged(MouseEvent me) {
		    mouseX = me.getX() - ins.left;
		    mouseY = me.getY() - ins.top;
		}
		public void mouseMoved(MouseEvent me) {
		    mouseX = me.getX() - ins.left;
		    mouseY = me.getY() - ins.top;
		}
	    });

	isSelected = false;
	notYetNoticed = true;

	currentMidX = 0;
	currentMidY = 0;
	currentScalingFactor = 0;
	swarmDiameter = swarmRadius * 2;
	swarmInBirthOrder = new ArrayList<SwarmIndividual>();
	swarmInXOrder = new ArrayList<SwarmIndividual>();
	swarmInYOrder = new ArrayList<SwarmIndividual>();

	for (int i = 0; i < sol.population.size(); i ++)
	    addSwarm(sol.population.get(i));

	displayStates();
    }

    public void paint(Graphics g) {
	synchronized(this) {
	    while (im == null) im = createImage(width, height);
	    while (img == null) img = im.getGraphics();
	}
	g.drawImage(im, ins.left, ins.top, width, height, this);
    }

    public void redraw() {
	//sfg.drawImage(im, ins.left, ins.top, width, height, this);
    }

    public void clearImage() {
	img.setColor(Color.white);
	img.fillRect(0, 0, width, height);
	redraw();
    }

    public synchronized void addSwarm(SwarmIndividual b) {
	int i;

	swarmInBirthOrder.add(b);

	if (swarmInXOrder.isEmpty()) {
	    swarmInXOrder.add(b);
	    swarmInYOrder.add(b);
	}

	else {

	    if ((b.x - swarmInXOrder.get(0).x)
		< (swarmInXOrder.get(swarmInXOrder.size() - 1).x
		   - b.x)) {
		i = 0;
		while (i < swarmInXOrder.size()) {
		    if (swarmInXOrder.get(i).x >= b.x) break;
		    i ++;
		}
		swarmInXOrder.add(i, b);
	    }
	    else {
		i = swarmInXOrder.size();
		while (i > 0) {
		    if (swarmInXOrder.get(i - 1).x <= b.x) break;
		    i --;
		}
		swarmInXOrder.add(i, b);
	    }

	    if ((b.y - swarmInYOrder.get(0).y)
		< (swarmInYOrder.get(swarmInYOrder.size() - 1).y
		   - b.y)) {
		i = 0;
		while (i < swarmInYOrder.size()) {
		    if (swarmInYOrder.get(i).y >= b.y) break;
		    i ++;
		}
		swarmInYOrder.add(i, b);
	    }
	    else {
		i = swarmInYOrder.size();
		while (i > 0) {
		    if (swarmInYOrder.get(i - 1).y <= b.y) break;
		    i --;
		}
		swarmInYOrder.add(i, b);
	    }

	}

    }

    public synchronized void replacePopulationWith(SwarmPopulation newpop) {
	setTitle("Swarm #" + (frameNumber + 1) + ": " + newpop.title);

	population = newpop;
	originalPopulationList[frameNumber] = population;

	currentMidX = 0;
	currentMidY = 0;
	currentScalingFactor = 0;
	swarmDiameter = swarmRadius * 2;
	swarmInBirthOrder = new ArrayList<SwarmIndividual>();
	swarmInXOrder = new ArrayList<SwarmIndividual>();
	swarmInYOrder = new ArrayList<SwarmIndividual>();

	for (int i = 0; i < newpop.population.size(); i ++)
	    addSwarm(newpop.population.get(i));

	displayStates();
    }

    public synchronized void resetRanksInSwarm() {
	SwarmIndividual tempSwarm;

	for (int i = 0; i < swarmInXOrder.size(); i ++) {
	    tempSwarm = swarmInXOrder.get(i);
	    if (tempSwarm.rankInXOrder != -1) tempSwarm.rankInXOrder = i;
	    else swarmInXOrder.remove(i --);
	}

	for (int i = 0; i < swarmInYOrder.size(); i ++) {
	    tempSwarm = swarmInYOrder.get(i);
	    if (tempSwarm.rankInYOrder != -1) tempSwarm.rankInYOrder = i;
	    else swarmInYOrder.remove(i --);
	}
    }

    public boolean losing(SwarmIndividual defender, SwarmIndividual attacker, String compfunc) {
	// *** the following can be modified to test different competition functions ***

	if (compfunc.equals("leftfaster")) {
	    if (defender.x < 150) compfunc = "faster";
	    else compfunc = "majority-relative";
	}
	else if (compfunc.equals("rightfaster")) {
	    if (defender.x > 150) compfunc = "faster";
	    else compfunc = "majority-relative";
	}
	else if (compfunc.equals("leftslower")) {
	    if (defender.x < 150) compfunc = "slower";
	    else compfunc = "majority-relative";
	}
	else if (compfunc.equals("rightslower")) {
	    if (defender.x > 150) compfunc = "slower";
	    else compfunc = "majority-relative";
	}

	// faster one wins

	if (compfunc.equals("faster")) {
	    if (defender.dx * defender.dx + defender.dy * defender.dy >
		attacker.dx * attacker.dx + attacker.dy * attacker.dy)
		return false;
	    else return true;
	}

	// slower one wins

	else if (compfunc.equals("slower")) {
	    if (defender.dx * defender.dx + defender.dy * defender.dy <
		attacker.dx * attacker.dx + attacker.dy * attacker.dy)
		return false;
	    else return true;
	}

	// attacker from behind wins

	else if (compfunc.equals("behind")) {
	    double angle = 0.75 * Math.PI;
	    double threshold = Math.cos(angle);

	    double ax = attacker.x - defender.x;
	    double ay = attacker.y - defender.y;
	    double bx = defender.dx;
	    double by = defender.dy;

	    if ((ax * bx + ay * by) > 
		threshold * Math.sqrt(ax * ax + ay * ay) * Math.sqrt(bx * bx + by * by))
		return false;
	    else return true;
	}

	// the one with more colleagues wins

	else if (compfunc.equals("majority")) {
	    double interactionRadius = 30;
	    ArrayList<SwarmIndividual> defNeighbors = neighborsOf(defender, interactionRadius);
	    ArrayList<SwarmIndividual> attNeighbors = neighborsOf(attacker, interactionRadius);

	    int defNumber = 0;
	    for (int j = 0; j < defNeighbors.size(); j ++)
		if (defNeighbors.get(j).recipe == defender.recipe) defNumber ++;

	    int attNumber = 0;
	    for (int j = 0; j < attNeighbors.size(); j ++)
		if (attNeighbors.get(j).recipe == attacker.recipe) attNumber ++;
	    
	    if (defNumber < attNumber) return true;
	    else return false;
	}

	// the one with more colleagues wins (relative ratio within its own interaction range)

	else if (compfunc.equals("majority-relative")) {
	    ArrayList<SwarmIndividual> defNeighbors = neighborsOf(defender, Math.max(30.0, defender.genome.neighborhoodRadius)); // *** revised 3/21/2011
	    ArrayList<SwarmIndividual> attNeighbors = neighborsOf(attacker, Math.max(30.0, attacker.genome.neighborhoodRadius)); // *** revised 3/21/2011

	    double defNumber = 0.0;
	    for (int j = 0; j < defNeighbors.size(); j ++)
		if (defNeighbors.get(j).recipe == defender.recipe) defNumber += 1.0;
	    if (defNeighbors.size() > 0.0) defNumber /= defNeighbors.size();

	    double attNumber = 0.0;
	    for (int j = 0; j < attNeighbors.size(); j ++)
		if (attNeighbors.get(j).recipe == attacker.recipe) attNumber += 1.0;
	    if (attNeighbors.size() > 0.0) attNumber /= attNeighbors.size();
	    
	    if (defNumber < attNumber) return true;
	    else return false;
	}

	// the one with more colleagues wins (stochastically)

	else if (compfunc.equals("majority-stochastic")) {
	    double interactionRadius = 30;
	    ArrayList<SwarmIndividual> defNeighbors = neighborsOf(defender, interactionRadius);
	    ArrayList<SwarmIndividual> attNeighbors = neighborsOf(attacker, interactionRadius);

	    int defNumber = 0;
	    for (int j = 0; j < defNeighbors.size(); j ++)
		if (defNeighbors.get(j).recipe == defender.recipe) defNumber ++;

	    int attNumber = 0;
	    for (int j = 0; j < attNeighbors.size(); j ++)
		if (attNeighbors.get(j).recipe == attacker.recipe) attNumber ++;
	    
	    if (Math.random() * (double) (attNumber + defNumber) < (double) attNumber) return true;
	    else return false;
	}

	// the one with more colleagues wins (relative ratio within its own interaction range; stochastically)

	else if (compfunc.equals("majority-relative-stochastic")) {
	    ArrayList<SwarmIndividual> defNeighbors = neighborsOf(defender, Math.max(30.0, defender.genome.neighborhoodRadius)); // *** revised 3/21/2011
	    ArrayList<SwarmIndividual> attNeighbors = neighborsOf(attacker, Math.max(30.0, attacker.genome.neighborhoodRadius)); // *** revised 3/21/2011

	    double defNumber = 0.0;
	    for (int j = 0; j < defNeighbors.size(); j ++)
		if (defNeighbors.get(j).recipe == defender.recipe) defNumber += 1.0;
	    if (defNeighbors.size() > 0.0) defNumber /= defNeighbors.size();

	    double attNumber = 0.0;
	    for (int j = 0; j < attNeighbors.size(); j ++)
		if (attNeighbors.get(j).recipe == attacker.recipe) attNumber += 1.0;
	    if (attNeighbors.size() > 0.0) attNumber /= attNeighbors.size();
	    
	    if (Math.random() * (double) (attNumber + defNumber) < (double) attNumber) return true;
	    else return false;
	}

	// longer recipe wins

	else if (compfunc.equals("recipe-length")) {
	    if (attacker.recipe.parameters.size() <= defender.recipe.parameters.size())
		return false;
	    else return true;
	}

	// majority * longer recipe

	else if (compfunc.equals("majority-and-recipe-length")) {
	    double interactionRadius = 30;
	    ArrayList<SwarmIndividual> defNeighbors = neighborsOf(defender, interactionRadius);
	    ArrayList<SwarmIndividual> attNeighbors = neighborsOf(attacker, interactionRadius);

	    int defNumber = 0;
	    for (int j = 0; j < defNeighbors.size(); j ++)
		if (defNeighbors.get(j).recipe == defender.recipe) defNumber ++;

	    int attNumber = 0;
	    for (int j = 0; j < attNeighbors.size(); j ++)
		if (attNeighbors.get(j).recipe == attacker.recipe) attNumber ++;
	    
	    attNumber *= attacker.recipe.parameters.size();
	    defNumber *= defender.recipe.parameters.size();

	    if (defNumber < attNumber) return true;
	    else return false;
	}

	// longer recipe; if length is equal, then majority

	else if (compfunc.equals("recipe-length-then-majority")) {
	    if (attacker.recipe.parameters.size() < defender.recipe.parameters.size())
		return false;
	    else if (attacker.recipe.parameters.size() > defender.recipe.parameters.size())
		return true;

	    else {
		double interactionRadius = 30;
		ArrayList<SwarmIndividual> defNeighbors = neighborsOf(defender, interactionRadius);
		ArrayList<SwarmIndividual> attNeighbors = neighborsOf(attacker, interactionRadius);

		int defNumber = 0;
		for (int j = 0; j < defNeighbors.size(); j ++)
		    if (defNeighbors.get(j).recipe == defender.recipe) defNumber ++;

		int attNumber = 0;
		for (int j = 0; j < attNeighbors.size(); j ++)
		    if (attNeighbors.get(j).recipe == attacker.recipe) attNumber ++;
	    
		if (defNumber < attNumber) return true;
		else return false;
	    }
	}

	else {
	    System.out.println("Usage:\njava SwarmChemistry *type-of-competition-function* number|recipe");
	    System.exit(0);
	}

	return false;
    }

    public ArrayList<SwarmIndividual> neighborsOf(SwarmIndividual tempSwarm, double radius) {
	ArrayList<SwarmIndividual> ngbs = new ArrayList<SwarmIndividual>();
	
	double tempX = tempSwarm.x;
	double tempY = tempSwarm.y;
	double neighborhoodRadiusSquared = radius * radius;

	SwarmIndividual tempSwarm2;

	int numberOfSwarm = swarmInBirthOrder.size();

	// Detecting neighbors using sorted lists

	double minX = tempX - radius;
	double maxX = tempX + radius;
	double minY = tempY - radius;
	double maxY = tempY + radius;
	int minRankInXOrder = tempSwarm.rankInXOrder;
	int maxRankInXOrder = tempSwarm.rankInXOrder;
	int minRankInYOrder = tempSwarm.rankInYOrder;
	int maxRankInYOrder = tempSwarm.rankInYOrder;

	for(int j = tempSwarm.rankInXOrder - 1; j >= 0; j --) {
	    if (swarmInXOrder.get(j).x >= minX)
		minRankInXOrder = j;
	    else break;
	}
	for(int j = tempSwarm.rankInXOrder + 1; j < numberOfSwarm; j ++) {
	    if (swarmInXOrder.get(j).x <= maxX)
		maxRankInXOrder = j;
	    else break;
	}
	for(int j = tempSwarm.rankInYOrder - 1; j >= 0; j --) {
	    if (swarmInYOrder.get(j).y >= minY)
		minRankInYOrder = j;
	    else break;
	}
	for(int j = tempSwarm.rankInYOrder + 1; j < numberOfSwarm; j ++) {
	    if (swarmInYOrder.get(j).y <= maxY)
		maxRankInYOrder = j;
	    else break;
	}

	if (maxRankInXOrder - minRankInXOrder < maxRankInYOrder - minRankInYOrder) {
	    for (int j = minRankInXOrder; j <= maxRankInXOrder; j ++) {
		tempSwarm2 = swarmInXOrder.get(j);
		if (tempSwarm != tempSwarm2) 
		    if (tempSwarm2.rankInYOrder >= minRankInYOrder &&
			tempSwarm2.rankInYOrder <= maxRankInYOrder) {
			if ((tempSwarm2.x - tempSwarm.x) * (tempSwarm2.x - tempSwarm.x) +
			    (tempSwarm2.y - tempSwarm.y) * (tempSwarm2.y - tempSwarm.y)
			    < neighborhoodRadiusSquared) ngbs.add(tempSwarm2);
		    }
	    }
	}
	else {
	    for (int j = minRankInYOrder; j <= maxRankInYOrder; j ++) {
		tempSwarm2 = swarmInYOrder.get(j);
		if (tempSwarm != tempSwarm2) 
		    if (tempSwarm2.rankInXOrder >= minRankInXOrder &&
			tempSwarm2.rankInXOrder <= maxRankInXOrder) {
			if ((tempSwarm2.x - tempSwarm.x) * (tempSwarm2.x - tempSwarm.x) +
			    (tempSwarm2.y - tempSwarm.y) * (tempSwarm2.y - tempSwarm.y)
			    < neighborhoodRadiusSquared) ngbs.add(tempSwarm2);
		    }
	    }
	}

	return ngbs;
    }

    public synchronized void simulateSwarmBehavior(String compfunc){
	SwarmIndividual tempSwarm, tempSwarm2;
	SwarmParameters param;

	double tempX, tempY, tempX2, tempY2, tempDX, tempDY;
	double localCenterX, localCenterY, localDX, localDY, tempAx, tempAy, d;
	int n;

	ArrayList<SwarmIndividual> neighbors;

	int numberOfSwarm = swarmInBirthOrder.size();

	SwarmIndividual mouseCursor = new SwarmIndividual();

	if (mouseEffect.getState() && isMouseIn) {
	    mouseCursor.x = ((double) (mouseX - width / 2)) / currentScalingFactor + currentMidX;
	    mouseCursor.y = ((double) (mouseY - height / 2)) / currentScalingFactor + currentMidY;
	}

	for (int i = 0; i < numberOfSwarm; i ++) {
	    tempSwarm = swarmInBirthOrder.get(i);
	    param = tempSwarm.genome;
	    tempX = tempSwarm.x;
	    tempY = tempSwarm.y;

	    // simulating recipe transmission by collision; added on 3/21/2011

	    double minRSquared = 10.0 * 10.0;
	    double tempRSquared;
	    SwarmIndividual nearest = null;

	    neighbors = neighborsOf(tempSwarm, 10);
	    n = neighbors.size();
	    for (int j = 0; j < n; j ++) {
		tempSwarm2 = neighbors.get(j);
		if (tempSwarm2.recipe != null) {
		    tempRSquared = (tempX - tempSwarm2.x) * (tempX - tempSwarm2.x) + (tempY - tempSwarm2.y) * (tempY - tempSwarm2.y);
		    if (tempRSquared < minRSquared) {
			minRSquared = tempRSquared;
			nearest = tempSwarm2;
		    }
		}
	    }

	    if (nearest != null) {
		if (tempSwarm.recipe != nearest.recipe) {
		    if (tempSwarm.recipe == null || losing(tempSwarm, nearest, compfunc)) {
			if (Math.random() < mutationRateAtTransmission)
			    tempSwarm.recipe = nearest.recipe.mutate();
			else
			    tempSwarm.recipe = nearest.recipe;
			tempSwarm.genome = tempSwarm.recipe.randomlyPickParameters();
		    }
		}
	    }

	    // finding neighbors within interaction range

	    neighbors = neighborsOf(tempSwarm, param.neighborhoodRadius);

	    if (mouseEffect.getState() && isMouseIn) {
		if ((mouseCursor.x - tempX) * (mouseCursor.x - tempX) +
		    (mouseCursor.y - tempY) * (mouseCursor.y - tempY)
		    < param.neighborhoodRadius * param.neighborhoodRadius)
		    for (int j = 0; j < weightOfMouseCursor; j ++)
			neighbors.add(mouseCursor);
	    }

	    // simulating the behavior of swarm agents

	    n = neighbors.size();

	    if (n == 0) {
		tempAx = Math.random() - 0.5;
		tempAy = Math.random() - 0.5;
	    }

	    else {
		/* commented out on 3/21/2011; moved up
		double minRSquared = 10.0 * 10.0;
		double tempRSquared;
		SwarmIndividual nearest = null;
		*/

		localCenterX = localCenterY = 0;
		localDX = localDY = 0;
		for (int j = 0; j < n; j ++) {
		    tempSwarm2 = neighbors.get(j);
		    localCenterX += tempSwarm2.x;
		    localCenterY += tempSwarm2.y;
		    localDX += tempSwarm2.dx;
		    localDY += tempSwarm2.dy;

		    /* commented out on 3/21/2011; moved up
		    if (tempSwarm2.recipe != null) {
			tempRSquared = (tempX - tempSwarm2.x) * (tempX - tempSwarm2.x) + (tempY - tempSwarm2.y) * (tempY - tempSwarm2.y);
			if (tempRSquared < minRSquared) {
			    minRSquared = tempRSquared;
			    nearest = tempSwarm2;
			}
		    }
		    */
		}

		/* commented out on 3/21/2011; moved up
		if (nearest != null) {
		    if (tempSwarm.recipe != nearest.recipe) {
			if (tempSwarm.recipe == null || losing(tempSwarm, nearest, compfunc)) {
			    if (Math.random() < mutationRateAtTransmission)
				tempSwarm.recipe = nearest.recipe.mutate();
			    else
				tempSwarm.recipe = nearest.recipe;
			    tempSwarm.genome = tempSwarm.recipe.randomlyPickParameters();
			}
		    }
		}
		*/

		localCenterX /= n;
		localCenterY /= n;
		localDX /= n;
		localDY /= n;

		if (tempSwarm.recipe != null) {

		    /*
		    double locDiffSquared = (localCenterX - tempX) * (localCenterX - tempX) + (localCenterY - tempY) * (localCenterY - tempY);
		    double velDiffSquared = (localDX - tempSwarm.dx) * (localDX - tempSwarm.dx) + (localDY - tempSwarm.dy) * (localDY - tempSwarm.dy);

		    if (locDiffSquared < param.minLocationDifference * param.minLocationDifference ||
			locDiffSquared > param.maxLocationDifference * param.maxLocationDifference ||
			velDiffSquared < param.minVelocityDifference * param.minVelocityDifference ||
			velDiffSquared > param.maxVelocityDifference * param.maxVelocityDifference) {
		    */

		    if (Math.random() < 0.005) {
			tempSwarm.genome = tempSwarm.recipe.randomlyPickParameters();
			param = tempSwarm.genome;
		    }
		}

		tempAx = tempAy = 0;

		tempAx += (localCenterX - tempX) * param.c1;
		tempAy += (localCenterY - tempY) * param.c1;

		tempAx += (localDX - tempSwarm.dx) * param.c2;
		tempAy += (localDY - tempSwarm.dy) * param.c2;

		for (int j = 0; j < n; j ++) {
		    tempSwarm2 = neighbors.get(j);
		    tempX2 = tempSwarm2.x;
		    tempY2 = tempSwarm2.y;
		    d = (tempX - tempX2) * (tempX - tempX2) +
			(tempY - tempY2) * (tempY - tempY2);
		    if (d == 0) d = 0.001;
		    tempAx += (tempX - tempX2) / d * param.c3;
		    tempAy += (tempY - tempY2) / d * param.c3;
		}

		if (Math.random() < param.c4) {
		    tempAx += Math.random() * 10 - 5;
		    tempAy += Math.random() * 10 - 5;
		}
	    }

	    tempSwarm.accelerate(tempAx, tempAy, param.maxSpeed);

	    tempDX = tempSwarm.dx2;
	    tempDY = tempSwarm.dy2;
	    d = Math.sqrt(tempDX * tempDX + tempDY * tempDY);
	    if (d == 0) d = 0.001;
	    tempSwarm.accelerate(tempDX * (param.normalSpeed - d) / d * param.c5,
				 tempDY * (param.normalSpeed - d) / d * param.c5,
				 param.maxSpeed);

	    // new addition: *** random mutation at normal time ***

	    if (Math.random() < mutationRateAtNormalTime)
		if (tempSwarm.recipe != null)
		    tempSwarm.recipe = tempSwarm.recipe.mutate();
	}

    }

    public synchronized void updateStates() {
	SwarmIndividual tempSwarm, tempSwarm2;
	int numberOfSwarm = swarmInBirthOrder.size();
	int j;

	for (int i = 0; i < numberOfSwarm; i ++)
	    swarmInBirthOrder.get(i).move();

	// Sorting swarmInXOrder and swarmInYOrder using insertion sorting algorithm

	for (int i = 1; i < numberOfSwarm; i ++) {
	    tempSwarm = swarmInXOrder.get(i);
	    j = i;
	    while (j > 0) {
		tempSwarm2 = swarmInXOrder.get(j - 1);
		if (tempSwarm2.x > tempSwarm.x) {
		    swarmInXOrder.set(j, tempSwarm2);
		    j --;
		}
		else break;
	    }
	    swarmInXOrder.set(j, tempSwarm);
	
	    tempSwarm = swarmInYOrder.get(i);
	    j = i;
	    while (j > 0) {
		tempSwarm2 = swarmInYOrder.get(j - 1);
		if (tempSwarm2.y > tempSwarm.y) {
		    swarmInYOrder.set(j, tempSwarm2);
		    j --;
		}
		else break;
	    }
	    swarmInYOrder.set(j, tempSwarm);
	}
	
	resetRanksInSwarm();

    }

    public synchronized void displayStates() {
	SwarmIndividual ag, ag2;
	int max, x, y;
	double minX, maxX, minY, maxY, tempX, tempY, midX, midY, scalingFactor;
	double averageInterval;
	double intervalCoefficient = 10.0;
	int tempRadius, tempDiameter;
	int margin = 0;
	double gridInterval = 300;

	while (img == null);

	//if (isSelected) img.setColor(Color.cyan);
	//else 
	img.setColor(Color.white);
	img.fillRect(0, 0, width, height);

	max = swarmInBirthOrder.size();

	/*
	if ((max = swarmInBirthOrder.size()) == 0) {
	    redraw();
	    return;
	}

	minX = swarmInXOrder.get(0).x;
	maxX = swarmInXOrder.get(max - 1).x;
	minY = swarmInYOrder.get(0).y;
	maxY = swarmInYOrder.get(max - 1).y;

	if (tracking.getState() && max > 10) {

	    averageInterval = 0;
	    for (int i = 0; i < max - 1; i ++) {
		ag = swarmInXOrder.get(i);
		ag2 = swarmInXOrder.get(i + 1);
		averageInterval += ag2.x - ag.x;
	    }
	    averageInterval /= max - 1;
	    for (int i = 0; i < max - 10; i ++) {
		ag = swarmInXOrder.get(i);
		ag2 = swarmInXOrder.get(i + 10);
		if (ag2.x - ag.x < averageInterval * intervalCoefficient) {
		    minX = ag.x;
		    break;
		}
	    }
	    for (int i = max - 1; i >= 10; i --) {
		ag = swarmInXOrder.get(i - 10);
		ag2 = swarmInXOrder.get(i);
		if (ag2.x - ag.x < averageInterval * intervalCoefficient) {
		    maxX = ag2.x;
		    break;
		}
	    }

	    tempX = (maxX - minX) * 0.1;
	    minX -= tempX;
	    maxX += tempX;

	    averageInterval = 0;
	    for (int i = 0; i < max - 1; i ++) {
		ag = swarmInYOrder.get(i);
		ag2 = swarmInYOrder.get(i + 1);
		averageInterval += ag2.y - ag.y;
	    }
	    averageInterval /= max - 1;
	    for (int i = 0; i < max - 10; i ++) {
		ag = swarmInYOrder.get(i);
		ag2 = swarmInYOrder.get(i + 10);
		if (ag2.y - ag.y < averageInterval * intervalCoefficient) {
		    minY = ag.y;
		    break;
		}
	    }
	    for (int i = max - 1; i >= 10; i --) {
		ag = swarmInYOrder.get(i - 10);
		ag2 = swarmInYOrder.get(i);
		if (ag2.y - ag.y < averageInterval * intervalCoefficient) {
		    maxY = ag2.y;
		    break;
		}
	    }

	    tempY = (maxY - minY) * 0.1;
	    minY -= tempY;
	    maxY += tempY;
	}

	if (maxX - minX < (double) originalWidth)
	    maxX = (minX = (minX + maxX - (double) originalWidth) / 2) + (double) originalWidth;
	if (maxY - minY < (double) originalHeight)
	    maxY = (minY = (minY + maxY - (double) originalHeight) / 2) + (double) originalHeight;
	*/

	minX = minY = -2500 + 150;
	maxX = maxY =  2500 + 150;

	currentMidX = (minX + maxX) / 2;
	currentMidY = (minY + maxY) / 2;

	/*
	if ((maxX - minX) * height > (maxY - minY) * width)
	    scalingFactor = ((double) (width - 2 * margin)) / (maxX - minX);
	else
	    scalingFactor = ((double) (height - 2 * margin)) / (maxY - minY);
	*/

	currentScalingFactor = 400.0 / 5000.0;

	/*
	if (currentScalingFactor == 0) {
	    currentMidX += midX;
	    currentMidY += midY;
	    currentScalingFactor = scalingFactor;
	}
	else {
	    currentMidX += (midX - currentMidX) * 0.1;
	    currentMidY += (midY - currentMidY) * 0.1;
	    currentScalingFactor += (scalingFactor - currentScalingFactor) * 0.5;
	}
	*/

	// Drawing grids

	/*
	img.setColor(Color.lightGray);
	for (tempX = Math.floor((-((double) width) / 2 / currentScalingFactor + currentMidX) / gridInterval) * gridInterval;
	     tempX < ((double) width) / 2 / currentScalingFactor + currentMidX;
	     tempX += gridInterval)
	    img.drawLine((int) ((tempX - currentMidX) * currentScalingFactor) + width/2,
			 0,
			 (int) ((tempX - currentMidX) * currentScalingFactor) + width/2,
			 height);
	for (tempY = Math.floor((-((double) height) / 2 / currentScalingFactor + currentMidY) / gridInterval) * gridInterval;
	     tempY < ((double) height) / 2 / currentScalingFactor + currentMidY;
	     tempY += gridInterval)
	    img.drawLine(0,
			 (int) ((tempY - currentMidY) * currentScalingFactor) + height/2,
			 width,
			 (int) ((tempY - currentMidY) * currentScalingFactor) + height/2);

	*/

	// Drawing swarm

	//tempRadius = (int) (swarmRadius * currentScalingFactor);
	//tempDiameter = (int) (swarmDiameter * currentScalingFactor);
	//	if (tempDiameter < 1) tempDiameter = 1;

	for (int i = 0; i < max; i ++) {
	    ag = swarmInBirthOrder.get(i);
	    x = (int) ((ag.x - currentMidX) * currentScalingFactor) + width / 2;
	    y = (int) ((ag.y - currentMidY) * currentScalingFactor) + height / 2;
	    img.setColor(ag.displayColor());
	    //	    img.fillOval(x - tempRadius, y - tempRadius, tempDiameter, tempDiameter);
	    img.fillRect(x, y, 1, 1);
	}

	redraw();

	// Relocating swarm if they went too far

	/*
	if (midX < - 3 * gridInterval) {
	    currentMidX += gridInterval;
	    for (int i = 0; i < max; i ++)
		swarmInBirthOrder.get(i).x += gridInterval;
	}
	else if (midX > 3 * gridInterval) {
	    currentMidX -= gridInterval;
	    for (int i = 0; i < max; i ++)
		swarmInBirthOrder.get(i).x -= gridInterval;
	}

	if (midY < - 3 * gridInterval) {
	    currentMidY += gridInterval;
	    for (int i = 0; i < max; i ++)
		swarmInBirthOrder.get(i).y += gridInterval;
	}
	else if (midY > 3 * gridInterval) {
	    currentMidY -= gridInterval;
	    for (int i = 0; i < max; i ++)
		swarmInBirthOrder.get(i).y -= gridInterval;
	}
	*/
    }

    public void saveImage(String initial, int timestep) {
	saveJPEG(im, initial + "-" + String.format("%06d", timestep) + ".jpg", (float) 1.0);
    }

    // The following code was thanks to N. Taka
    // (http://www.geocities.jp/ntaka329/java/faq/ques_jpeg_save.html)
    public boolean saveJPEG(Image saveImage, String saveName, float quality) {
	BufferedImage buffImage;
	FileOutputStream foStream;
	int width = saveImage.getWidth(null);
	int height = saveImage.getHeight(null);
	
	buffImage = new BufferedImage(width,height,BufferedImage.TYPE_INT_BGR);
	Graphics g = buffImage.getGraphics();
	
	try {
	    g.drawImage(saveImage,0,0,null);
	} catch (NullPointerException e) {
	    e.printStackTrace();
	    return false;
	}
	try {
	    foStream = new FileOutputStream(saveName);
	} catch (FileNotFoundException e) {
	    e.printStackTrace();
	    return false;
	} catch (SecurityException e) {
	    e.printStackTrace();
	    return false;
	}
	JPEGEncodeParam param =	 JPEGCodec.getDefaultJPEGEncodeParam(buffImage);
	param.setQuality(quality, false);
	
	JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(foStream,param);
	
	try {
	    encoder.encode(buffImage);
	    foStream.close();
	} catch(IOException e) {
	    e.printStackTrace();
	    return false;
	} catch(ImageFormatException e) {
	    e.printStackTrace();
	    return false;
	}
	System.out.println("Saved "+ saveName);
	return true;
    }

    public synchronized void outputRecipe() {
	if (displayedRecipe == null) {
	    displayedRecipe = new RecipeFrame(this, swarmInBirthOrder, originalWidth, originalHeight, recipeFrames);
	    synchronized (recipeFrames) {
		recipeFrames.add(displayedRecipe);
	    }
	    displayedRecipe.setVisible(true);
	}
	else {
	    displayedRecipe.putImage(im);
	    displayedRecipe.setState(Frame.NORMAL);
	    displayedRecipe.toFront();
	}
    }
}
