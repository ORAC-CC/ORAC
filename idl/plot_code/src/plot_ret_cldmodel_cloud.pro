
;+
; PLOT_RET_CLDMODEL
;
; Plot results from cloud-model retrieval compared to Phil's OCA results
;
; PARAMETERS
;	X	Result structure (run ret_cldmodel, read by rd_ret_cldmodel)
;	H	Header also returned by keyword to rd_ret_cldmodel
;
; KEYWORDS
;	FILE	Define file from which to read X,H
;	ISEL	Passed to RD_RET_CLDMODEL
;	PS	Write pdf
;	FAC	Increase size of plot symbol by given factor
;	UR	Define grid U coord range to plot
;	VRcolocate_calipso_modis,/ps,/aatsr,datein='20080921',/forc,/netcdf	Define grid V coord range to plot
;	IMAGE	Plot data as images (smaller ps file)
;	ITYPE 	Plot results for a specific type, not "best" type
;	MCOT	Set min cloud opt depth for plotting Re,height,phase
;	MCOST	Set max normalised cost for plotting Re,height,phase
;	RELEVL	Specify contour levels for eff.radius / microns
;	EXT	Specify procedure name to call when map coods set-up
;		(usefull for overplotting things on the ret fields)
;		parameters can be sent to this via _EXTRA
;	NORESID	Don't do 2nd page of residual plots
;	LATR	Lat range to plot
;	LONR	Lat range to plot
;	ZRAN	Set altitude range for result colour bar
;	AXTI	If set and satellite grid is used, then plot along x x-track images
;		instead of using pl_boxmap to show data - results in much smaller files !
;	LAND	Set to do first plot in landscape mode (the default), set to 0
;		for portrait - e.g. if more rows than cols in image
;	NSET 	Do not set_a4 for first plot
;	P1,P2	Define p1,p2 for first plot
;	MASK	Define mask used in first plot
;	CHARS	Define charsize used
;	OFC	Return after plotting false colour
;	KML	Output results to kml file - only works if data sinusoidally gridded.
;		NB this may be forced for other data by changing h.sg to define
;		a sinusoidal grid and
;		h.u,v so that results on other grid end up binned into the new grid.
;		plot_ret_cldmodel_modis does this.
;
; R.S. 19/12/2008
; Cp. 20/06/2013 remove sea key word as command need external
; libraries
; cp : 20/06/2013 added in nosec keyword
; cp : 11/11/2013 modified code to plot out uncertainties if
; requested.
; cp : 28/01/2014 tidy up of plots
; $Id: plot_ret_cldmodel.pro 1112 2011-08-08 09:06:42Z rsiddans $
;-
pro quick_cim_prc,sg,u,v,d,_EXTRA=extra,ll=ll,ext=ext,chars=chs,brd=brd,crd=crd,pext=pext,cpos=cpos,axti=axti,nodata=nodata,kml=kmlfi,eop_col=eop_col,eop_thick=eop_thick,eop_y=eop_y,eop_x=eop_x

	md=min(d(where(finite(d) eq 1)))

	if not keyword_set(axti) then sat=sg.sat else sat=0
	if sat eq 1 then begin
		pl_boxmap,u,v,d,lonr=range(u),latr=range(v),brd=brd, $
                          crd=crd,_EXTRA=extra,ext=ext,$
			chsrs=chs

	endif else begin
		if n_elements(nodata) eq 0 then nodata=md-999

		di=standard_grid_1d2d(d,u,v,nodata=nodata,ur=ur,vr=vr,$
                                      ll=ll,lonr=lonr,latr=latr,rll=sg,ori=ori)
		if keyword_set(pext) then call_procedure,pext,di, $
                                                         _EXTRA=extra,ur=ur,vr=vr
		if sg.sd eq 1 then begin
			quick_cim,di,_EXTRA=extra,min_v=md-100, $
                                  chars=chs,brd=brd,crd=crd,cpos=cpos

		endif else begin
                   if keyword_set(kmlfi) then begin
                      quick_cim_kml,kmlfi,di,_EXTRA=extra,$
                                    min_v=md-100,/add,/noclose,$
                                    lonr=lonr,latr=latr

                   endif else begin
                      quick_cim,di,_EXTRA=extra,min_v=md-100,$
                                chars=chs,brd=brd,crd=crd,cpos=cpos

                      if n_elements(lonr) gt 0 then begin
                         !p.multi(0)=!p.multi(0)+1
                         plot,lonr,latr,/nodata,/xst,/yst, $
                              chars=chs*0.5,position=cpos,xminor=1,yminor=1

                         !p.multi(0)=!p.multi(0)+1
                         kmap_set,/adv,pos=cpos,lonr=lonr,latr=latr, $
                                  /nobo,/hir,ori=ori
                      endif
                      
                      if keyword_set(ext) then call_procedure,ext,_EXTRA=extra

                      
                   endelse
                endelse
		if keyword_set(ext) then call_procedure,ext,_EXTRA=extra, $
                                                        u=u,v=v,cpos=cpos ;,eop_col=eop_col,eop_thick=eop_thick,eop_y=eop_y,eop_x=eop_x

	endelse
     end

pro plot_ret_cldmodel_cloud,x,h,ps=ps,isel=isel,file=fi,fac=fac,ur=ur,vr=vr,image=image,itype=itype,sea=sea,mcot=mcot,mcost=mcost,ext=ext,_EXTRA=extra,noresid=noresid,noqc=noqc,latr=ulatr,lonr=ulonr,zran=zran,axti=axti,land=land,lcb=lcb,bcb=bcb,p1=p1,p2=p2,nset=nset,mask=mask,chars=chs,ofc=ofc,night=night,error=error,kml=kml,eop_col=eop_col,eop_thick=eop_thick,eop_y=eop_y,eop_x=eop_x,nosec=nosec,fips=fips,fatplot=fatplot,istomina=istomina,v1=v1,inst=inst,aer=aer,noir=noir


	if n_tags(x) eq 0 then begin
;		if n_elements(fi) eq 0 then fi='/home/cluster/rsiddans/cloud-model/out/2007/07/22/ATS_TOA_1PRUPA20070722_102425_000065272060_00079_28189_4846.N1_50_v2.str'

		if n_elements(fi) eq 0 then fi='/home/cluster/cpoulsen/idl/cloud_model/out/2008/06/20/_ATS_TOA_1PRUPA20080620_170936_000065272069_00355_32974_0742_1-512_74-79_gv3_spi_11110001_v3p18.str'
;fi='/home/cluster/cpoulsen/idl/cloud_model/out/2008/06/20/_ATS_TOA_1PRUPA20080620_170936_000065272069_00355_32974_0742_1-512_-58--53_gv3_spi_11110001_v3p18.str'
		x=rd_ret_cldmodel(fi,h=h,isel=isel)
	endif



