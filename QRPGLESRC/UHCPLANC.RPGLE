      *=========================================================================
     h option(*noDebugIo)
      *=========================================================================
      * UHCPLANC - UHC Create plans - Prime
      *=========================================================================
      * Date         Int  Description
      * ---------    ---  ------------------------------------------------------
      * 02/14/2020   jt   Original Creation
      * 04/08/2021   jt   Added error report
      * 04/22/2021   jt   Prevented record to be added to the transoff file
      *                   unless record is added to caraccp with a status of N
      * 04/28/2021   jt   Don't write record if first "(" is missing. Changed
      *                   to activate plans when creating and turn trans. on
      * 05/11/2021   jt   Modification for when a group is changing from UHC UNET
      *                   to UHC Prime.
      * 06/09/2022   jt   Check for one space in plan in group #.
      * 06/14/2024   jt   Testing synch
      * 06/14/2024   jt   Test sychc to RDi from GH
      * 06/14/2024   jt   Send this to GH
      * 06/14/2024   jt   Testing synch
      * 06/14/2024   jt   Test sychc to RDi from GH
      * 06/14/2024   jt   Send this to GH
      * 06/14/2024   ja   Send this back to GH
      * 06/14/2024   jt   Send this again
      *=========================================================================
      *
     fuhcplancr1uf   e           k disk    rename(uhcpcr:mainFile)

     fuhcplancrcif a e           k disk    rename(uhcpcr:newFile)

     fplnmst    if   e           k disk    extfile('F.PLNMST')
     f                                     rename(plnmsr:planFile)

     fcarplnz   if a e           k disk    rename(carplnr:mapFile)

     fcaraccp   uf a e           k disk    rename(caraccr:acctFile)

     ftransoff1 uf a e           k disk    rename(transr:transFile)

     fgrate     if   e           k disk    extfile('F.GRATE')
     f                                     rename(grater:rateFile)

     fcomctuniq if   e           k disk    rename(comcxr:comFile)
     f

     fuhcplancreif a e           k disk    rename(uhcper:errorFile)

     fhist      if a e           k disk    ExtFile('F.HIST')
     f                                     rename(histr:histFile)

     fdiaryhd0  if a e           k disk    ExtFile('F.DIARYHD0')
     f                                     rename(rdiaryhd:diaryFile)

      *=========================================================================

     d psds           sds
     d proc_name         *proc
     d user                  254    263

     d unique          s             10
     d runique         s             10
     d pos             s              2  0
     d pos2            s              2  0
     d pos3            s              2  0
     d lenght          s              2  0
     d planvar         s              5
     d incarrier       s              2  0
     d option          s              1
     d inhistory       s              1
     d today           s              8  0
     d fndcurrent      s              1
     d fndfuture       s              1
     d wrong_plncat    s              3
     d active          s              1

     d dltadd          pr                  ExtPgm('TROFF2')
     d  catrst                        3  0
     d  casub#                        3  0
     d  caacct                        4  0
     d  incarrier                     2  0
     d  option                        1
     d  inhistory                     1

     d uhcplanc        pi
     d  renewalMonth                  2    const

      //========================================================================
      // mainline
      //========================================================================

       exsr init;
       exsr main;
       exsr exit;

      //========================================================================
      // main
      //========================================================================

       begsr main;

        setll *loval mainFile;
        read  mainFile;
        dow not %eof;

         exsr process;
         //pprocessed = 'P';
         update mainFile;

        read  mainFile;
        enddo;

       endsr;

      //========================================================================
      // exit
      //========================================================================

       begsr process;

        chain (unique : ptrst : psub# : pacct : pplan) mapFile;
        if %found;
         pprocessed = 'P';
         leavesr;
        endif;

        chain (runique : ptrst : psub# : pacct : pplan) mapFile;
        if %found;
         pprocessed = 'P';
         leavesr;
        endif;

        if not %found;

         chain (ptrst : psub# : pplan) planFile;
         if %found;

          if %parms = 1;

           if prenew = %dec(renewalMonth:2:0);
            exsr writeMapping;
            leavesr;
           endif;

          else;
           exsr writeMapping;
          endif;

         endif;

        endif;

       endsr;

      //========================================================================
      // write map file
      //========================================================================

       begsr writeMapping;

        exsr see_ifActive;
        if active = 'N';
         pprocessed = 'P';
         leavesr;
        endif;

        exsr getGroup;
        if wrong_plncat = ' ';

         clear mapFile;
         //cpuniq = runique;
         cpuniq = unique;
         cptrst = ptrst;
         cpsub# = psub#;
         cpacct = pacct;
         cpcctr = 'ALL';
         cpplan = plplan;
         exsr getGroup;
         cpcid5 = planvar;
         write mapFile;

         chain (unique : ptrst : psub# : pacct) acctFile;
         if not %found(caraccp);
          clear acctFile;
           cauniq = unique;
            catrst = ptrst;
             casub# = psub#;
              caacct = pacct;
               cacid6 = 'GBSEDIPRIME';
               cacid8 = 'OE';
              cacid9 = 'F';
            castatus = 'Y';
           //dltadd(catrst : casub# : caacct : incarrier : option : inhistory);
          write acctFile;

         exsr history;

         chain (incarrier : ptrst : psub# : pacct) transFile;
         if not %found;
          clear transFile;
           otrst = ptrst;
            osub# = psub#;
             oacct = pacct;
              ocarrier = incarrier;
              odesc = 'UHC';
             ouser = user;
            odate = %dec(%date);
           otime = %dec(%time);
          //write transFile;
         endif;

         endif;

         if %found(caraccp);
          if castatus <> 'Y';
           cacid6 = 'GBSEDIPRIME';
            cacid8 = 'OE';
             cacid9 = 'F';
            castatus = 'Y';
           update acctFile;
          endif;

          chain (incarrier : ptrst : psub# : pacct) transFile;
          if %found;
           delete transFile;
          endif;
         endif;

         pprocessed = 'P';
         exsr writeNew;

        endif;

       endsr;

      //========================================================================
      // canceled
      //========================================================================

       begsr see_ifActive;

        active = 'N';

        setll (ptrst : psub# : pacct : plplan) comfile;
        reade (ptrst : psub# : pacct : plplan) comfile;
        dow not %eof;

         if cmcan = 0;
          active = 'Y';
          leavesr;
         endif;

         if cmcan > %dec(%date);
          active = 'Y';
          leavesr;
         endif;

        reade (ptrst : psub# : pacct : plplan) comfile;
        enddo;

       endsr;

      //========================================================================
      // get group
      //========================================================================

       begsr getGroup;

        fndcurrent = 'N';
        fndfuture = 'N';

        setll (ptrst : psub# : plplan) rateFile;
        reade (ptrst : psub# : plplan) rateFile;

        dow not %eof;

        if today >= frmdat;
         if today <= todat;
          fndcurrent = 'Y';
          leave;
         else;
          group# = ' ';
         endif;
        endif;

        reade (ptrst : psub# : pplan) rateFile;
        enddo;

        if fndcurrent = 'N';
         setll (ptrst : psub# : plplan) rateFile;
         reade (ptrst : psub# : plplan) rateFile;

         dow not %eof;

         if  frmdat > today;
          fndfuture = 'Y';
          leave;
         else;
           group# = ' ';
         endif;

         reade (ptrst : psub# : pplan) rateFile;
         enddo;
        endif;

        if fndcurrent = 'Y' or fndfuture = 'Y';
         exsr getCategory;
        else;
         cpcid7 = 'ERROR';
        endif;

       endsr;

      //========================================================================
      // get category
      //========================================================================

       begsr getCategory;

        wrong_plncat = ' ';

        select;
         when plncat = 'PMM';
          cpcid7 = %subst(group#:1:7);
          pos = %scan('(':pdescr:1);
          if pos > 0;
           pos2 = %scan(')':pdescr:pos);

            if pos2 = 0;
             exsr planError;
             wrong_plncat = 'INV';
             leavesr;
            endif;

            lenght = pos2 - pos - 1;
           pos = pos + 1;
           planvar = %subst(pdescr:pos:lenght);
          else;
           planvar = 'ERROR';
           wrong_plncat = 'INV';
          endif;

         when plncat = 'PDN';
          planvar = 'ERROR';
          cpcid7 = %subst(group#:1:7);
          pos3 = %scan('   ':group#:1);
          pos2 = %scan('  ':group#:1);
          pos = %scan(' ':group#:1);

          if pos > 0;
           planvar = %subst(group#:pos + 1 : 5);
           leavesr;
          endif;

          if pos2 > 0;
           planvar = %subst(group#:pos2 + 2 : 5);
           leavesr;
          endif;

          if pos3 > 0;
           planvar = %subst(group#:pos3 + 3 : 5);
           leavesr;
          endif;

         when plncat = 'PDV' or plncat = 'PVS';
          planvar = 'ERROR';
          cpcid7 = %subst(group#:1:7);
          pos3 = %scan('   ':group#:1);
          pos2 = %scan('  ':group#:1);
          pos = %scan(' ':group#:1);

          if pos > 0;
           planvar = %subst(group#:pos + 1 : 5);
           leavesr;
          endif;

          if pos2 > 0;
           planvar = %subst(group#:pos2 + 2 : 5);
           leavesr;
          endif;

          if pos3 > 0;
           planvar = %subst(group#:pos3 + 3 : 5);
           leavesr;
          endif;

         other;
          wrong_plncat = 'INV';

        endsl;

       endsr;

      //========================================================================
      // plan error
      //========================================================================

       begsr planError;

        ptrste = ptrst;
        psub#e = psub#;
        paccte = pacct;
        pplane = pplan;
        pdescre = pdescr;

        write errorFile;

       endsr;

      //========================================================================
      // write new
      //========================================================================

       begsr writeNew;

        ptrstn = ptrst;
        psub#n = psub#;
        pacctn = pacct;
        pplann = pplan;
        pdescrn = pdescr;

        write newFile;

       endsr;

      //===========================================================================
      // history
      //===========================================================================

       begsr history;

         clear diaryFile;
         nhkey = %editc(catrst:'X') + %editc(casub#:'X') + %editc(caacct:'X');
         nhcode = 'WFT';
         nhaddt = %dec(%date);
         nhadti = %dec(%time);
         nhadus = user;
         nhsubj = 'UHC-TRANSMISSION TURNED ON';

         write diaryFile;

         clear histFile;
         hkey = %editc(catrst:'X') + %editc(casub#:'X') + %editc(caacct:'X');
         trcode = 'UHM';
         hprgnm = proc_name;
         hstrst = catrst;
         hssub# = casub#;
         hsacct = caacct;
         hsdltd = 'A';
         trdate = %dec(%date);
         hstrtime = %time;
         hoper = user;
         ck#not = 'UHC-TRANSMISSION TURNED ON';

         write histFile;

       endsr;


      //========================================================================
      // exit
      //========================================================================

       begsr exit;

        *inlr = '1';
        return;

       endsr;

      //========================================================================
      // init
      //========================================================================

       begsr init;

        unique = '0000000290';
        runique = '9000000290';
        incarrier = 17;
        option = 'A';
        inhistory = 'Y';
        today = %dec(%date);

       endsr;

      //========================================================================
