pro plotsed, flux, band, rxtef=rxtef, radflux=fluxrad, radfreq=freqrad, $
             ps=ps, fname=namef, plote=plote, vfv=vfv, opltsed=opltsed, $
             mjd=omjd, yrn=nyr, xrn=nxr, strip=strip, fixind=fixind, $
             Tin=inT, res=R, crflxtxt=crflxtxt

;This program plots SED of given fluxes in given bands. IF rxte
;spectra file output is given, it also plots RXTE data. Similarly if
;radio flux and frequency are provided, they are also plotted

;INPUTS
;
; flux: flux of OIR in different bands, with errors (fltarr(2,nbands))
; band: bands are given as an array of string and will be converted to
;       frequency or energy in the program
;
;OUTPUTS
;
; A plot of the SED
;
; OPTIONAL INPUTS
;
; rxtef: the output of iplot in terms of pl euf?, to be implemented
;        later
; radflux: radio fluxes in mJy and errors
; radfreq: radio frequencies
; opltsed : if set fit the OIR data with a BB and overplot the fit
; mjd: if given, print the MJD on the plot
; res: result structure from the fit
; 
; ps: postscript output
; fname: optional name of the postscript output
; plote: x axis in eV instead of frequency
; vfv: nu - f - nu plot, multiply fluxes by frequencies
; yrn: new yrange
; strip: if set, part of another plotting program
; Tin: initial parameter for blackbody temperature
; fixind: IF set. fix the index of radio spectrum
; crflxtxt: IF set, create a txt file that will be input to flx2xsp
; LOGS
;
; Created by E. Kalemci Feb 22, 2015
;
; Bunch of changes April 4:
;
; FIXED a problem with plotting radio fluxes, when an upper limit is
;present, now it plots an arrow
; 
; ADDED opltbb option to overplot bb
;
; FIXED wrong syntax in ploterror, added charsize
;
; ADDED mjd keyword.
;
; ADDED a script to write down flux densities in a text file to be
;used with flx2xsp
;
; fixed a syntax error about nnu
;
; Jan 30 2016 fixed problems about crflxtxt
; changed magic number 0.08 to fixed index of 0 as flat spectrum
;

IF NOT keyword_set(ps) THEN ps=0
IF NOT keyword_set(namef) THEN namef='sed.eps'
IF NOT keyword_set(plote) THEN plote=0
IF NOT keyword_set(vfv) THEN vfv=0
IF NOT keyword_set(opltbb) THEN opltbb=0
IF NOT keyword_set(strip) THEN strip=0
IF NOT keyword_set(crflxtxt) THEN crflxtxt=0

indf=0. ;fixed index is flat spectrum.... think about this later

IF NOT keyword_set(nxr) THEN BEGIN
   IF plote THEN nxr=[4e-6, 2.6] ELSE nxr=[1E9,1E15]
ENDIF

IF NOT keyword_set(inT) THEN inT=8000.
IF NOT keyword_set(fixind) THEN fixind=0

IF NOT strip THEN BEGIN
   IF ps THEN BEGIN
      set_plot, 'ps'
      device,/color
;   loadct,5
      device,/encapsulated
      device, filename = namef
      device, yoffset = 2
      device, ysize = 14.
                                ;device, xsize = 12.0
      !p.font=0
      device,/times
   ENDIF ELSE window, 4, retain=2, xsize=800, ysize=800
ENDIF

;Need to merge all given fluxes in different bands

nu=fltarr(2,n_elements(band))
wave=fltarr(n_elements(band))
FOR i=0, n_elements(band)-1 DO BEGIN

CASE band[i] OF

   'J': BEGIN
      Jlam=1.25e-6*100. ;cm
      wave[i]=Jlam*1E8
      frJ=3e10/Jlam
      frerr=(1.325-1.166)/(2.*1.25) ;um
      nu[0,i]=frJ
      nu[1,i]=frJ*frerr
   END