;next 3 lines needed for net cdf file

	if n_elements(itype) eq 0 then xc=ret_min_cost(x,h.types,h=h) 
        xc=x

	xc=ret_add_geo(xc,h)
	np=h.npix
;
; plot
;

	names=cldmodel_sv_retnames(h.sv)
        print,'short name',names
	tis=names.short_names+' / '+names.units
	nx=n_elements(xc(0).xn)
	ny=n_elements(xc(0).yn)
	fb=file_name(h.file,del='.')
	psfi=fips+'.ps'


        print,'psfi',psfi
	if keyword_set(kml) then begin
		if strpos(h.sg.id,'neq') ne 0 then message,'Only works for sinusoidal grid - see plot_ret_cldmodel_modis.pro for forcing with other grids'
		kmlfi='/disks/rdrive/Richard/cld_model/kml/'+file_name(psfi,/base)
		quick_cim_kml,kmlfi,/open
             endif

        fb=file_basename(psfi,'.ps')

        fd=file_dirname(psfi)

 
        psfi=fd+'/'+fb+'.ps'
        print,'plot_ret_cldmodel psfi',psfi

	if keyword_set(ps) then ps_open,psfi


	if n_elements(land) eq 0 then land=1
	if n_elements(chs) eq 0 then chs=def_chs()
	if n_elements(lcb) eq 0 then lcb=1

        
        if ~keyword_set(fatplot) then begin
           if not keyword_set(nset) then begin
              set_a4,n=nx+8,/rs,landscape=land
              mask=[[0,1,2,3,4,5,6],[7,8,9,10,11,12,13]]
           endif
        endif else begin

           set_a4,n=nx+1,/rs,landscape=land
           mask=[[0,1,2],[3,4,5]]
        endelse

        
        if n_elements(p1) eq 0 then p1=[0.02,0.02,0.99,0.93]
        if n_elements(p2) eq 0 then p2=[0.1,0.1,0.98,0.96]

	if n_elements(fac) eq 0 then fac=0.5	; size of plot symbol
	if n_elements(ur) eq 0 then ur=range(h.u)
	if n_elements(vr) eq 0 then vr=range(h.v)
	wh=where(h.u le ur(1) and h.u gt ur(0) and h.v le vr(1) and h.v ge vr(0),nw)
	if nw eq 0 then wh=0
	xc=xc(wh)


	if h.sg.sat eq 1 and not keyword_set(axti) then begin
		u=xc.lon
		v=xc.lat
	endif else begin
		u=xc.u
		v=xc.v
	endelse


;
; apply lat/lon range if set
;
	if keyword_set(ulatr) then begin
		wlat=where(xc.lat ge ulatr(0) and xc.lat le ulatr(1),nlat)
		if nlat eq 0 then message,'No data in lat range!'
		xc=xc(wlat) & u=u(wlat) & v=v(wlat)
	endif
	if keyword_set(ulonr) then begin
		wlon=where(xc.lon ge ulonr(0) and xc.lon le ulonr(1),nlon)
		if nlon eq 0 then message,'No data in lon range!'
		xc=xc(wlon) & u=u(wlon) & v=v(wlon)
	endif
;
; apply some qc
;

	xq=xc
		uq=u
		vq=v


;	if keyword_set(error) then goto, skip2error


;
; plot a map and approx position of data
;



if max(h.sg.latr) le -999 then goto,skip
if min(h.sg.latr) le -999 then goto,skipmap
	map_loc,mean1(h.sg.latr),mean_lon(h.sg.lonr),$
		position=ypos(p1,p2,mask=mask),chars=chs,/nop,zoom=0.25,/horiz


	bg=setup_llbin(xc.lat,xc.lon,[-90,90,1],[-180,180,1])
	wg=where(bg.n gt 0,ng)
	if ng gt 0 then begin
		iglat=wg/n_elements(bg.mlon)
		iglon=wg mod n_elements(bg.mlon)
		for ig=0l,ng-1 do polyfill,bg.lon(iglon(ig)+[0,1,1,0,0]),$
			bg.lat(iglat(ig)+[0,0,1,1,0]),col=2
	 	map_continents
             endif
skipmap:
;
;false color plot
;
        if ~keyword_set(nosec) then begin
           if tag_exist(xc,'alb') then begin
              d16=min(abs(1.6-h.s.mwl))
              d37=min(abs(3.7-h.s.mwl))

              if d16 gt 0.5 and d37 lt 0.5 then i37=1 
              if d16 gt 0.5 and d37 lt 0.5 then print,'i37'
  ;print,h.s.mwl
;i37=1            
 ;does not work           
 ;             im_mea=mk_cldmodel_false_color_cloud(xc,h,i37=i37)
 ;             im_sim=mk_cldmodel_false_color_cloud(xc,h,/sim,i37=i37)


              im_mea=mk_cldmodel_false_color_cloud(xc,h)
              im_sim=mk_cldmodel_false_color_cloud(xc,h,/sim)
              im_alb=mk_cldmodel_false_color_cloud(xc,h,/alb)

              xc.alb(0,*)=xc.alb(0,*)
              xc.alb(1,*)=xc.alb(1,*)
              xc.alb(2,*)=xc.alb(2,*)
; store old albedo values
              xc_temp=xc

             im_alb1=mk_cldmodel_false_color_cloud(xc_temp,h,/alb)
 

              xc.alb(0,*)=xc.alb(0,*)*abs(cos(!dtor*xc.solz))
              xc.alb(1,*)=xc.alb(1,*)*abs(cos(!dtor*xc.solz))
              xc.alb(2,*)=xc.alb(2,*)*abs(cos(!dtor*xc.solz))
 
              im_alb2=mk_cldmodel_false_color_cloud(xc,h,/alb)
                            
              quick_cim_prc,kml=kmlfi,h.sg,u,v,im_mea,ur=ur,vr=vr,num=2,fac=fac,$
                            position=ypos(p1,p2,mask=mask),chars=chs,title='False colour - meas',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

           endif
        endif ;nosec



        if ~keyword_set(nosec) then begin
           for k=0,4 do begin
              if k eq 2 then begin
                 if keyword_set(i37)  then begin
                 lev=indgen(22)*5+210
;cp just changed
                 lev=indgen(22)*2+280
                    levres=indgen(20)*.5-5
              endif else begin
                 lev=indgen(20)*.025
                 levres=indgen(20)*.025*2-0.5
                 levres=indgen(20)*.01-0.1
              endelse

              endif else begin
                 if k gt 2 then begin
                    lev=indgen(24)*5+190
                    levres=indgen(20)*.5-5
                 endif else begin
                    lev=indgen(20)*.05
                    levres=indgen(20)*.01-0.1
                 endelse
              endelse
              
              
              if max((xc.y(k,*)))  lt 180. then type_channel='ref'
              if max((xc.y(k,*)))  gt 180. then type_channel='BT'
        
              if( type_channel eq 'BT') and ~keyword_set(noir) then begin       
                 quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.y(k),lev=lev,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title=type_channel+' Ch '+i2s(k+1),lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti
              
                 
                 quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.yn(k),lev=lev,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title='sim Ch '+i2s(k+1),lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti
                 
                 
