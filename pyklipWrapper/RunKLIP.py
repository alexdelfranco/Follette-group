##################################################################
#############                                        #############
#############                 IMPORTS                #############
#############                                        #############
##################################################################

import glob
import inspect
import os
import pyklip.instruments.MagAO as MagAO
import pyklip.parallelized as parallelized
import numpy as np
import sys
import pyklip.klip as klip
from astropy.io import fits
import warnings
from astropy.utils.exceptions import AstropyWarning
import SNRMap_new as snr

warnings.filterwarnings('ignore', category=AstropyWarning, append=True)


##################################################################
#############                                        #############
#############               SAVE FILES               #############
#############                                        #############
################################################################## 
 
def writeData(indiv, hdr, snrmap = False, pre = ''):
    #function writes out fits files and writes important information to fits headers
    
    #hdu = fits.PrimaryHDU(indiv)
    #hdulist = fits.HDUList([hdu])
    #hdr = prihdr
 

    #shortens file path to bottom 4 directories so it will fit in fits header
    try:
        pathToFiles_short = '/'.join(pathToFiles.split(os.path.sep)[-4:])
    except:
        pathToFiles_short = pathToFiles
            
    #adds info to fits headers
    hdr.set('annuli', str(annuli))
    hdr.set('movement', str(movement))
    hdr.set('subsctns', str(subsections))
    hdr.set('klmodes', str(klmodes))
    hdr.set('filepath', str(pathToFiles_short))
 
    if(snrmap):
        hdr.set('mask_rad', str(ra))
        hdr.set('mask_pa', str(pa))
        hdr.set('mask_wid', str(wid))
        hdr.set('smooth_val', str(_smooth))
        hdr.set('FWHM', str(FWHM))
   
    #hdulist[0].header = hdr
    #writes out files
    fits.writeto(str(pathToFiles) + "_klip/" + str(pre)  + outputFileName + "_a" + str(annuli) + "m" + str(movement) +
                 "s" + str(subsections) + "iwa" + str(iwa) + '_klmodes-all.fits', indiv, hdr, overwrite=True)


    

##################################################################
#############                                        #############
#############         GET INPUTS FROM GUI            #############
#############                                        #############
################################################################## 

#value adjusts argument numbering in case of white space in file path 
argnum = 0

pathToFiles = sys.argv[1]

#if the file path has white space in it, recognizes the end of the filepath by the phrase '%finish'
#If the phrase '%finish' does not occur, leaves pathToFiles as the first argument

print("KLIP Parameters:")
try:
    while (not pathToFiles[-7:] == '%finish'):
        argnum += 1
        pathToFiles = pathToFiles + " " + sys.argv[1+argnum]
    pathToFiles = pathToFiles[:-7]
        
except:
    pathToFiles = sys.argv[1]
    argnum = 0

print("  File Path = " + pathToFiles) 

if not os.path.exists(pathToFiles + "_klip"):
    os.makedirs(pathToFiles + "_klip")
    os.chmod(pathToFiles + "_klip", 0o777)

iwa = int(sys.argv[2+argnum])
print("  IWA = " + str(iwa))

klmodes = list(map(int, sys.argv[3+argnum].split(",")))
print("  KL Modes = " + str(list(map(int, sys.argv[3+argnum].split(",")))))

annuli = int(sys.argv[4+argnum])
print("  Annuli = " + str(annuli))

movement = float(sys.argv[5+argnum])
print("  Movement = " + str(movement))

subsections = int(sys.argv[6+argnum])
print("  Subsections = " + str(subsections))

outputFileName = sys.argv[7+argnum]     
  
highpass = False
if (sys.argv[8+argnum] == 'true' or sys.argv[8+argnum] == 'True'):
    highpass = True     
    
saveData = False
if (sys.argv[9+argnum] == 'true' or sys.argv[9+argnum] == 'True'):
    saveData = True  
    
SNR = False
if (sys.argv[10+argnum] == 'true' or sys.argv[10+argnum] == 'True'):
    SNR = True
    
maskParams = None
ra = 'none'
pa = 'none'
wid = 'none'

if (SNR):
    try: 
        FWHM = float(sys.argv[11+argnum])
        _smooth = float(sys.argv[12+argnum])
        print()
        print("SNR Map Parameters:")
        print('  Star FWHM = ' + str(FWHM))
        print('  Smoothing value = ' + str(_smooth))
        ra = list(map(int, sys.argv[13+argnum].split(",")))
        pa = list(map(int, sys.argv[14+argnum].split(",")))
        wid = list(map(int, sys.argv[15+argnum].split(",")))
        maskParams = (ra, pa, wid)
        print('  Planet mask parameters:')
        print("    Radius = " + str(ra))
        print("    Position Angle = " + str(pa))
        print("    Mask width (radial, angular): = " + str(wid))
        
    except:
        print("Planet mask parameters not specified or incorrectly specified")
        


    
##################################################################
#############                                        #############
#############                 RUN KLIP               #############
#############                                        #############
##################################################################
#grab header
hdr = fits.getheader(pathToFiles + '/sliced_1.fits')
hdr['rotoff'] = None


print()
print("Reading: " + pathToFiles + "/*.fits")
filelist = glob.glob(pathToFiles + '/*.fits')

dataset = MagAO.MagAOData(filelist)
#set iwa
dataset.IWA = iwa

print()
print("Starting KLIP")


#run klip for given parameters
parallelized.klip_dataset(dataset, outputdir=(pathToFiles + "_klip/"), fileprefix= ('mean_' + str(outputFileName)), annuli=annuli,
                          subsections=subsections, movement=movement, numbasis=klmodes, calibrate_flux=False, mode="ADI",
                          highpass = highpass, time_collapse='median')
           
#cube to hold median combinations of klipped images
#dim = dataset.output.shape[3]

#cube = np.zeros((len(klmodes),dim,dim))
            
#flips images
#print("Now flipping KLIPed images")
#dataset.output = dataset.output[:,:,:,::-1]
      
if (saveData):
    print("Writing KLIPed time series 4D cube to " + pathToFiles + "_klip")
    writeData(dataset.output, hdr, pre = "uncombined_")

#collapse KLIP output cube in time dimension
cube = np.nanmedian(dataset.output, axis=(1,2))
#print(cube.shape)

if (SNR):
     SNRcube, snrs, snrsums, snr_spurious = snr.create_map(cube, FWHM, smooth = _smooth, planets = maskParams, saveOutput = False)
        
#write median combination cube to disk 
print()
print("Writing median KLIPed images to " + pathToFiles + "_klip")
writeData(cube, hdr, pre = "med_")

  
if (SNR):
    print("Writing SNR maps to " + pathToFiles + "_klip")
    writeData(SNRcube, hdr, snrmap = True, pre = "snrmap_")


print()
print("KLIP completed")        

  
     
            