;dino

   'H': BEGIN
      Hlam=1.65e-6*100. ;cm
      wave[i]=Hlam*1E8
      frH=3e10/Hlam
      frerr=(1.780-1.486)/(2.*1.65)
      nu[0,i]=frH
      nu[1,i]=frH*frerr
      END

   'K': BEGIN
      Klam=2.2e-6*100. ;cm
      wave[i]=Klam*1E8
      frK=3e10/Klam
      frerr=(2.284-1.996)/(2.*2.2)
      nu[0,i]=frK
      nu[1,i]=frK*frerr
   END

   'B': BEGIN
      Blam=0.44e-6*100. ;cm
      wave[i]=Blam*1E8
      frB=3e10/Blam
      frerr=(50./440.) ;nm
      nu[0,i]=frB
      nu[1,i]=frB*frerr
   END

   'V': BEGIN
      Vlam=0.545e-6*100. ;cm
      wave[i]=Vlam*1E8
      frV=3e10/Vlam
      frerr=(50./545.) ;nm
      nu[0,i]=frV
      nu[1,i]=frV*frerr
   END

;   'R': BEGIN
;      Jlam=1.25e-6*100. ;cm
;      frJ=3e10/Jlam
;      nu[0,i]=frJ
;   END

   'I': BEGIN
      Ilam=0.798e-6*100. ;cm
      wave[i]=Ilam*1E8
      frI=3e10/Ilam
      frerr=(90./798.);
      nu[0,i]=frI
      nu[1,i]=frI*frerr
   END

ENDCASE

ENDFOR

h=4.136D-15             ;eV s
nuall=nu 
enall=h*nu
fluxall=flux

nel=0
IF keyword_set(fluxrad) THEN BEGIN
   nel=N_ELEMENTS(freqrad)
   nuall=fltarr(2,i+nel)
   nuall[0,0:nel-1]=freqrad
   nuall[1,0:nel-1]=50*1e6 ;50 MHz
   nuall[*,nel:i+nel-1]=nu
   enall=fltarr(2,i+nel)
   enall[0,0:nel-1]=h*freqrad
   enall[1,0:nel-1]=h*50*1e6
   enall[*,nel:i+nel-1]=h*nu
   fluxall=fltarr(2,i+nel)
   fluxall[*,0:nel-1]=fluxrad
   fluxall[*,nel:i+nel-1]=flux
   wradio=1
ENDIF ELSE wradio=0

IF crflxtxt THEN BEGIN
   fils=file_search('.','forxspec*', count=nxfil)
   ;version 1
   openw, 1, 'forxspec'+strtrim(string(nxfil),1)+'.txt'
   srt=sort(nuall[0,*])
   FOR ni=0,(i+nel-1) DO BEGIN
      printf,1,strtrim(string(nuall[0,srt[ni]]-(nuall[1,srt[ni]]/2.)),1)+' '+$
             strtrim(string(nuall[0,srt[ni]]+(nuall[1,srt[ni]]/2.)),1)+' '+$
             strtrim(string(fluxall[0,srt[ni]]*1e-3),1)+' '+$
             strtrim(string(fluxall[1,srt[ni]]*1e-3),1)
      IF ni NE (i+nel-1) THEN $
         printf, 1, strtrim(string(nuall[0,srt[ni]]+(nuall[1,srt[ni]]/2.)),1)+' '+$
                 strtrim(string(nuall[0,srt[ni+1]]-(nuall[1,srt[ni+1]]/2.)),1)+' '+$
                 '0. 0.'
   ENDFOR
   close,1

   ;version 2
   IF wradio THEN BEGIN
        filsr=file_search('.','rforxspec*', count=nxfil)
        openw, 1, 'rforxspec'+strtrim(string(nxfil),1)+'.txt'
        srt=sort(nuall[0,0:nel-1])
        ;MAGIC NUMBERS! FIX THIS - THIS SEEMS INCORRECT, DO NOT USE
