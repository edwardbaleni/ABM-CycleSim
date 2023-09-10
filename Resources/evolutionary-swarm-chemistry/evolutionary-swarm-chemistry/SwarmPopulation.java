// SwarmPopulation.java
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


import java.util.*;

public class SwarmPopulation {
    public ArrayList<SwarmIndividual> population;
    public String title;

    public SwarmPopulation(ArrayList<SwarmIndividual> pop, String t) {
	population = pop;
	title = t;
    }

    public SwarmPopulation(String recipeText, String t) {
	Recipe rcp = new Recipe(recipeText);
	population = rcp.createPopulation(300, 300);
	title = t;

	int num = 10000;
	num -= 1;

	double xx, yy;

	for (int i = 0; i < num; i ++) {
	    xx = Math.random() * 5000 - 2500;
	    yy = Math.random() * 5000 - 2500;
	    population.add(new SwarmIndividual(xx + 150, yy + 150, 0, 0,
					       new SwarmParameters(10, 0, 0, 0, 0, 0, 0, 1)));
	}
    }

    private double shorten(double d) {
	return Math.round(d * 100.0) / 100.0;
    }

    public SwarmPopulation(int n, String t) {
	population = new ArrayList<SwarmIndividual>();
	title = t;

	int num = 10000;
	num -= n;

	double xx, yy;

	for (int i = 0; i < n; i ++) {
	    xx = Math.random() * 5000 - 2500;
	    yy = Math.random() * 5000 - 2500;
	    SwarmParameters sp = new SwarmParameters();
	    population.add(new SwarmIndividual(xx + 150, yy + 150, 0, 0, sp,
					       new Recipe("1 * "
							  + shorten(sp.neighborhoodRadius) + " "
							  + shorten(sp.normalSpeed) + " "
							  + shorten(sp.maxSpeed) + " "
							  + shorten(sp.c1) + " "
							  + shorten(sp.c2) + " "
							  + shorten(sp.c3) + " "
							  + shorten(sp.c4) + " "
							  + shorten(sp.c5))));
	}

	for (int i = 0; i < num; i ++) {
	    xx = Math.random() * 5000 - 2500;
	    yy = Math.random() * 5000 - 2500;
	    population.add(new SwarmIndividual(xx + 150, yy + 150, 0, 0,
					       new SwarmParameters(10, 0, 0, 0, 0, 0, 0, 1)));
	}
    }

    public SwarmPopulation(SwarmPopulation a, String t) {
	title = t;

	SwarmIndividual temp;

	population = new ArrayList<SwarmIndividual>();
	for (int i = 0; i < a.population.size(); i ++) {
	    temp = a.population.get(i);
	    population.add(new SwarmIndividual(Math.random() * 5000 - 2500 + 150,
					       Math.random() * 5000 - 2500 + 150,
					       Math.random() * 10 - 5,
					       Math.random() * 10 - 5,
					       new SwarmParameters(temp.genome)));
	}
    }

    public SwarmPopulation(SwarmPopulation a, SwarmPopulation b, double rate, String t) {
	title = t;

	SwarmIndividual temp;
	SwarmPopulation source;

	population = new ArrayList<SwarmIndividual>();
	for (int i = 0; i < (a.population.size() + b.population.size()) / 2; i ++) {
	    if (Math.random() < rate) source = a;
	    else source = b;
	    temp = source.population.get((int) (Math.random() * source.population.size()));
	    population.add(new SwarmIndividual(Math.random() * 5000 - 2500 + 150,
					       Math.random() * 5000 - 2500 + 150,
					       Math.random() * 10 - 5,
					       Math.random() * 10 - 5,
					       new SwarmParameters(temp.genome)));
	}
    }

    public void perturb(double pcm, int spaceSize) {
	int pop = population.size();
	pop += (int) ((Math.random() * 2.0 - 1.0) * pcm * (double) pop);
	if (pop < 1) pop = 1;
	if (pop > SwarmParameters.numberOfIndividualsMax) pop = SwarmParameters.numberOfIndividualsMax;

	ArrayList<SwarmIndividual> newPopulation = new ArrayList<SwarmIndividual>();
	SwarmParameters tempParam;
	for (int i = 0; i < pop; i ++) {
	    tempParam
		= new SwarmParameters(population.get((int) (Math.random() * population.size())).genome);
	    newPopulation.add(new SwarmIndividual(Math.random() * spaceSize,
						  Math.random() * spaceSize,
						  Math.random() * 10 - 5,
						  Math.random() * 10 - 5,
						  tempParam));
	}
	population = newPopulation;
    }
}