;residual
                 
                 if tag_exist(xc,'ymfit') then begin
                    quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.ymfit(k),lev=levres,ur=ur,vr=vr,num=2,fac=fac,$
                                  position=ypos(p1,p2,mask=mask),chars=chs,title='residual Ch '+i2s(k+1),lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti
                 endif
              endif  else begin
                 quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.y(k),lev=lev,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title=type_channel+' Ch '+i2s(k+1),lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti
              
                 
                 quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.yn(k),lev=lev,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title='sim Ch '+i2s(k+1),lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti
                 if tag_exist(xc,'ymfit') then begin
                    quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.ymfit(k),lev=levres,ur=ur,vr=vr,num=2,fac=fac,$
                                  position=ypos(p1,p2,mask=mask),chars=chs,title='residual Ch '+i2s(k+1),lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti
endif


              endelse           ;noir
              
              if k eq 2 then begin
                 if ~keyword_set(fatplot) then begin
                    if not keyword_set(nset) then begin
                       set_a4,n=nx+8,/rs,landscape=land
                       mask=[[0,1,2,3,4,5,6],[7,8,9,10,11,12,13]]
                    endif
                 endif else begin
                    
                    set_a4,n=nx+1,/rs,landscape=land
                    mask=[[0,1,2],[3,4,5]]
                 endelse
                 
                 
              endif
              
              
              any_key
           endfor
        endif                   ;nosec
;
;plot the angles
;
        
        if tag_exist(xc, 'solz') then begin
           
           levang=indgen(20)*5
           quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.satz,lev=levang,ur=ur,vr=vr,$
                         num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs, $
                         title='sat zenith ',lcb=lcb,bcb=bcb,image=image, $
                         ext=ext,_EXTRA=extra,axti=axti
           
           levang=indgen(20)*9.
           quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.relaz,lev=levang,ur=ur,vr=vr, $
                         num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs, $
                         title='rel az ',lcb=lcb,bcb=bcb,image=image, $
                         ext=ext,_EXTRA=extra,axti=axti
           
           levang=indgen(36)*5.
           quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.solz,lev=levang,ur=ur,vr=vr, $
                         num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs,$
                         title='solar zenith ',lcb=lcb,bcb=bcb,image=image,$
                         ext=ext,_EXTRA=extra,axti=axti
           levang=indgen(20)*5
           levanglong=indgen(20)*9
; calculate scattering angle
           sc=scat_ang(xc.solz,xc.satz,xc.relaz)
           quick_cim_prc,kml=kmlfi,h.sg,u,v,sc,lev=levanglong,ur=ur,vr=vr, $
                         num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs,$
                         title='scattering angle ',lcb=lcb,bcb=bcb,image=image,$
                         ext=ext,_EXTRA=extra,axti=axti

endif                   ;solz

        if ~keyword_set(nosec) then begin
;
;plot illumination
;

           quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.illum,lev=[-1.0,-0.,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0],$
                         ur=ur,vr=vr,num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs, $
                         title='Illumination',lcb=lcb,bcb=bcb,image=image, $
                         ext=ext,_EXTRA=extra,axti=axti
           
        endif
        any_key
skipref:        
        
        
        
        if ~keyword_set(nosec) then begin
;
; plot 11-12 microns
;
           if ~keyword_set(noir) then begin
              
              w0=where(h.s.iview eq h.s(0).iview,n0)
              ich=w0(get_nns([10.5,12.],h.s.mwl)) ; identify split window
              swlev=[-10,-7,-5,-3,-2,-1,-0.5]
              swlev=[swlev,0,-reverse(swlev)]
              quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.y(ich(0))-xc.y(ich(1)),lev=swlev,ur=ur,vr=vr,num=2,fac=fac,$
                            position=ypos(p1,p2,mask=mask),chars=chs,title='11-12 um - meas',lcb=lcb,bcb=bcb,image=image,/cbs,ext=ext,_EXTRA=extra,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
              
              
              quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.yn(ich(0))-xc.yn(ich(1)),lev=swlev,ur=ur,vr=vr,num=2,fac=fac,$
                            position=ypos(p1,p2,mask=mask),chars=chs,title='11-12 um - sim',lcb=lcb,bcb=bcb,image=image,/cbs,ext=ext,_EXTRA=extra,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
           endif
        endif                   ;nosec
        
        
        if ~keyword_set(fatplot) then begin
           set_a4,n=nx+8,/rs,landscape=land
           mask=[[0,1,2,3,4,5,6],[7,8,9,10,11,12,13]]
        endif else begin
           set_a4,n=nx+1,/rs,landscape=land
           mask=[[0,1,2],[3,4,5]]
        endelse
        
;goto,skipconv
        
	quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.conv,lev=[-1.5,-0.5,0.5,1.5],$
                      ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),chars=chs, $
                      title='Convergence',lcb=lcb,bcb=bcb,image=image, $
                      ext=ext,_EXTRA=extra,axti=axti


	quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.ni,lev=indgen(26),$
                      ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),chars=chs, $
                      title='Iterations',lcb=lcb,bcb=bcb,image=image, $
                      ext=ext,_EXTRA=extra,axti=axti


;skipconv:
        costlev=[0.,1,2,3,5,6, 7, 8, 9,10, 11, 12,   15,20,30,50]

	quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.cost/ny,$
		lev=costlev,/cbs,$
		ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs, $
                title='Cost',lcb=lcb,bcb=bcb, $
                image=image,ext=ext,_EXTRA=extra,axti=axti,$
                eop_col=eop_col,eop_thick=eop_thick,eop_y=eop_y,eop_x=eop_x



;
;plot ctt
;
        pd=xc.tc                ;/100.0
        levctt=indgen(20)*6+190
;if keyword_set(mli) then  levctt=indgen(20)*6+100
       xd=u
        yd=v
        cbs=1

        quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),lev=levctt,$
                      chars=chs,title='CTT K',lcb=lcb,bcb=bcb,cbs=cbs,$
                      ext=ext,_EXTRA=extra,$
                      image=image,axti=axti,eop_col=eop_col,$
                      eop_thick=def_th,eop_y=eop_y,eop_x=eop_x


;
;phase
;


	quick_cim_prc,kml=kmlfi,h.sg,uq,vq,xq.itype,lev=findgen(5)-1,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='Phase',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
		crd=crd,brd=brd,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x


        if ~keyword_set(nosec) then begin
;
; plot false colour images - usually 1.6,0.8,0.6 false colour unless it looks like
; 1.6 not present and 37 is
;
           if ~keyword_set(night) then begin
              
              if tag_exist(xc,'alb') then begin
