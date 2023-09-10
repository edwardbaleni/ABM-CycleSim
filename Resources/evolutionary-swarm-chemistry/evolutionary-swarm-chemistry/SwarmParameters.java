// SwarmParameters.java
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

public class SwarmParameters {
    static int numberOfIndividualsMax = 10000;

    double neighborhoodRadius;
    static double neighborhoodRadiusMax = 300;

    double normalSpeed;
    static double normalSpeedMax = 20;

    double maxSpeed;
    static double maxSpeedMax = 40;

    double c1;
    static double c1Max = 1;

    double c2;
    static double c2Max = 1;

    double c3;
    static double c3Max = 100;

    double c4;
    static double c4Max = 0.5;

    double c5;
    static double c5Max = 1;

    //    double minLocationDifference;
    //    double maxLocationDifference;
    //    double minVelocityDifference;
    //    double maxVelocityDifference;

    public SwarmParameters() {
	neighborhoodRadius = Math.random() * neighborhoodRadiusMax;
	normalSpeed = Math.random() * normalSpeedMax;
	maxSpeed = Math.random() * maxSpeedMax;
	c1 = Math.random() * c1Max;
	c2 = Math.random() * c2Max;
	c3 = Math.random() * c3Max;
	c4 = Math.random() * c4Max;
	c5 = Math.random() * c5Max;
	//	minLocationDifference = 0.0;
	//	maxLocationDifference = neighborhoodRadius;
	//	minVelocityDifference = 0.0;
	//	maxVelocityDifference = maxSpeed;
    }

    public SwarmParameters(double p1, double p2, double p3, double p4,
			   double p5, double p6, double p7, double p8) {
	//,
	//			   double p9, double p10, double p11, double p12) {
	neighborhoodRadius = p1;
	normalSpeed = p2;
	maxSpeed = p3;
	c1 = p4;
	c2 = p5;
	c3 = p6;
	c4 = p7;
	c5 = p8;
	//	minLocationDifference = p9;
	//	maxLocationDifference = p10;
	//	minVelocityDifference = p11;
	//	maxVelocityDifference = p12;

	boundParameterValues();
    }

    public SwarmParameters(SwarmParameters parent) {
	neighborhoodRadius = parent.neighborhoodRadius;
	normalSpeed = parent.normalSpeed;
	maxSpeed = parent.maxSpeed;
	c1 = parent.c1;
	c2 = parent.c2;
	c3 = parent.c3;
	c4 = parent.c4;
	c5 = parent.c5;
	//	minLocationDifference = parent.minLocationDifference;
	//	maxLocationDifference = parent.maxLocationDifference;
	//	minVelocityDifference = parent.minVelocityDifference;
	//	maxVelocityDifference = parent.maxVelocityDifference;
    }

    public boolean equals(SwarmParameters param) {
	if (
	    (neighborhoodRadius == param.neighborhoodRadius) &&
	    (normalSpeed == param.normalSpeed) &&
	    (maxSpeed == param.maxSpeed) &&
	    (c1 == param.c1) &&
	    (c2 == param.c2) &&
	    (c3 == param.c3) &&
	    (c4 == param.c4) &&
	    (c5 == param.c5) // &&
	    //	    (minLocationDifference == param.minLocationDifference) &&
	    //	    (maxLocationDifference == param.maxLocationDifference) &&
	    //	    (minVelocityDifference == param.minVelocityDifference) &&
	    //	    (maxVelocityDifference == param.maxVelocityDifference)
	    ) return true;
	else return false;
    }

    public void inducePointMutations(double rate, double magnitude) {
	if (Math.random() < rate)
	    neighborhoodRadius += (Math.random() - 0.5) * neighborhoodRadiusMax * magnitude;

	if (Math.random() < rate)
	    normalSpeed += (Math.random() - 0.5) * normalSpeedMax * magnitude;

	if (Math.random() < rate)
	    maxSpeed += (Math.random() - 0.5) * maxSpeedMax * magnitude;

	if (Math.random() < rate)
	    c1 += (Math.random() - 0.5) * c1Max * magnitude;

	if (Math.random() < rate)
	    c2 += (Math.random() - 0.5) * c2Max * magnitude;

	if (Math.random() < rate)
	    c3 += (Math.random() - 0.5) * c3Max * magnitude;

	if (Math.random() < rate)
	    c4 += (Math.random() - 0.5) * c4Max * magnitude;

	if (Math.random() < rate)
	    c5 += (Math.random() - 0.5) * c5Max * magnitude;

	boundParameterValues();
    }

    public void boundParameterValues() {
	if (neighborhoodRadius < 0) neighborhoodRadius = 0;
	else if (neighborhoodRadius > neighborhoodRadiusMax) neighborhoodRadius = neighborhoodRadiusMax;

	if (normalSpeed < 0) normalSpeed = 0;
	else if (normalSpeed > normalSpeedMax) normalSpeed = normalSpeedMax;

	if (maxSpeed < 0) maxSpeed = 0;
	else if (maxSpeed > maxSpeedMax) maxSpeed = maxSpeedMax;

	if (c1 < 0) c1 = 0;
	else if (c1 > c1Max) c1 = c1Max;

	if (c2 < 0) c2 = 0;
	else if (c2 > c2Max) c2 = c2Max;

	if (c3 < 0) c3 = 0;
	else if (c3 > c3Max) c3 = c3Max;

	if (c4 < 0) c4 = 0;
	else if (c4 > c4Max) c4 = c4Max;

	if (c5 < 0) c5 = 0;
	else if (c5 > c5Max) c5 = c5Max;
    }

    public Color displayColor() {
	return new Color((float) (c1 / c1Max * 0.8),
			 (float) (c2 / c2Max * 0.8),
			 (float) (c3 / c3Max * 0.8));
    }
}
