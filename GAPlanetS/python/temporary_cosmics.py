from astropy.io import fits
import numpy as np

def remove_cosmics():
    hdulist = fits.open("Cont_clip451_flat_reg_circsym.fits")
    Cont_cube = hdulist[0].data
    hdulist.close()
    hdulist = fits.open("Line_clip451_flat_reg_circsym.fits")
    Line_cube = hdulist[0].data
    hdulist.close()
    hdulist = fits.open("cosmic_arr_Ha.fits")
    line_cosmics = hdulist[0].data
    hdulist.close()
    hdulist = fits.open("cosmic_arr_Cont.fits")
    cont_cosmics = hdulist[0].data
    hdulist.close()
    hdulist = fits.open("rotoff_preproc.fits")
    rotoff_line = hdulist[0].data
    rotoff_cont = rotoff_line
    hdulist.close()
    
    marker = 0
    count = 0
    for a in range(Cont_cube.shape[0]):
        if not a in cont_cosmics:
            rotoff_cont = np.delete(rotoff_cont,a-count)
            count = count+1
        if a in cont_cosmics:
            print("beginning cube with layer " + str(a))
            new_cont = Cont_cube[a]
            marker = a
            break;
    for a in range(marker+1,Cont_cube.shape[0]):
        if not a in cont_cosmics:
            rotoff_cont = np.delete(rotoff_cont,a-count)
            count = count+1
        if a in cont_cosmics:
            print("Adding layer " +str(a))
            if(new_cont.shape[0]==451):
                new_cont = np.vstack(([new_cont],[Cont_cube[a]]))
            else:
                new_cont = np.vstack((new_cont,[Cont_cube[a]]))
                
    marker = 0
    count = 0
    for a in range(Line_cube.shape[0]):
        if not a in line_cosmics:
            rotoff_line = np.delete(rotoff_line,a-count)
            count = count+1
        if a in line_cosmics:
            print("beginning cube with layer " + str(a))
            new_line = Line_cube[a]
            marker = a
            break;
    for a in range(marker+1,Line_cube.shape[0]):
        if not a in line_cosmics:
            rotoff_line = np.delete(rotoff_line,a-count)
            count = count+1
        if a in line_cosmics:
            print("Adding layer " +str(a))
            if(new_line.shape[0]==451):
                new_line = np.vstack(([new_line],[Line_cube[a]]))
            else:
                new_line = np.vstack((new_line,[Line_cube[a]]))
            
    print("Writing to fits files.")    
    fits.writeto('Cont_clip451_flat_reg_circsym_nocosmics.fits', new_cont, overwrite = True)
    fits.writeto('Line_clip451_flat_reg_circsym_nocosmics.fits', new_line, overwrite = True)
    fits.writeto('rotoff_nocosmics_cont.fits', rotoff_cont, overwrite = True)
    fits.writeto('rotoff_nocosmics_line.fits', rotoff_line, overwrite = True)