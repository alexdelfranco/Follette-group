;+
; NAME: visao_removecosmics
;
; PURPOSE:
;  allows user to reject images with cosmic rays and creates new image and rotoff cubes without the rejected images. also writes out an array 
;  specifying which indices in original sequence contain cosmics. 
;
; INPUTS:
; fname: string file name of image cube that will be used to identify cosmic rays without the .fits suffix
; namestr: final file will be named with suffix _no+namestr+cosmics.fits. can be blank, but should generally be 'ha' or 'cont'
;
; OUTPUTS:
;
; OUTPUT KEYWORDS:
;    none
;
; EXAMPLE:
;
;
; HISTORY:
;  Written 2015 by Kate Follette, kbf@stanford.edu
;  07-29-2016 KBF. Revied to read a more generic set of image cubes.
;     Added all keyword and genericized to find and appy to any circsym cube
;-

pro visao_removecosmics, fname, namestr=namestr, stp=stp

  if not keyword_set(namestr) then begin
    print, "pleaase specify a name string. For example Line or Cont"
    stop
  endif

  ;;read in image (should be SDI)
  im=readfits(string(fname)+'.fits', imhead)
  zdim=(size(im))[3]
  print, zdim

  ds9_imselect, im, index=idx

  writefits, string(fname)+'_nocosmics.fits', im, imhead
  writefits, namestr+'cosmics.fits', idx

  ;; cull rotoff cube as well
  rotoffs=readfits('rotoff_preproc.fits', rothead)
  rotoffs_noc=dblarr(n_elements(idx))

  for i=0, n_elements(idx)-1 do begin
    rotoffs_noc[i]=rotoffs[idx[i]]
  endfor

  writefits, 'rotoff_no'+namestr+'cosmics.fits', rotoffs_noc, rothead

  print, 'rejected', zdim-n_elements(idx), 'cosmics'

  if keyword_set(stp) then  stop

end
