from __future__ import print_function

import openmm as mm
from openmm.app import *
from openmm.app.metadynamics import *
from openmm import *
from simtk.unit import *
from sys import stdout
import os, re,time, shutil, math
import numpy as np
from datetime import datetime
from configobj import ConfigObj

print("Started at: " + str(time.asctime()))
start=datetime.now()

commandFile = sys.argv[1]
keywords = ConfigObj(commandFile)

jobname = keywords.get('METADBIAS_JOBNAME')

#metadynamics settings
bias_factor = float(keywords.get('METADBIAS_FACTOR')) # this is (T+DeltaT)/T
bias_height = float(keywords.get('METADBIAS_GHEIGHT')) * kilocalorie_per_mole #height of each gaussian
bias_frequency = int(keywords.get('METADBIAS_FREQUENCY')) #steps in between gaussian depositions
bias_savefrequency = int(keywords.get('METADBIAS_SAVEFREQUENCY')) #steps in between checkpointing of bias potential 
bias_id = keywords.get('METADBIAS_ID') #directory where to store the bias potential

prmtop = AmberPrmtopFile(jobname + '.prmtop')
inpcrd = AmberInpcrdFile(jobname + '.inpcrd')
system = prmtop.createSystem(nonbondedMethod=PME, nonbondedCutoff=1*nanometer,
                             constraints=HBonds)

#add barostat, but disables it to run NVT.
temperature = 300.0 * kelvin
barostat = MonteCarloBarostat(1*bar, temperature)
barostat.setForceGroup(1)
barostat.setFrequency(999999999)#disabled
system.addForce(barostat)

#
# Metadynamics protocol 
#

#bias force settings
torsions = keywords.get('METADBIAS_TORSIONS')
ndim = len(torsions.keys())

gaussian_width = keywords.get('METADBIAS_GWIDTH')
angle_min = keywords.get('METADBIAS_MINANGLE')
angle_max = keywords.get('METADBIAS_MAXANGLE')
ngrid = keywords.get('METADBIAS_NGRID')
periodic = keywords.get('METADBIAS_PERIODIC')

torForce = []
biasvar = []

for t in range(ndim):
    torForce.append(mm.CustomTorsionForce("theta"))
    p = torsions[str(t)]
    gw = float(gaussian_width[t])*degrees
    amin = float(angle_min[t])*degrees
    amax = float(angle_max[t])*degrees
    per = int(periodic[t]) > 0
    ng = int(ngrid[t])
    torForce[t].addTorsion(int(p[0]), int(p[1]), int(p[2]), int(p[3]))
    biasvar.append(BiasVariable(torForce[t], amin, amax, gw, per, ng))
    
metaD = Metadynamics(system, biasvar, temperature, bias_factor, bias_height, bias_frequency, bias_savefrequency, bias_id)

#Set up Langevin integrator
frictionCoeff = 0.5 / picosecond
dt = float(keywords.get('METADBIAS_MDTIMESTEP'))
MDstepsize = dt * picosecond
integrator = LangevinIntegrator(temperature/kelvin, frictionCoeff/(1/picosecond), MDstepsize/ picosecond)

platform_name = 'CUDA'
if keywords.get('METADBIAS_OPENMMPLATFORM') != None:
    platform_name = keywords.get('METADBIAS_OPENMMPLATFORM')
platform = Platform.getPlatformByName(platform_name)
properties = {}
properties["Precision"] = "mixed"

simulation = Simulation(prmtop.topology, system, integrator,platform, properties)
print ("Using platform %s" % simulation.context.getPlatform().getName())
simulation.context.setPositions(inpcrd.positions)
if inpcrd.boxVectors is not None:
    simulation.context.setPeriodicBoxVectors(*inpcrd.boxVectors)

print( "LoadState ...")
simulation.loadState(jobname + '_0.xml')


#    12000000
totalSteps = int(keywords.get('METADBIAS_NUMMDSTEPS'))
nprnt = int(keywords.get('METADBIAS_PRINTFREQUENCY'))

if totalSteps > 0:
    simulation.reporters.append(StateDataReporter(stdout, nprnt, step=True, potentialEnergy = True, temperature=True))
    simulation.reporters.append(DCDReporter(jobname + '_' + bias_id + '.dcd', nprnt))
    metaD.step(simulation, totalSteps)

    simulation.saveState(jobname + '_' + bias_id + '.xml')
    positions = simulation.context.getState(getPositions=True).getPositions()
    boxsize = simulation.context.getState().getPeriodicBoxVectors()
    simulation.topology.setPeriodicBoxVectors(boxsize)
    with open(jobname + '_' + bias_id + '.pdb', 'w') as output:
        PDBFile.writeFile(simulation.topology, positions, output)

f = open('free_energy_' + bias_id + '.dat', 'w')
if ndim == 1:
    y = metaD.getFreeEnergy()
    x = np.linspace(-180, 180, num=len(y))
    for i in range(len(y)):
        print(x[i], y[i], file = f)
elif ndim == 2:
    z = metaD.getFreeEnergy()
    (ny,nx) = z.shape
    x = np.linspace(-180, 180, num=nx)
    y = np.linspace(-180, 180, num=ny)
    for i in range(ny): #y
        for j in range(nx): #x
            print(x[j], y[i], z[i,j],file = f)
        print(file=f)

f.close()
    

end=datetime.now()
elapsed=end - start
print("elapsed time="+str(elapsed.seconds+elapsed.microseconds*1e-6)+"s")