;                 d16=min(abs(1.6-h.s.mwl))
;                 d37=min(abs(3.7-h.s.mwl))
;                 if d16 gt 0.5 and d37 lt 0.5 then i37=1 
                 
                 
                 
;                 im_mea=mk_cldmodel_false_color_cloud(xc,h,i37=i37)
;                 im_sim=mk_cldmodel_false_color_cloud(xc,h,/sim,i37=i37)
;                 im_alb=mk_cldmodel_false_color_cloud(xc,h,/alb,i37=i37)
                 
                 
                 quick_cim_prc,kml=kmlfi,h.sg,u,v,im_mea,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title='False colour - meas',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                 
                 if keyword_set(ofc) then return
                 quick_cim_prc,kml=kmlfi,h.sg,u,v,im_sim,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title='False colour - sim',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                 

                 quick_cim_prc,kml=kmlfi,h.sg,u,v,im_alb2,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title='FC albedo zenith corrected',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                 

                 quick_cim_prc,kml=kmlfi,h.sg,u,v,im_alb1,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title='FC albedo',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                 




              endif
           endif else begin
              if ~keyword_set(noir) then begin
;
;plot 11 and 12 microns of a night scene
;
                 w0=where(h.s.iview eq h.s(0).iview,n0)
                 ich=w0(get_nns([10.5,12.],h.s(w0).mwl)) ; identify split window
                 
                 quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.y(ich(0)),ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title='11 um - meas',lcb=lcb,bcb=bcb,image=image,/cbs,ext=ext,_EXTRA=extra,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x,nodata=-999.,lev=indgen(20)*5+200.
                 
                 quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.y(ich(1)),ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title='12 um - meas',lcb=lcb,bcb=bcb,image=image,/cbs,ext=ext,_EXTRA=extra,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                 
              endif
;
           endelse
           
           
           
        endif
                                ;nosec
        
        
        for i=0,nx-2 do begin
           
           ti1=tis(i)
           pd=xc.xn(i)
           xd=u
           yd=v
           cbs=0
           lev=0
           
           
           if strpos(tis(i),'PC') ge 0  then begin
              
              ti1='Z* / km'
              xd=uq
              yd=vq
              if h.sv.zstar eq 1 then begin
                 if keyword_set(error) then begin
                    pd=xq.xe(i)
                    
                 endif else begin
                    pd=xq.xn(i)
                    if keyword_set(error) then begin
                       pd(wh)=zstar(xq(wh).xn(i)-xq(wh).sx(i))-zstar(xq(wh).xn(i))
                       
                    endif
                    
                 endelse
              endif else begin
                 pd=xq.xn(i)*0
                 wh=where(xq.xn(i) gt 0,nw)
                 pd(wh)=zstar((xq.xn(i))(wh))
                 if keyword_set(error) then begin
                    pd(wh)=zstar(xq(wh).xn(i)-xq(wh).sx(i))-zstar(xq(wh).xn(i))
                    
                 endif
;message,'Check SX!!!!'
              endelse
              if n_elements(zran) eq 0 then range=[0.,16.] else range=zran
              if  keyword_set(error) then range=[0.,3.] 
           endif else if strpos(tis(i),'LCOT') ge 0 then begin
              ti1='Optical depth'
              pd=xc.xn(i)       ; removed 10^
              
              if keyword_set(error) then pd=xq.xe(i) ;pd*xc.xe(i)/alog10(exp(1.))

              lev=[0.,0.05,0.1,0.2,0.4,0.7,1,2,5,10,20,50,100]
              cbs=1
           endif else if strpos(tis(i),'RE') ge 0 then begin
              pd=xq.xn(i)
              if keyword_set(error) then pd=xq.xe(i)

              xd=uq
              yd=vq
;			lev=[0.,0.01,0.2,0.05,0.1,0.2,0.5,1.,2.,5,10,20,50,100,200]
                                ;                   		if n_elements(relev) eq 0 then $
              lev=[0.,0.1,1.,2,4,6,8,10,12,15,20,25,30,50,100] 
              if keyword_set(error) then lev=[0.,0.1,1.,2,4,6,8,10,12,15,20] 
;				else lev=relev
              cbs=1
           endif else     range=range(cldmodel_sv_levels(tis(i)))
           
           if n_elements(lev) lt 2 then lev=clevels(range)
           
           
           if i eq nx-1 then begin
;
;plot iterations
;
              
              quick_cim_prc,kml=kmlfi,h.sg,uq,vq,xq.ni,lev=findgen(22),ur=ur,vr=vr,num=2,fac=fac,$
                            position=ypos(p1,p2,mask=mask),chars=chs,title='Iterations',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
                            crd=crd,brd=brd,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
              
              
           endif else begin
              
;if strpos(tis(i),'Ts') ge 0  then lev=levctt
;if strpos(tis(i),'Ts') ge 0  then
      
;endif
              if strpos(tis(i),'TS') ge 0 or  strpos(tis(i),'Ts') ge 0  then begin
levstemp=indgen(20)*4+240
                 quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),lev=levstemp,chars=chs,title=ti1,lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                               image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                 
              endif else begin
;plot opd,cre,zstar

                 quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),lev=lev,chars=chs,title=ti1,lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                               image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x


              endelse

              if strpos(tis(i),'TS') ge 0 or  strpos(tis(i),'Ts') ge 0 then begin ;
                 pd=xc.x0(i)
                 if ~keyword_set(nosec) then begin 
                    quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                  position=ypos(p1,p2,mask=mask),lev=levctt,chars=chs,title='FG '+ti1,lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                  image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                    

       if ~keyword_set(fatplot) then begin
           if not keyword_set(nset) then begin
              set_a4,n=nx+8,/rs,landscape=land
              mask=[[0,1,2,3,4,5,6],[7,8,9,10,11,12,13]]
           endif
        endif else begin

           set_a4,n=nx+1,/rs,landscape=land
           mask=[[0,1,2],[3,4,5]]
        endelse

;plot the difference between fg and ret
                    
                    diff=xc.xn(i)-xc.x0(i)
                    levdiff=indgen(20)*.5-5.
                    pd=diff
                    quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                  position=ypos(p1,p2,mask=mask),lev=levdiff,chars=chs,title='diff ts xn-xo '+ti1,lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                  image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

;
;plot difference between ctt and stemp
;


 diff=xc.xn(i)-xc.tc
;print,'diff range',range(diff)
levcttdiff=indgen(20)*5-5
levcttdiff2=indgen(20)*.4-2
pd=diff
                    quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                  position=ypos(p1,p2,mask=mask),lev=levcttdiff,chars=chs,title='diff ctt-stemp '+ti1,lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                  image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x


                    quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                  position=ypos(p1,p2,mask=mask),lev=levcttdiff2,chars=chs,title='diff ctt-stemp '+ti1,lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                  image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x


                    
                 endif          ;nosec
                                     
