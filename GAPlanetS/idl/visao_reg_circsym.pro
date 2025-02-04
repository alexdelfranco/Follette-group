;+
; NAME: visao_reg_circsym
;
; PURPOSE:
;  separate, register and align all of the raw science images and create an image cube
;
; INPUTS:
;  sci_imlist :
;
; INPUT KEYWORDS:
;  clip     :  crops the array to specified width (square)
;  scl      :  rescale the continuum images by this factor
;  msk      :  radius of saturated region to mask at center of PSF in pixels
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
;  Written 2017-08-15 based heaviy on the existing visao_reg and visao_circsym routines
;
;-

pro visao_reg_circsym, clip=clip, flat=flat, fwhm=fwhm, indiv=indiv, scl=scl, stp=stp, reg=reg, mask=mask

  if keyword_set(flat) then namestr='_flat_' else namestr='_'


  if not keyword_set(reg) then begin
    ;; if reg keyword not set, read in channel cubes from visao_separate_sdi, which are dark subtracted and flat fielded
    if not keyword_set(indiv) then begin
      Line=readfits('Line'+string(namestr)+'preproc.fits', Linehead)
      Cont=readfits('Cont'+string(namestr)+'preproc.fits', Conthead)

    endif

    if keyword_set(indiv) then begin
      spawn, 'ls indiv/Line* | wc -l', nims
      nims=long(nims[0])
    endif

  endif else begin
    if not keyword_set(clip) then print, 'must set clip keyword with reg keyword'
    Line = readfits('Line_clip'+string(clip, format='(i03)')+string(namestr)+'reg.fits', Linehead)
    Cont = readfits('Cont_clip'+string(clip, format='(i03)')+string(namestr)+'reg.fits', Conthead)
  endelse

  dim1 = (size(Line))[1]
  dim2 = (size(Line))[2]

  xcen=(dim1-1)/2.
  ycen=(dim2-1)/2.

  if not keyword_set(indiv) then nims=(size(Line))[3]

  ;;if clip keyword not defined (not recommended), image size is full array (10254x512)
  if not keyword_set(clip) then clip=dim1

  ;;create blank arrays
  if not keyword_set(indiv) then begin
    cubedim=nims
  endif else begin
    cubedim=1
  endelse

  Line_smooth=dblarr(dim1, dim2, cubedim)
  Cont_smooth=dblarr(dim1, dim2, cubedim)
  Line_reg=dblarr(clip, clip, nims)
  Cont_reg=dblarr(clip, clip, nims)

  peak_ratio=dblarr(nims)
  expt=dblarr(nims)
  Line_max_coords=dblarr(2,nims)
  Cont_max_coords=dblarr(2,nims)
  Line_shift_arr=dblarr(2,nims)
  Cont_shift_arr=dblarr(2,nims)

  ;; PSF for finding star in each image
  if not keyword_set(fwhm) then fwhm=10
  gauss_cen=psf_gaussian(npixel=[dim1, dim2], centroid=[(dim1-1)/2., (dim2-1)/2.], FWHM=fwhm)

  ;;image loop
  for i=0, nims-1 do begin

    if keyword_set(indiv) then begin
      Line=readfits('./indiv/Line'+string(namestr)+string(i+1, format='(i04)')+'.fits', Linehead)
      Cont=readfits('./indiv/Cont'+string(namestr)+string(i+1, format='(i04)')+'.fits', Conthead)
      j=0
    endif else begin
      j=i
    endelse

    ;smooth out cosmic rays
    Line_smooth[*,*,j]=gauss_smooth(Line[*,*,j], width=fwhm)*1.
    Cont_smooth[*,*,j]=gauss_smooth(Cont[*,*,j], width=fwhm)*1.

    ;; calculate approximate offset by registering against gaussian via Fourier cross-correlation, but don't shift
    ;; note just finding the max after smoothing doesn't work for faint sources
    subreg, gauss_cen, Line_smooth[*,*,j], sft, method='F'
    ;stop

    ;; do line image first
    ;make 51x51 grid around max coords
    xr=indgen(51.)-50/2.-sft[0]
    ;; line below is
    yr=indgen(51.)-50/2.-sft[1]

    rmax=25

    ;; calculate center of circular symmetry in this region
    if keyword_set(mask) then begin
      ;print, 'masked'
      center_circlesym, Line[*,*,j], xr, yr, rmax, Line_xc, Line_yc, Line_grid, mask=mask
    endif else begin
      center_circlesym, Line[*,*,j], xr, yr, rmax, Line_xc, Line_yc, Line_grid
    endelse

    ;; record shifts as a check
    Line_shift=[(dim1-1)/2.-Line_xc,(dim2-1)/2.-Line_yc]
    Line_shift_arr[*,j]=Line_shift

    nims=(size(Line))[3]
    print, 'center of circular symmetry for Line image is', Line_xc, Line_yc
    print, 'shifting Line image', j+1, ' of', nims, ' by', Line_shift

    ;Line[*,*,j]=shift_interp(Line[*,*,j], Line_shift-1, spline=-0.5) old ver. - based on bug in Fourier cx correlation
    Line[*,*,j]=shift_interp(Line[*,*,j], Line_shift, spline=-0.5)

    ;now the same for the continuum image
    subreg, gauss_cen, Cont_smooth[*,*,j], sft, method='F'
    ;stop

    ;make 71x71 grid around max coords
    xr=indgen(51.)-50/2.-sft[0]
    ;; line below is
    yr=indgen(51.)-50/2.-sft[1]

    rmax=25

    ;; calculate center of circular symmetry in this region
    if keyword_set(mask) then begin
      print, 'masked'
      center_circlesym, Cont[*,*,j], xr, yr, rmax, Cont_xc, Cont_yc, Cont_grid, mask=mask
    endif else begin
      center_circlesym, Cont[*,*,j], xr, yr, rmax, Cont_xc, Cont_yc, Cont_grid
    endelse

    ;; record shifts as a check
    Cont_shift=[(dim1-1)/2.-Cont_xc,(dim2-1)/2.-Cont_yc]
    Cont_shift_arr[*,j]=Cont_shift

    nims=(size(Cont))[3]
    print, 'center of circular symmetry for Line image is', Cont_xc, Cont_yc
    print, 'shifting Continuum image', j+1, 'of', nims, 'by', Cont_shift

    ;Cont[*,*,j]=shift_interp(Cont[*,*,j], Cont_shift-1, spline=-0.5) old ver. - based on bug in Fourier cx correlation
    Cont[*,*,j]=shift_interp(Cont[*,*,j], Cont_shift, spline=-0.5)



    ;;rescale continuum image by scl if keyowrd is set
    if keyword_set(scl) then begin
      Cont[*,*,j]=rot(Cont[*,*,j],0.,scl,cubic=-0.5)
    endif

    ;;clip may overshoot edge of frame in some images. Adjust clip to be smaller in these cases

    ;;Line adjustments to clip
    if dim1/2-abs(Line_shift[0]) lt clip/2 then begin
      print, 'Line overshoots by', dim1/2-abs(Line_shift[0])-clip/2, 'pixels in x'
      Line_cropx=floor(dim1/2-abs(Line_shift[0]))
    endif else begin
      Line_cropx=clip/2
    endelse
    if dim2/2-abs(Line_shift[1]) lt clip/2 then begin
      print, 'Line overshoots by', dim2/2-abs(Line_shift[1])-clip/2, 'pixels in y'
      Line_cropy=floor(dim2/2-abs(Line_shift[1]))
    endif else begin
      Line_cropy=clip/2
    endelse

    ;;Cont adjustments to clip
    if dim1/2-abs(Cont_shift[0]) lt clip/2 then begin
      print, 'Cont overshoots by', dim1/2-abs(Cont_shift[0])-clip/2, 'pixels in x'
      Cont_cropx=floor(dim1/2-abs(Cont_shift[0]))
    endif else begin
      Cont_cropx=clip/2
    endelse
    if dim2/2-abs(Cont_shift[1]) lt clip/2 then begin
      print, 'Cont overshoots by', dim2/2-abs(Cont_shift[1])-clip/2, 'pixels in y'
      Cont_cropy=floor(dim2/2-abs(Cont_shift[1]))
    endif else begin
      Cont_cropy=clip/2
    endelse
    ;stop
    Line_reg[clip/2-Line_cropx:clip/2+Line_cropx-1,clip/2-Line_cropy:clip/2+Line_cropy-1,i]= $
      Line[xcen-Line_cropx+1:xcen+Line_cropx,ycen-Line_cropy+1:ycen+Line_cropy,j]
    Cont_reg[clip/2-Cont_cropx:clip/2+Cont_cropx-1,clip/2-Cont_cropy:clip/2+Cont_cropy-1,i]= $
      Cont[xcen-Cont_cropx+1:xcen+Cont_cropx, ycen-Cont_cropy+1:ycen+Cont_cropy,j]

    ;;if clip is odd number, then need to shift by 0.5 to get to center of array. VisAO chip channels
    ;are even numbered, so it's expected that the center of the star will be between two pixels
    if clip/2. mod 1 gt 0 then begin
      Line_reg[*,*,i]=shift_interp(Line_reg[*,*,i], [0.5, 0.5], spline=-0.5)
      Cont_reg[*,*,i]=shift_interp(Cont_reg[*,*,i], [0.5, 0.5], spline=-0.5)
    endif

    print, 'processed image', i+1, '        of', nims
    ;stop

  endfor

  ;;add parameters to headers
  sxaddpar, Linehead, 'CLIP', clip

  if keyword_set(mask) then begin
    sxaddpar, Linehead, 'MASK', mask
  endif
  sxaddpar, Linehead, 'SMOOTH_FWHM', fwhm
  
  sxaddpar, Conthead, 'CLIP', clip
  if not keyword_set(scl) then scl=1
  sxaddpar, Conthead, 'CONT_SCALE', scl
  if keyword_set(mask) then begin
    sxaddpar, Conthead, 'MASK', mask
  endif
  sxaddpar, Conthead, 'SMOOTH_FWHM', fwhm

  print, 'median line shift was', median(Line_shift_arr[0,*]), median(Line_shift_arr[1,*])
  print, 'median cont shift was', median(Cont_shift_arr[0,*]), median(Cont_shift_arr[1,*])
  print, 'standard deviation of line shifts was', stddev(Line_shift_arr[0,*]), stddev(Line_shift_arr[1,*])
  print, 'standard deviation of cont shifts was', stddev(Cont_shift_arr[0,*]), stddev(Cont_shift_arr[1,*])

  sxaddpar, Linehead, 'XSHIFT_MED',  median(Line_shift_arr[0,*])
  sxaddpar, Linehead, 'YSHIFT_MED',  median(Line_shift_arr[1,*])
  sxaddpar, Linehead, 'XSHIFT_STD',  stddev(Line_shift_arr[0,*])
  sxaddpar, Linehead, 'YSHIFT_STD',  stddev(Line_shift_arr[1,*])  

  sxaddpar, Conthead, 'XSHIFT_MED',  median(Cont_shift_arr[0,*])
  sxaddpar, Conthead, 'YSHIFT_MED',  median(Cont_shift_arr[1,*])
  sxaddpar, Conthead, 'XSHIFT_STD',  stddev(Cont_shift_arr[0,*])
  sxaddpar, Conthead, 'YSHIFT_STD',  stddev(Cont_shift_arr[1,*])

  ;; write files
  if keyword_set(clip) then begin
    writefits, 'Line_clip'+string(clip, format='(i03)')+string(namestr)+'circsymreg.fits', Line_reg, Linehead
    writefits, 'Cont_clip'+string(clip, format='(i03)')+string(namestr)+'circsymreg.fits', Cont_reg, Conthead
  endif else begin
    writefits, 'Line'+string(namestr)+'circsymreg.fits', Line_reg, Linehead
    writefits, 'Cont'+string(namestr)+'circsymreg.fits', Cont_reg, Conthead
  endelse

  if keyword_set(stp) then  stop

  writefits, 'Line_cicrsym_shifts.fits', Line_shift_arr
  writefits, 'Cont_cicrsym_shifts.fits', Cont_shift_arr
  
  print, 'registration complete'

end
