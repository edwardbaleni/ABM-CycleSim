// RecipeFrame.java
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

public class RecipeFrame extends Frame implements ActionListener {
    private Recipe recipe;
    private Image im;
    private Insets ins;
    private Canvas swarmCanvas;
    private Panel leftPanel, rightPanel;
    private TextArea recipeBox;
    private Button applyEdits;
    private int width, height;
    private SwarmPopulationSimulator parentFrame;
    private java.util.List<RecipeFrame> recipeFrames;

    public RecipeFrame(SwarmPopulationSimulator par,
		       ArrayList<SwarmIndividual> swarmInAnyOrder,
		       int w, int h, java.util.List<RecipeFrame> rcfs) {

	super("Recipe of Swarm #" + (par.frameNumber + 1));

	parentFrame = par;
	width = w;
	height = h;
	recipeFrames = rcfs;
	setVisible(true);
	setLocation(parentFrame.getLocation());
	ins = getInsets();
	setSize(600 + ins.left + ins.right, 240 + ins.top + ins.bottom);

	addWindowListener(new WindowAdapter() {
		public void windowClosing(WindowEvent e) {
		    synchronized(recipeFrames) {
			recipeFrames.remove(parentFrame.displayedRecipe);
			parentFrame.displayedRecipe = null;
		    }
		    dispose();
		}
	    });

	putImage(parentFrame.im);

	rightPanel = new Panel();
	rightPanel.setLayout(new BorderLayout());
	rightPanel.add(new Label("Screen shot"), BorderLayout.NORTH);
	rightPanel.add(swarmCanvas = new Canvas() {
		public void paint(Graphics g) {
		    g.drawImage(im, 0, 0, 200, 200, this);
		}
	    }, BorderLayout.CENTER);
	swarmCanvas.setSize(200, 200);
	add(rightPanel, BorderLayout.EAST);

	leftPanel = new Panel();
	leftPanel.setLayout(new BorderLayout());
	//	leftPanel.add(new Label("Format: # of agents * (R, Vn, Vm, c1, c2, c3, c4, c5, minLocDiff, maxLocDiff, minVelDiff, maxVelDiff)"), BorderLayout.NORTH);
	leftPanel.add(new Label("Format: # of agents * (R, Vn, Vm, c1, c2, c3, c4, c5)"), BorderLayout.NORTH);
	leftPanel.add(recipeBox = new TextArea(), BorderLayout.CENTER);
	recipeBox.setBackground(Color.white);
	leftPanel.add(applyEdits = new Button("Apply edits"), BorderLayout.SOUTH);
	add(leftPanel, BorderLayout.CENTER);

	applyEdits.addActionListener(this);

	recipe = new Recipe(swarmInAnyOrder);
	recipeBox.setText(recipe.recipeText);	
    }

    public void putImage(Image im2) {
	while (im == null) im = createImage(200, 200);
	im.getGraphics().drawImage(im2, 0, 0, 200, 200, this);
	if (swarmCanvas instanceof Canvas) swarmCanvas.repaint();
    }

    public void actionPerformed(ActionEvent e) {
	if (e.getSource() == applyEdits) {

	    recipe.setFromText(recipeBox.getText());
	    recipeBox.setText(recipe.recipeText);

	    if (recipe.recipeText.charAt(0) == '*')
		recipeBox.setBackground(Color.yellow);
	    else {
		recipeBox.setBackground(Color.white);
		SwarmPopulation newSwarmPop = new SwarmPopulation(recipe.createPopulation(width, height), "Created from a given recipe");
		parentFrame.replacePopulationWith(newSwarmPop);
		im.getGraphics().clearRect(0, 0, 200, 200);
		swarmCanvas.repaint();
	    }
	}
    }

    public void orphanize() {
	setTitle("Orphaned recipe");
	putImage(parentFrame.im);
	recipeBox.setEditable(false);
	applyEdits.setEnabled(false);
    }
}