;
;plot uncorrected albedo
;
if ~keyword_set(nosec) then begin
for k=0,3 do begin

;plot albedo over land
lev=indgen(20)*.0525
;if k eq 2 then lev=indgen(20)*.025
	quick_cim_prc,kml=kmlfi,h.sg,u,v,xc_temp.alb(k),lev=lev,ur=ur,vr=vr,num=2,fac=fac,$;
		position=ypos(p1,p2,mask=mask),chars=chs,title='Albedo land Ch'+i2s(k+1)+' uncorr',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti

any_key
endfor ;albedo

                 quick_cim_prc,kml=kmlfi,h.sg,u,v,im_alb1,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title='FC albedo',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x


                 quick_cim_prc,kml=kmlfi,h.sg,u,v,im_mea,ur=ur,vr=vr,num=2,fac=fac,$
                               position=ypos(p1,p2,mask=mask),chars=chs,title='FC mea',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                 
endif
                 
                 
                 if strpos(tis(i),'PC') ge 0  then begin ;
                    
                    
                    levpc=indgen(20)*55
                    
                    if tag_exist(xc,'cth') then begin
                       pd=xc.cth
                       quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                     position=ypos(p1,p2,mask=mask),lev=lev,chars=chs,title='CTH '+'km',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                    endif
                    
                    pd=xc.x0(i)
                    if ~keyword_set(nosec) then begin 
                       quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                     position=ypos(p1,p2,mask=mask),lev=levpc,chars=chs,title='FG '+'PC hPa',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                       
                       pd=zstar(xc.x0(i))
                       quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                     position=ypos(p1,p2,mask=mask),lev=lev,chars=chs,title='FG '+'zstarkm',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x



any_key


;
;retrived cloud top pressure
;
pd=xc.ctp
quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                     position=ypos(p1,p2,mask=mask),lev=levpc,chars=chs,title='PC hPa',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

                       any_key
                    endif



                    
        if ~keyword_set(fatplot) then begin
           if not keyword_set(nset) then begin
              set_a4,n=nx+8,/rs,landscape=land
              mask=[[0,1,2,3,4,5,6],[7,8,9,10,11,12,13]]
           endif
        endif else begin

           set_a4,n=nx+1,/rs,landscape=land
           mask=[[0,1,2],[3,4,5]]
        endelse
                 
        if ~keyword_set(nosec) then begin
                       pd=xc.lsflag+1
                       quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                     position=ypos(p1,p2,mask=mask),lev=indgen(6),chars=chs,title='land sea flag',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
any_key
                    endif
                    
                    pd=xc.xn(i)
                    quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                  position=ypos(p1,p2,mask=mask),lev=levpc,chars=chs,title=''+'PC hPa',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                  image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                    any_key
                 endif
                 
              endif
              
           endelse
           
           title,file_name(h.ofile,/base),/no,strcat(trim_zero(indgen(h.nst))+':'+h.types,del='; ')
   
           
        endfor
        
        if ~keyword_set(nosec) then begin
        if ~keyword_set(fatplot) then begin
           if not keyword_set(nset) then begin
              set_a4,n=nx+8,/rs,landscape=land
              mask=[[0,1,2,3,4,5,6],[7,8,9,10,11,12,13]]
           endif
        endif else begin

           set_a4,n=nx+1,/rs,landscape=land
           mask=[[0,1,2],[3,4,5]]
        endelse

        endif
;
;plot the cloud mask and neural net mask
;
        quick_cim_prc,kml=kmlfi,h.sg,uq,vq,(xc.mask/100.0),lev=findgen(3)-1,ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),chars=chs,title='Cloud mask cc_total',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
                      crd=crd,brd=brd,axti=axti
        
        quick_cim_prc,kml=kmlfi,h.sg,uq,vq,(xc.cccot),lev=findgen(21)*.055,ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),chars=chs,title='Neural Cloud mask',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
		crd=crd,brd=brd,axti=axti


           
           quick_cim_prc,kml=kmlfi,h.sg,u,v,(xc.nn_pre_mask),lev=findgen(3)-1,ur=ur,vr=vr,num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs,title='Pre NN CM',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
                         crd=crd,brd=brd,axti=axti

           
           quick_cim_prc,kml=kmlfi,h.sg,u,v,(xc.nn_pre),lev=findgen(21)*.055,ur=ur,vr=vr,num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs,title='Pre NN',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
                         crd=crd,brd=brd,axti=axti

           
           quick_cim_prc,kml=kmlfi,h.sg,u,v,(xc.nn_pre),lev=findgen(21)*.0125,ur=ur,vr=vr,num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs,title='Pre NN focus',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
                         crd=crd,brd=brd,axti=axti

if ~keyword_set(nosec) then begin
           quick_cim_prc,kml=kmlfi,h.sg,u,v,(xc.ice_mask),lev=findgen(3)-1,ur=ur,vr=vr,num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs,title='Ice_mask',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
                         crd=crd,brd=brd,axti=axti
endif
if keyword_set(nosec) then set_a4,n=nx+8,/rs,landscape=land

           quick_cim_prc,kml=kmlfi,h.sg,u,v,(xc.cloud_type),lev=findgen(10),ur=ur,vr=vr,num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs,title=' C,N,F,W,S,M,I,Ci,O, PO',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
                         crd=crd,brd=brd,axti=axti


quick_cim_prc,kml=kmlfi,h.sg,u,v,(xc.land_use),lev=findgen(25),ur=ur,vr=vr,num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs,title='Land use',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
                         crd=crd,brd=brd,axti=axti

        any_key
        
;
;plot false color
;
        if ~keyword_set(nosec) then begin
           quick_cim_prc,kml=kmlfi,h.sg,u,v,im_alb2,ur=ur,vr=vr,num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs,title='False colour albedo',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

           
           quick_cim_prc,kml=kmlfi,h.sg,u,v,im_mea,ur=ur,vr=vr,num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),chars=chs,title='False colour - meas',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
           any_key
           


           levpc2=indgen(20)*7+900
           
           pd=xc.x0(2)
           quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                         position=ypos(p1,p2,mask=mask),lev=levpc2,chars=chs,title='FG '+'PC hPa',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                         image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
           
lev=indgen(20)*.1
pd=zstar(xc.x0(2))

quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
              position=ypos(p1,p2,mask=mask),lev=lev,chars=chs,title='FG '+'zstarkm',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
              image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x




;
;extended range
;
levpc=indgen(20)*55
           pd=xc.x0(2)
                       quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                     position=ypos(p1,p2,mask=mask),lev=levpc,chars=chs,title='FG '+'PC hPa',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
                       levz=indgen(20)
                       pd=zstar(xc.x0(2))
                       quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                                     position=ypos(p1,p2,mask=mask),lev=levz,chars=chs,title='FG '+'zstarkm',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x


