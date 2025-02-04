pro visao_reg_medcircsym, Line_cent, Cont_cent, mask=mask, clip=clip, fits=fits, sdi=sdi, rmax=rmax, indiv=indiv

;;finds center of circular symmetry of median combinations of registered images, and shifts this center to the center of the image cube

if keyword_set(clip) then Line=readfits('Line_clip'+string(clip,format='(i03)')+'_flat_reg.fits', Linehead) $
  else Line=readfits('Line_reg.fits')

  if keyword_set(clip) then Cont=readfits('Cont_clip'+string(clip,format='(i03)')+'_flat_reg.fits', Conthead) $
else Cont=readfits('Cont_reg.fits')  
  
  Linemed=median(Line, dim=3)
  Contmed=median(Cont, dim=3)
  
 dim1=(size(Line))[1]
 dim2=(size(Line))[2]
  
; xr=indgen(dim1/2.+1)-dim1/4.
; yr=indgen(dim2/2.+1)-dim2/4.
xr=indgen(51.)-50/2.
yr=indgen(51.)-50/2.

if keyword_set(rmax) then lim=rmax else lim=dim1/2.
 
if keyword_set(mask) then begin
  center_circlesym, Linemed, xr, yr, lim, Line_xc, Line_yc, Line_grid, mask=mask
  center_circlesym, Contmed, xr, yr, lim, Cont_xc, Cont_yc, Cont_grid, mask=mask
endif else begin
  center_circlesym, Linemed, xr, yr, lim, Line_xc, Line_yc, Line_grid
  center_circlesym, Contmed, xr, yr, lim, Cont_xc, Cont_yc, Cont_grid
endelse


Line_shift=[(dim1-1)/2.-Line_xc,(dim2-1)/2.-Line_yc]
Cont_shift=[(dim1-1)/2.-Cont_xc,(dim2-1)/2.-Cont_yc]
avg_shift=(Line_shift+Cont_shift)/2.

print, 'center of circular symmetry for Line image is', Line_xc, Line_yc
print, 'shifting Line image by', Line_shift
print, 'center of circular symmetry for Continuum image is', Cont_xc, Cont_yc
print, 'shifting Continuum image by', Cont_shift
nims=(size(Line))[3]

Line_cent=dblarr(dim1, dim2, nims)
Cont_cent=dblarr(dim1, dim2, nims)
if keyword_set(sdi) then begin
  if keyword_set(clip) then begin
    SDI1=readfits('SDI_sc'+string(sdi, format='(f05.2)')+'_clip'+string(clip, format='(i03)')+'_reg.fits')
    SDI2=readfits('SDI_sc'+string(1, format='(f05.2)')+'_clip'+string(clip, format='(i03)')+'_reg.fits')  
  endif else begin
    SDI1=readfits('SDI_sc'+string(sdi, format='(f05.2)')+'_reg.fits')
    SDI2=readfits('SDI_sc'+string(1, format='(f05.2)')+'_reg.fits') 
  endelse
  SDI1_cent=dblarr(dim1,dim2,nims)
  SDI2_cent=dblarr(dim1,dim2,nims)
endif

for i=0, nims-1 do begin
   Line_cent[*,*,i]=shift_interp(Line[*,*,i], Line_shift, spline=-0.5)
   Cont_cent[*,*,i]=shift_interp(Cont[*,*,i], Cont_shift, spline=-0.5)
   if keyword_set(sdi) then begin
      SDI1_cent[*,*,i]=shift_interp(SDI1[*,*,i], avg_shift, spline=-0.5)
      SDI2_cent[*,*,i]=shift_interp(SDI2[*,*,i], avg_shift, spline=-0.5)
   endif
endfor

if keyword_set(fits) then begin
 if keyword_set(clip) then begin
  writefits, 'Line_clip'+string(clip, format='(i03)')+'_flat_reg_medcircsym.fits', Line_cent, Linehead
  writefits, 'Cont_clip'+string(clip, format='(i03)')+'_flat_reg_medcircsym.fits', Cont_cent, Conthead
    if keyword_set(sdi) then begin
      writefits, 'SDI_sc'+string(sdi, format='(f05.2)')+'_clip'+string(clip, format='(i03)')+'_flat_reg_medcircsym.fits',SDI1_cent
      writefits, 'SDI_sc'+string(1, format='(f05.2)')+'_clip'+string(clip, format='(i03)')+'_flat_reg_medcircsym.fits',SDI2_cent
    endif
 endif else begin
  writefits, 'Line_flat_reg_medcircsym.fits', Line_cent, Linehead
  writefits, 'Cont_flat_reg_medcircsym.fits', Cont_cent, Conthead
  if keyword_set(sdi) then begin
    writefits, 'SDI_sc'+string(sdi, format='(f05.2)')+'_flat_reg_medcircsym.fits',SDI1_cent
    writefits, 'SDI_sc'+string(1, format='(f05.2)')+'_flat_reg_medcircsym.fits',SDI2_cent
  endif
 endelse
endif
 
;stop
end