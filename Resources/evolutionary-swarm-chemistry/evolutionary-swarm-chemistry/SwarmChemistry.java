// SwarmChemistry.java
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
import java.applet.Applet;

public class SwarmChemistry extends Applet {
    public static void main(String args[]) {
	boolean recipeIsGiven = false;
	int n;// = 10;
	SwarmChemistryEnvironment master;

	if (args.length != 1) {
	    System.out.println("Usage:\njava SwarmChemistry number|recipe");
	    System.exit(0);
	}

	try {
	    n = Integer.parseInt(args[0]);
	}
	catch(NumberFormatException e) {
	    n = 1;
	    recipeIsGiven = true;
	}
	if (n < 1) n = 1;
	if (n > 1000) n = 1000;

	if (recipeIsGiven)
	    master = new SwarmChemistryEnvironment(false, args[0]);
	else
	    master = new SwarmChemistryEnvironment(false, n);
    }

    public void init() {
	//SwarmChemistryEnvironment master = new SwarmChemistryEnvironment(true, 1);
    }
}