endif;nosec
;start new page
        if ~keyword_set(nosec) then begin
        if ~keyword_set(fatplot) then begin
           if not keyword_set(nset) then begin
              set_a4,n=nx+8,/rs,landscape=land
              mask=[[0,1,2,3,4,5,6],[7,8,9,10,11,12,13]]
           endif
        endif else begin

           set_a4,n=nx+1,/rs,landscape=land
           mask=[[0,1,2],[3,4,5]]
        endelse
          
        endif
;
;plot albedo if first channel
;

if ~keyword_set(nosec) then begin
for k=0,3 do begin

;plot albedo over land
lev=indgen(20)*.0525
;if k eq 2 then lev=indgen(20)*.025
	quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.alb(k),lev=lev,ur=ur,vr=vr,num=2,fac=fac,$;
		position=ypos(p1,p2,mask=mask),chars=chs,title='Albedo land Ch'+i2s(k+1),lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti

;plot albedo over sea
lev=indgen(20)*.0025
	quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.alb(k),lev=lev,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='Albedo Ch.'+i2s(k+1)+' sea',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti


any_key
endfor ;albedo

	quick_cim_prc,kml=kmlfi,h.sg,u,v,im_alb2,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='False colour albedo',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x


	quick_cim_prc,kml=kmlfi,h.sg,u,v,im_mea,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='False colour - meas',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

;	if keyword_set(ofc) then return
	quick_cim_prc,kml=kmlfi,h.sg,u,v,im_sim,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='False colour - sim',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
;endif
     endif
                      ;nosec

skipalb:
skip2error:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;plot the cloud albedo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if ~keyword_set(v1) then begin
lev=indgen(20)*.0525
nchan=2
for k=0,nchan-1 do begin


	quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.cloud_alb(k),lev=lev,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='Cloud Albedo Ch.'+i2s(k+1),lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti


endfor
any_key
endif;v1


;
;plot the cwp=lwp and iwp
;

lev=indgen(20)*40.
quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.cwp,lev=lev,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='CWP',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti


lev=800+indgen(20)*80.
quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.cwp,lev=lev,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='CWP',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;plot resultsw with quality control
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        if ~keyword_set(fatplot) then begin
           if not keyword_set(nset) then begin
              set_a4,n=nx+8,/rs,landscape=land
              mask=[[0,1,2,3,4,5,6],[7,8,9,10,11,12,13]]
           endif
        endif else begin

           set_a4,n=nx+1,/rs,landscape=land
           mask=[[0,1,2],[3,4,5]]
        endelse

 
ex_t=''
if keyword_set(error) then ex_t='unc'


; extra qc applied here
		xqc=cldmodel_qc_pp(xc,iok=iok,mmask=mmask,mcost=mcost,istomina=istomina,v1=v1,inst=inst,aer=aer,whbad=whbad)

		uqc=u(iok)
		vqc=v(iok)
;false color
if n_elements(iok) le 1 then print,'qc did not work'

if n_elements(iok) le 1 then goto,skip

	for i=0,nx-2 do begin

		ti1=tis(i)
		pd=xqc.xn(i)
                      if keyword_set(error) then  pd=xqc.xe(i)
		xd=uqc
		yd=vqc
		cbs=0
		lev=0

		if strpos(tis(i),'PC') ge 0  then begin

                   ti1='Z* / km'
                   xd=uqc
                   yd=vqc
                   if h.sv.zstar eq 1 then begin
                      if keyword_set(error) then begin
                         ;pd=xqc.xe(i)
                if keyword_set(error) then begin
                   pd=zstar(xqc.xn(i)-xqc.sx(i))-zstar(xqc.xn(i))
                   
                endif

                      endif else begin
                         pd=xqc.xn(i)
                      endelse
                   endif else begin
                      pd=xqc.xn(i)*0
                      wh=where(xqc.xn(i) gt 0,nw)
                      pd(wh)=zstar((xqc.xn(i))(wh))
                      if keyword_set(error) then begin
                         pd(wh)=zstar(xqc(wh).xn(i)-xqc(wh).sx(i))-zstar(xqc(wh).xn(i))

                      endif
;message,'Check SX!!!!'
                   endelse
                   if n_elements(zran) eq 0 then range=[0.,16.] else range=zran
                   if  keyword_set(error) then range=[0.,3.] 
                   if  keyword_set(error) then range2=[0.,2.] 
                endif else if strpos(tis(i),'LCOT') ge 0 then begin
			ti1='Optical depth'
			pd=xqc.xn(i); removed 10^

if keyword_set(error) then pd=xqc.xe(i);pd*xqc.xe(i)/alog10(exp(1.))
			lev=[0.,0.05,0.1,0.2,0.4,0.7,1,2,5,10,20,50,100]
                        levaer=[0.,0.05,0.1,0.2,0.4,0.5,0.7,1,2,3,5,7,10]
                        levaer2=indgen(20)*.15
                        lev2=[100,130,145,160,190,205,220,235,250,255,260,265,280,310,350]
			cbs=1
		endif else if strpos(tis(i),'RE') ge 0 then begin
			pd=xqc.xn(i)
if keyword_set(error) then pd=xqc.xe(i)
			xd=uqc
			yd=vqc
			;lev=[0.,0.01,0.2,0.05,0.1,0.2,0.5,1.,2.,5,10,20,50,100,200]
                    		;if n_elements(relev) eq 0 then $
				lev=[0.,0.1,1.,2,4,6,8,10,12,15,20,25,30,50,100] 
;levels for ice
lev2=[1,5,10,15,20,24,27,30,33,36,39,42,45, 48, 51,60,70,85,100] 

if keyword_set(error) then lev=[0.,0.1,1.,2,4,6,8,10,12,15,20] 
				;else lev=relev
			cbs=1
		endif else range=range(cldmodel_sv_levels(tis(i)))
		if n_elements(lev) lt 2 then lev=clevels(range)


                if i eq nx-2 then begin

                endif else begin

til=ex_t+' '+ti1

if strpos(tis(i),'PC') ge 0  then begin;


levpc=indgen(20)*55


		pd=xqc.cth
                      if keyword_set(error) then begin
                         pd=zstar(xqc.xn(i)-xqc.sx(i))-zstar(xqc.xn(i))

                      endif


quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),lev=lev,chars=chs,title='CTH '+'km',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                      image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

levcth2=indgen(20)*.1
quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),lev=levcth2,chars=chs,title='CTH surface'+'km',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                      image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x



if keyword_set(error) then begin
 lev=clevels(range2)
quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),lev=lev,chars=chs,title='CTH '+'km',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                      image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
endif

endif else begin

                    quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),lev=lev,chars=chs,title=ti1,lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                      image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

