# README.txt of "Evolutionary Swarm Chemistry Simulator"
# Hiroki Sayama (sayama@binghamton.edu)
# 7/28/2015

# To run a simulation with 100 randomly generated active particles:

java SwarmChemistry 100

# To run a simulation with just one active particle with a given recipe:

java SwarmChemistry "48 150.39 15.89 23.54 0.74 0.45 62.65 0.33 0.13 152 217.14 12.13 12.42 0.59 0.98 14.06 0.04 0.65 14 248.54 5.85 22.26 0.43 0.11 17.14 0.06 0.68 31 141.53 2.91 4.86 0.92 0.03 21.87 0.28 0.2"

# In either case, the simulation snapshots (in JPEG) are continuously
# saved in every 10 time steps in the local directory. Running this
# simulator will generate some weird interface windows, but those are
# remnants originating from its older versions; please ignore them, as
# I haven't had much time to elaborate on the interface.  Once you
# obtain a series of snapshots, you can make them into a movie using
# any movie making software. Enjoy!

# P.S. If you want to re-compile the code, use the
# "ignore.symbol.file" option as follows:
#
#   javac -XDignore.symbol.file SwarmChemistry.java
#
# This is because this code uses the "com.sun.image.codec.jpeg"
# package that is no longer supported officially by Oracle.