;        delf=freqrad
;        IF N_ELEMENTS(delf) GT 1 THEN BEGIN
;           FOR dind=1, N_ELEMENTS(delf)-1 DO delf[dind
        delf=[1.425,4.86-2*(1.425), (8.46-4.86)-(4.86-2*(1.425))]*1e-9
       FOR ni=0,nel-1 DO BEGIN
           printf,1,strtrim(string(nuall[0,srt[ni]]-delf[ni]),1)+' '+$
             strtrim(string(nuall[0,srt[ni]]+delf[ni]),1)+' '+$
             strtrim(string(fluxall[0,srt[ni]]*1e-3),1)+' '+$
             strtrim(string(fluxall[1,srt[ni]]*1e-3),1)
        ENDFOR
     ENDIF
   close,1
   filsoi=file_search('.','oiforxspec*', count=nxfil)
   openw, 1, 'oiforxspec'+strtrim(string(nxfil),1)+'.txt'
   srt=sort(nuall[0,nel:i+nel-1])
   delf=[0.518,0.518,0.841,0.905,0408]*1e14
   nnu=[1.364,2.4,3.759,5.505,6.818]*1e14
   FOR ni=0,i-1 DO BEGIN
      IF (ni eq 0) THEN delf[ni]=(nuall[0,nel+srt[ni+1]]-nuall[0,nel+srt[ni]])/2. 
      IF (ni eq 1) THEN delf[ni]=delf[ni-1]
      IF ((ni GT 1) AND (ni LT (i-1))) THEN $
                      delf[ni]=(nuall[0,nel+srt[ni]]-nuall[0,nel+srt[ni-1]])-delf[ni-1]
      print, ni, srt[ni],delf[ni],nuall[0,nel+srt[ni]], 'ALOOOO'
      IF ni eq (i-1) THEN delf[ni]=(nuall[0,nel+i-1]-nuall[0,nel+i-2])-delf[ni-1]             
           printf,1,strtrim(string(nuall[0,nel+srt[ni]]-delf[ni]),1)+' '+$
             strtrim(string(nuall[0,nel+srt[ni]]+delf[ni]),1)+' '+$
             strtrim(string(fluxall[0,nel+srt[ni]]*1e-3),1)+' '+$
             strtrim(string(fluxall[1,nel+srt[ni]]*1e-3),1)
        ENDFOR
   close,1
ENDIF



IF keyword_set(rxtef) THEN BEGIN
   ;this part will be implemented later
ENDIF

IF opltsed THEN BEGIN 
   IF wradio THEN fit_plot_sed, band, flux, R, $
   rfreq=freqrad/1D9, rflux=fluxrad, Tin=inT, /noplt, $
   wradio=wradio, fixind=fixind ELSE $
     fit_plot_sed, band, flux, R, $
      Tin=inT, /noplt 
ENDIF


; now we can plot everything

xx=where(fluxall[1,*] NE -1)
yy=where(fluxall[1,*] EQ -1)

cs=1.2

IF vfv THEN BEGIN

   IF plote THEN BEGIN

   IF NOT keyword_set(nyr) THEN nyr=[1e-6,1e4]

IF strip THEN ploterror, enall[0,xx],enall[0,xx]*fluxall[0,xx],$
                 enall[1,xx],enall[0,xx]*fluxall[1,xx],$
                 /nohat,/xlog, /ylog, yr=nyr, xr=nxr, $
                  chars=cs , psym=1, /xstyle, /ystyle ELSE $
      ploterror, enall[0,xx],enall[0,xx]*fluxall[0,xx],$
                 enall[1,xx],enall[0,xx]*fluxall[1,xx],$
                 /nohat,/xlog, /ylog, xtitle='Energy (eV)', yr=nyr, $
                 ytitle='Energy x Flux (eV*mJy)', chars=cs , psym=1, $
                 xr=nxr, /xstyle, /ystyle
;weird units, fix later


      IF yy[0] NE -1 THEN BEGIN
         FOR k=0, N_ELEMENTS(yy)-1 DO BEGIN
            arrow, enall[0,yy[k]], enall[0,yy[k]]*fluxall[0,yy[k]],$
                   enall[0,yy[k]],10.^(!y.crange[0]),/data
            oplot,enall[0,yy[k]]+[-enall[1,yy[k]],enall[1,yy[k]]],$
               [enall[0,yy[k]]*fluxall[0,yy[k]],enall[0,yy[k]]*fluxall[0,yy[k]]]   
         ENDFOR
      ENDIF

      IF opltsed THEN BEGIN
         oplot,h*R.freqs, R.fitres1*(h*R.freqs)
         IF wradio THEN BEGIN
            IF fixind THEN BEGIN
                oplot, h*R.freqs, R.freqs*(R.R1[0,0]*planckf(R.freqs,R.R1[0,1])), $
                       line=1
                oplot, h*R.freqs, R.freqs*(R.R1[0,2]*R.freqs^(indf)), line=1
             ENDIF ELSE BEGIN
                oplot, h*R.freqs, R.freqs*(R.R1[0,0]*planckf(R.freqs,R.R1[0,1])), $
                       line=1
                oplot, h*R.freqs, R.freqs*(R.R1[0,2]*R.freqs^R.R1[0,3]), line=1
           ENDELSE
          ENDIF
      ENDIF

   ENDIF ELSE BEGIN

      IF NOT keyword_set(nyr) THEN nyr=[1e8,1e18]

IF strip THEN ploterror, nuall[0,xx],nuall[0,xx]*fluxall[0,xx], $
                 nuall[1,xx],nuall[0,xx]*fluxall[1,xx], psym=1, $
                         /nohat,/xlog, /ylog, charsize=cs, xr=nxr, $
                         /xstyle, /ystyle ELSE $
               ploterror, nuall[0,xx],nuall[0,xx]*fluxall[0,xx], $
                 nuall[1,xx],nuall[0,xx]*fluxall[1,xx], psym=1, xr=nxr, $
                         /nohat,/xlog, /ylog, xtitle='Frequency (Hz)',$
                         ytitle='Freq. x Flux (Hz x mJy)', charsize=cs, $
                          /xtyle, /ystyle

      IF yy[0] NE -1 THEN BEGIN
         FOR k=0, N_ELEMENTS(yy)-1 DO BEGIN
            arrow, nuall[0,yy[k]], nuall[0,yy[k]]*fluxall[0,yy[k]],$
                   nuall[0,yy[k]],10.^(!y.crange[0]),/data
            oplot,nuall[0,yy[k]]+[-nuall[1,yy[k]],nuall[1,yy[k]]],$
                  [nuall[0,yy[k]]*fluxall[0,yy[k]],nuall[0,yy[k]]*fluxall[0,yy[k]]]
         ENDFOR
      ENDIF

      IF opltsed THEN BEGIN
         oplot, R.freqs, R.fitres1*R.freqs
           IF wradio THEN BEGIN
            IF fixind THEN BEGIN
                oplot, R.freqs, R.freqs*(R.R1[0,0]*planckf(R.freqs,R.R1[0,1])), $
                       line=1
                oplot, R.freqs, R.freqs*(R.R1[0,2]*R.freqs^(indf)), line=1
             ENDIF ELSE BEGIN
                oplot, R.freqs, R.freqs*(R.R1[0,0]*planckf(R.freqs,R.R1[0,1])), $
                       line=1
                oplot, R.freqs, R.freqs*(R.R1[0,2]*R.freqs^R.R1[0,3]), line=1
           ENDELSE
          ENDIF
        ENDIF

   ENDELSE

ENDIF ELSE BEGIN

   IF NOT keyword_set(nyr) THEN nyr=[0.1,1000.]

   IF plote THEN BEGIN
      ;h=4.136D-18               ;keV s
      ;en=h*nu

     IF strip THEN ploterror, enall[0,xx],fluxall[0,xx],$
                 enall[1,xx],fluxall[1,xx], yr=nyr, xr=nxr, $
                 /nohat,/xlog, /ylog, psym=1, charsize=cs, $
                 /xstyle, /ystyle ELSE $
      ploterror, enall[0,xx],fluxall[0,xx],$
                 enall[1,xx],fluxall[1,xx], yr=nyr, xr=nxr, $
                 /nohat,/xlog, /ylog, psym=1, /xstyle, /ystyle, $
              xtitle='Energy (eV)', ytitle='Flux (mJy)', charsize=cs
      
      IF yy[0] NE -1 THEN BEGIN
         FOR k=0, N_ELEMENTS(yy)-1 DO BEGIN
            arrow, enall[0,yy[k]], fluxall[0,yy[k]],$
                   enall[0,yy[k]],10.^(!y.crange[0]),/data
            oplot,enall[0,yy[k]]+[-enall[1,yy[k]],enall[1,yy[k]]],$
                  [fluxall[0,yy[k]],fluxall[0,yy[k]]]
         ENDFOR
      ENDIF
  
      IF opltsed THEN BEGIN
         oplot, (h*R.freqs), R.fitres1
         IF wradio THEN BEGIN
            IF fixind THEN BEGIN
                oplot, h*R.freqs, (R.R1[0,0]*planckf(R.freqs,R.R1[0,1])), $
                       line=1
                oplot, h*R.freqs, (R.R1[0,2]*R.freqs^(indf)), line=1
             ENDIF ELSE BEGIN
                oplot, h*R.freqs, (R.R1[0,0]*planckf(R.freqs,R.R1[0,1])), $
                       line=1
                oplot, h*R.freqs, (R.R1[0,2]*R.freqs^R.R1[0,3]), line=1
           ENDELSE
          ENDIF
      ENDIF

 ENDIF ELSE BEGIN

    IF strip THEN ploterror, nuall[0,xx],fluxall[0,xx],nuall[1,xx],$
                             fluxall[1,xx], /nohat,/xlog, psym=1, yr=nyr, $
                             xr=nxr, /ylog, charsize=cs, $
                             /xstyle,  /ystyle   ELSE $
       ploterror, nuall[0,xx],fluxall[0,xx],nuall[1,xx],fluxall[1,xx],$
                         /nohat,/xlog, psym=1, yr=nyr, $
                         /ylog, xtitle='Frequency (Hz)', xr=nxr, $
                         ytitle='Flux (mJy)',charsize=cs, /xstyle, /ystyle
    IF yy[0] NE -1 THEN BEGIN
         FOR k=0, N_ELEMENTS(yy)-1 DO BEGIN
            arrow, nuall[0,yy[k]], fluxall[0,yy[k]],$
                   nuall[0,yy[k]],10.^(!y.crange[0]),/data
            oplot,nuall[0,yy[k]]+[-nuall[1,yy[k]],nuall[1,yy[k]]],$
                  [fluxall[0,yy[k]],fluxall[0,yy[k]]]
         ENDFOR
      ENDIF
    
     IF opltsed THEN BEGIN
        oplot, R.freqs, R.fitres1
        IF wradio THEN BEGIN
            IF fixind THEN BEGIN
                oplot, R.freqs, (R.R1[0,0]*planckf(R.freqs,R.R1[0,1])), $
                       line=1
                oplot, R.freqs, (R.R1[0,2]*R.freqs^(indf)), line=1
             ENDIF ELSE BEGIN
                oplot, R.freqs, (R.R1[0,0]*planckf(R.freqs,R.R1[0,1])), $
                       line=1
                oplot, R.freqs, (R.R1[0,2]*R.freqs^R.R1[0,3]), line=1
           ENDELSE
          ENDIF
        ENDIF
 ENDELSE
ENDELSE



;     IF keyword_set(omjd) THEN xyouts, 10.^(!x.crange[0]*1.02), 10.^(!y.crange[1]*0.95), omjd, size=1.2

 IF keyword_set(omjd) THEN BEGIN
    IF strip THEN xyouts, 5E9, 80., omjd, size=1.2  ELSE $
       xyouts, 2500, 12000, /device, omjd, size=1.2
 ENDIF


;THIS NEEDS TO BE FIXED LATER, CURRENTLY ONLY OVERPLOTS freq vs mJy






IF (ps AND (NOT strip)) THEN BEGIN
   device,/close
   set_plot,'x'
ENDIF

END