print,'tis(i)',tis(i)

if strpos(tis(i),'LCOT') ge 0  then begin
                    quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),lev=levaer2,chars=chs,title=ti1,lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                      image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

                    quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),lev=levaer,chars=chs,title=ti1,lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                      image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

endif

if strpos(tis(i),'micro') ge 0  then begin
                    quick_cim_prc,kml=kmlfi,h.sg,xd,yd,pd,ur=ur,vr=vr,num=2,fac=fac,$
                      position=ypos(p1,p2,mask=mask),lev=lev2,chars=chs,title=ti1,lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                      image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

endif
;

	pd=xqc.tc;/100.0
	lev=indgen(20)*5+210
;	xd=u
;	yd=v
	cbs=1




endelse


                endelse
             endfor             ;loop over nx


lev=400+indgen(20)*40.
quick_cim_prc,kml=kmlfi,h.sg,uqc,vqc,xqc.cwp,lev=lev,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='CWP',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti



	quick_cim_prc,kml=kmlfi,h.sg,xd,yd,xqc.cost/ny,$
		lev=costlev,/cbs,$
		ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs, $
                title='Cost',lcb=lcb,bcb=bcb, $
                image=image,ext=ext,_EXTRA=extra,axti=axti,$
                eop_col=eop_col,eop_thick=eop_thick,eop_y=eop_y,eop_x=eop_x

if ~keyword_set(nosec)  then begin
if ~keyword_set(error)  then begin

	quick_cim_prc,kml=kmlfi,h.sg,u,v,im_mea,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='False colour - meas',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,lcb=lcb,bcb=bcb,nodata=256l*256l*256l-1,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
endif
endif
	quick_cim_prc,kml=kmlfi,h.sg,uqc,vqc,xqc.itype,lev=findgen(5)-1,ur=ur,vr=vr,num=2,fac=fac,$
		position=ypos(p1,p2,mask=mask),chars=chs,title='Phase',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,$
		crd=crd,brd=brd,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

     title,'with qc applied latr='+i2s(min(xc.lat))+'-'+i2s(max(xc.lat))+' lonr='+i2s(min(xc.lon))+'-'+i2s(max(xc.lon))


;
;plot the istomina snow mask
;

if keyword_set(istomina) and keyword_set(i37) then begin
chanin=h.s.mwl
cthy=is_tag(xc, 'CTH')
if cthy eq 0 then print, 'no cth'
cthd=xc.cth

snowmask,datain=xc.y,dataout=dataout,chanin=chanin,cthch=cthd,flag=flag,landdata=xc.lsflag,ac1=xc_temp.alb(0,*),ac2=xc_temp.alb(1,*), $
	trial=trial;,optic=xc.xn(0,*),effr=xq.xn(1,*)
;xc_temp.alb(k)

levsnowmask=indgen(12)*0.1
;
;plot the snow mask
;
; quick_cim_prc,kml=kmlfi,h.sg,uq,vq,reform(dataout),ur=ur,vr=vr,num=2,fac=fac,$
;                                     position=ypos(p1,p2,mask=mask),lev=levsnowmask,chars=chs,title='Istomina snow mask',lcb=lcb,bcb=bcb, $
														;				cbs=cbs,ext=ext,_EXTRA=extra,image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

;0.645832     0.856874      3.70000      11.0263      12.0424
eq1=(xc.y(2,*)-xc.y(3,*))/xc.y(2,*)
eq2=(xc.y(2,*)-xc.y(4,*))/xc.y(2,*)
eq4=(xc.y(1,*)-xc.y(0,*))/xc.y(1,*)

print,range(dataout)

leveq1=indgen(21)*.01-.1
leveq2=indgen(21)*.01-.1
leveq4=indgen(12)*.1-1.0

;
;plot diagnostics for snow and ice from Istomina paper
;
levTIR=indgen(7)*0.5

; quick_cim_prc,kml=kmlfi,h.sg,uq,vq,reform(trial),ur=ur,vr=vr,num=2,fac=fac,$
;                                     position=ypos(p1,p2,mask=mask),lev=levTIR,chars=chs,title='T;IR only flag',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
;                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x,min=-5.0


ls=xc.lsflag
levmap=indgen(3)*0.5

;optical=xc.xn
;plot_optical=reform(optical[1,*])
;help, plot_optical
 quick_cim_prc,kml=kmlfi,h.sg,uq,vq,reform(ls),ur=ur,vr=vr,num=2,fac=fac,$
                                     position=ypos(p1,p2,mask=mask),lev=levmap,chars=chs,title='Land/Sea map',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x



;
;plot the cwp=lwp and iwp
;

;lev=indgen(20)*40.
;quick_cim_prc,kml=kmlfi,h.sg,u,v,xqc.cwp,lev=lev,ur=ur,vr=vr,num=2,fac=fac,$;
;		position=ypos(p1,p2,mask=mask),chars=chs,title='CWP',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti



;lev=800+indgen(20)*80.
;quick_cim_prc,kml=kmlfi,h.sg,u,v,xqc.cwp,lev=lev,ur=ur,vr=vr,num=2,fac=fac,$
;		position=ypos(p1,p2,mask=mask),chars=chs,title='CWP',lcb=lcb,bcb=bcb,image=image,ext=ext,_EXTRA=extra,axti=axti



;quick_cim_prc,kml=kmlfi,h.sg,uq,vq,reform(eq4),ur=ur,vr=vr,num=2,fac=fac,$
;                                     position=ypos(p1,p2,mask=mask),lev=leveq4,chars=chs,title='snow mask eq 8',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
;                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x



eq1=abs((xc.y(2,*)-xc.y(3,*))/xc.y(2,*))
eq2=abs((xc.y(2,*)-xc.y(4,*))/xc.y(2,*))
eq4=(xc.y(1,*)-xc.y(0,*)/xc.y(1,*))



leveq1=indgen(21)*.002
leveq2=indgen(21)*.002


 quick_cim_prc,kml=kmlfi,h.sg,uq,vq,reform(eq1),ur=ur,vr=vr,num=2,fac=fac,$
                                     position=ypos(p1,p2,mask=mask),lev=leveq1,chars=chs,title='abs snow mask eq 5',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x



 quick_cim_prc,kml=kmlfi,h.sg,uq,vq,reform(eq2),ur=ur,vr=vr,num=2,fac=fac,$
                                     position=ypos(p1,p2,mask=mask),lev=leveq2,chars=chs,title='abs snow mask eq 6',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x



;quick_cim_prc,kml=kmlfi,h.sg,uq,vq,reform(eq4),ur=ur,vr=vr,num=2,fac=fac,$
;                                     position=ypos(p1,p2,mask=mask),lev=leveq4,chars=chs,title='abs snow mask eq 8',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
;                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x

