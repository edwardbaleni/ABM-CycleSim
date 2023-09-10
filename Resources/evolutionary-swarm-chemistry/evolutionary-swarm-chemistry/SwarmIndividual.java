// SwarmIndividual.java
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

public class SwarmIndividual {
    public double x, y, dx, dy, dx2, dy2;
    public SwarmParameters genome;
    public int rankInXOrder, rankInYOrder;
    public Recipe recipe;

    public SwarmIndividual() {
	this(0.0, 0.0, 0.0, 0.0, new SwarmParameters());
    }

    public SwarmIndividual(double xx, double yy, double dxx, double dyy,
			   SwarmParameters g) {
	this(xx, yy, dxx, dyy, g, null);
    }

    public SwarmIndividual(double xx, double yy, double dxx, double dyy,
			   SwarmParameters g, Recipe r) {
	x = xx;
	y = yy;
	dx = dx2 = dxx;
	dy = dy2 = dyy;
	genome = g;
	rankInXOrder = 0;
	rankInYOrder = 0;
	recipe = r;
    }

    public void accelerate(double ax, double ay, double maxMove) {
	dx2 += ax;
	dy2 += ay;

	double d = dx2 * dx2 + dy2 * dy2;
	if (d > maxMove * maxMove) {
	    double normalizationFactor = maxMove / Math.sqrt(d);
	    dx2 *= normalizationFactor;
	    dy2 *= normalizationFactor;
	}
    }

    public void move() {
	dx = dx2;
	dy = dy2;
	x += dx;
	y += dy;
	/*
 	if (x > 2500 + 150) { dx = -dx; x = 2500 + 150 + dx; }
	if (x < - 2500 + 150) {dx = -dx; x = - 2500 + 150 + dx; }
	if (y > 2500 + 150) {dy = -dy; y = 2500 + 150 + dy; }
	if (y < - 2500 + 150) {dy = -dy; y = - 2500 + 150 + dy; }
	*/
 	if (x > 2500 + 150) x -= 5000;
	if (x < - 2500 + 150) x +=  5000;
	if (y > 2500 + 150) y -= 5000;
	if (y < - 2500 + 150) y += 5000;
    }

    public Color displayColor() {
	return genome.displayColor();
    }
}