;help, flag
;levsnowflag=[0,0.5,1.0,1.5]
;levsnowflag=indgen(7)*0.5
;quick_cim_prc,kml=kmlfi,h.sg,uq,vq,reform(flag),ur=ur,vr=vr,num=2,fac=fac,$
;                                     position=ypos(p1,p2,mask=mask),lev=levsnowflag, chars=chs,title='Snow Flag',lcb=lcb,bcb=bcb,cbs=cbs,ext=ext,_EXTRA=extra,$
;                                     image=image,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x,min=-5.0



any_key
endif ;end of istomina cloud mask


           set_a4,n=nx+1,/rs,landscape=land



if keyword_set(kml) then begin
	quick_cim_kml,kmlfi,/close
	return
endif
if keyword_set(noresid) then goto,skip
            any_key
;
; for seviri do pink plot
;
	if ny eq 11 then begin
	        im_mea=mk_cldmodel_false_color_cloud(xc,h,/pink)
        	im_sim=mk_cldmodel_false_color_cloud(xc,h,/sim,/pink)
		quick_cim_prc,kml=kmlfi,h.sg,u,v,im_mea,ur=ur,vr=vr,num=2,fac=fac,$
			position=ypos(p1,p2,mask=mask1),chars=chs,title='False colour - meas',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,/lcb,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
		quick_cim_prc,kml=kmlfi,h.sg,u,v,im_sim,ur=ur,vr=vr,num=2,fac=fac,$
			position=ypos(p1,p2,mask=mask1),chars=chs,title='False colour - sim',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,/lcb,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
;
; also water vapour channels
;
		ich=get_nns([6.2,7.3,8.7],h.s.mwl)      ; identify std false colour channel
		lev=findgen(21)/20*60+200
		for ii=0,n_elements(ich)-1 do begin
			i=ich(ii)
			quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.y(i),ur=ur,vr=vr,num=2,fac=fac,$
				position=ypos(p1,p2,mask=mask1),chars=chs,title=h.s(i).name+' meas',image=image,lev=lev,_EXTRA=extra,ext=ext,axti=axti,/lcb,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
			quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.yn(i),ur=ur,vr=vr,num=2,fac=fac,$
				position=ypos(p1,p2,mask=mask1),chars=chs,title=h.s(i).name+' sim',image=image,lev=lev,_EXTRA=extra,ext=ext,axti=axti,/lcb,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
		endfor
;

; also 0.6,1.6,3.7 reflectance

		im_mea=mk_cldmodel_false_color_cloud(xc,h,/i37)
		im_sim=mk_cldmodel_false_color_cloud(xc,h,/sim,/i37)
		quick_cim_prc,kml=kmlfi,h.sg,u,v,im_mea,ur=ur,vr=vr,num=2,fac=fac,$
			position=ypos(p1,p2,mask=mask1),chars=chs,title='False colour - meas',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,/lcb,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
		quick_cim_prc,kml=kmlfi,h.sg,u,v,im_sim,ur=ur,vr=vr,num=2,fac=fac,$
			position=ypos(p1,p2,mask=mask1),chars=chs,title='False colour - sim',image=image,lev=lev,_EXTRA=extra,ext=ext,/tru,axti=axti,/b32,/lcb,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
		any_key
	endif
;
; residual plots
;
	fac1=float(fac)*0.3
	whc=where(xc.cost lt 50,nw)
	if nw eq 0 then begin
		message,'Warning no low cost retrievals!',/info
		whc=lindgen(n_elements(xc.cost))
	endif
	cl=[10,30,100,1e32]	; levels of cost function for residual histograms
	col=[c0(),2,3,4,6]
	ncl=n_elements(cl)
	mask1=[[0,1],[2,2]]
	mask1=[mask1,mask1+3]
	mask=mask1
	n2=long(ny/2)+1
	for i=1,n2-1 do mask=[[mask],[mask1+max(mask)+1]]
	set_a4,ro=max(mask)+1
	p1=[0.02,0.,1,1]
	p21=[0.1,0.14,0.97,0.89]
	p22=[0.1,0.16,0.97,0.95]
	chs=1.
;
; plot residuals 
;
	for i=0,ny-1 do begin
		set_color,/rs,/ps
		lev=clevels(median1(xc.y(i),pc=[2.,98.]))	; set levels to span most data
		quick_cim_prc,kml=kmlfi,h.sg,u,v,xc.y(i),ur=ur,vr=vr,num=2,fac=fac1,$
			position=ypos(p1,p21,mask=mask),chars=chs,title=h.s(i).name+' meas',image=image,lev=lev,_EXTRA=extra,ext=ext,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
		dy=xc.y(i)-xc.yn(i)

		lev=clevels(median1(dy(whc),pc=[2.,98.]))	; set levels based on half-decent cost
		quick_cim_prc,kml=kmlfi,h.sg,u,v,dy,ur=ur,vr=vr,num=2,fac=fac1,$
			position=ypos(p1,p21,mask=mask),chars=chs,title=h.s(i).name+' residual',$
			lev=lev,/lcb,image=image,_EXTRA=extra,ext=ext,axti=axti,eop_col=eop_col,eop_thick=def_th,eop_y=eop_y,eop_x=eop_x
;
; construct residual histograms for different cost thresholds
;
		if h.s.mwl(i) lt 3 then lag=[-0.5,0.5,0.005] else lag=[-50,50,0.25]
		bs=dblarr((lag(1)-lag(0))/lag(2),ncl,2)
		for ils=0,1 do for ic=0,ncl-1 do begin
			wh=where(xc.cost lt cl(ic) and ls eq ils+1,nc)
			if nc gt 0 then begin
				b=setup_bin(dy(wh),lag)
				if n_tags(b) gt 0 then bs(0,ic,ils)=b.n
			endif
		endfor
		if n_tags(b) gt 0 then begin
			wh=where(total(total(bs,2),2) gt 1,nw)
			set_color,/ps
			plot_array,bs(*,*,0),/yty,b.mlat,cl,/xst,/yst,chars=chs,$
				position=ypos(p1,p22,mask=mask),$
				title=h.s(i).name+' residual histogram',yran=[1,max(bs)],$
				xrange=range(b.mlat(wh)),lsi=0.3,col=col,/nol,thi=thi
			plot_array,bs(*,*,1),lin=2,b.mlat,cl,/noe,/nol
		endif else plot,[0,1],title=h.s(i).name+' not valid',$
				position=ypos(p1,p22,mask=mask),chars=csh
	endfor
	for i=0,2 do plot,[0,1],/nodata,xst=5,yst=5,position=ypos(p1,p21,mask=mask)
	legend,trim_zero(cl),col=col,size=chs*0.8,/box,/fill,$
		thic=thi,/bl
	legend,line=[0,2],['Sea','Land'],size=chs*0.8,/box,/fill,/br
skip:

	if keyword_set(ps) then ps_close,/hqpdf

end
