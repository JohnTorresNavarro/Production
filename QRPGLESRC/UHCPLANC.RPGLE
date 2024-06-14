<<<<<<< Upstream, based on origin/topicFM070
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
=======
000100240614      *=========================================================================
000200240614     h option(*noDebugIo)
000300240614      *=========================================================================
000400240614      * UHCPLANC - UHC Create plans - Prime
000500240614      *=========================================================================
000600240614      * Date         Int  Description
000700240614      * ---------    ---  ------------------------------------------------------
000800240614      * 02/14/2020   jt   Original Creation
000900240614      * 04/08/2021   jt   Added error report
001000240614      * 04/22/2021   jt   Prevented record to be added to the transoff file
001100240614      *                   unless record is added to caraccp with a status of N
001200240614      * 04/28/2021   jt   Don't write record if first "(" is missing. Changed
001300240614      *                   to activate plans when creating and turn trans. on
001400240614      * 05/11/2021   jt   Modification for when a group is changing from UHC UNET
001500240614      *                   to UHC Prime.
001600240614      * 06/09/2022   jt   Check for one space in plan in group #.
001700240614      * 06/14/2024   jt   Testing synch
001800240614      * 06/14/2024   jt   Test sychc to RDi from GH
001900240614      * 06/14/2024   jt   Send this to GH
002000240614      * 06/14/2024   ja   Send this back to GH
002100240614      *=========================================================================
002200240614      *
002300240614     fuhcplancr1uf   e           k disk    rename(uhcpcr:mainFile)
002400240614
002500240614     fuhcplancrcif a e           k disk    rename(uhcpcr:newFile)
002600240614
002700240614     fplnmst    if   e           k disk    extfile('F.PLNMST')
002800240614     f                                     rename(plnmsr:planFile)
002900240614
003000240614     fcarplnz   if a e           k disk    rename(carplnr:mapFile)
003100240614
003200240614     fcaraccp   uf a e           k disk    rename(caraccr:acctFile)
003300240614
003400240614     ftransoff1 uf a e           k disk    rename(transr:transFile)
003500240614
003600240614     fgrate     if   e           k disk    extfile('F.GRATE')
003700240614     f                                     rename(grater:rateFile)
003800240614
003900240614     fcomctuniq if   e           k disk    rename(comcxr:comFile)
004000240614     f
004100240614
004200240614     fuhcplancreif a e           k disk    rename(uhcper:errorFile)
004300240614
004400240614     fhist      if a e           k disk    ExtFile('F.HIST')
004500240614     f                                     rename(histr:histFile)
004600240614
004700240614     fdiaryhd0  if a e           k disk    ExtFile('F.DIARYHD0')
004800240614     f                                     rename(rdiaryhd:diaryFile)
004900240614
005000240614      *=========================================================================
005100240614
005200240614     d psds           sds
005300240614     d proc_name         *proc
005400240614     d user                  254    263
005500240614
005600240614     d unique          s             10
005700240614     d runique         s             10
005800240614     d pos             s              2  0
005900240614     d pos2            s              2  0
006000240614     d pos3            s              2  0
006100240614     d lenght          s              2  0
006200240614     d planvar         s              5
006300240614     d incarrier       s              2  0
006400240614     d option          s              1
006500240614     d inhistory       s              1
006600240614     d today           s              8  0
006700240614     d fndcurrent      s              1
006800240614     d fndfuture       s              1
006900240614     d wrong_plncat    s              3
007000240614     d active          s              1
007100240614
007200240614     d dltadd          pr                  ExtPgm('TROFF2')
007300240614     d  catrst                        3  0
007400240614     d  casub#                        3  0
007500240614     d  caacct                        4  0
007600240614     d  incarrier                     2  0
007700240614     d  option                        1
007800240614     d  inhistory                     1
007900240614
008000240614     d uhcplanc        pi
008100240614     d  renewalMonth                  2    const
008200240614
008300240614      //========================================================================
008400240614      // mainline
008500240614      //========================================================================
008600240614
008700240614       exsr init;
008800240614       exsr main;
008900240614       exsr exit;
009000240614
009100240614      //========================================================================
009200240614      // main
009300240614      //========================================================================
009400240614
009500240614       begsr main;
009600240614
009700240614        setll *loval mainFile;
009800240614        read  mainFile;
009900240614        dow not %eof;
010000240614
010100240614         exsr process;
010200240614         //pprocessed = 'P';
010300240614         update mainFile;
010400240614
010500240614        read  mainFile;
010600240614        enddo;
010700240614
010800240614       endsr;
010900240614
011000240614      //========================================================================
011100240614      // exit
011200240614      //========================================================================
011300240614
011400240614       begsr process;
011500240614
011600240614        chain (unique : ptrst : psub# : pacct : pplan) mapFile;
011700240614        if %found;
011800240614         pprocessed = 'P';
011900240614         leavesr;
012000240614        endif;
012100240614
012200240614        chain (runique : ptrst : psub# : pacct : pplan) mapFile;
012300240614        if %found;
012400240614         pprocessed = 'P';
012500240614         leavesr;
012600240614        endif;
012700240614
012800240614        if not %found;
012900240614
013000240614         chain (ptrst : psub# : pplan) planFile;
013100240614         if %found;
013200240614
013300240614          if %parms = 1;
013400240614
013500240614           if prenew = %dec(renewalMonth:2:0);
013600240614            exsr writeMapping;
013700240614            leavesr;
013800240614           endif;
013900240614
014000240614          else;
014100240614           exsr writeMapping;
014200240614          endif;
014300240614
014400240614         endif;
014500240614
014600240614        endif;
014700240614
014800240614       endsr;
014900240614
015000240614      //========================================================================
015100240614      // write map file
015200240614      //========================================================================
015300240614
015400240614       begsr writeMapping;
015500240614
015600240614        exsr see_ifActive;
015700240614        if active = 'N';
015800240614         pprocessed = 'P';
015900240614         leavesr;
016000240614        endif;
016100240614
016200240614        exsr getGroup;
016300240614        if wrong_plncat = ' ';
016400240614
016500240614         clear mapFile;
016600240614         //cpuniq = runique;
016700240614         cpuniq = unique;
016800240614         cptrst = ptrst;
016900240614         cpsub# = psub#;
017000240614         cpacct = pacct;
017100240614         cpcctr = 'ALL';
017200240614         cpplan = plplan;
017300240614         exsr getGroup;
017400240614         cpcid5 = planvar;
017500240614         write mapFile;
017600240614
017700240614         chain (unique : ptrst : psub# : pacct) acctFile;
017800240614         if not %found(caraccp);
017900240614          clear acctFile;
018000240614           cauniq = unique;
018100240614            catrst = ptrst;
018200240614             casub# = psub#;
018300240614              caacct = pacct;
018400240614               cacid6 = 'GBSEDIPRIME';
018500240614               cacid8 = 'OE';
018600240614              cacid9 = 'F';
018700240614            castatus = 'Y';
018800240614           //dltadd(catrst : casub# : caacct : incarrier : option : inhistory);
018900240614          write acctFile;
019000240614
019100240614         exsr history;
019200240614
019300240614         chain (incarrier : ptrst : psub# : pacct) transFile;
019400240614         if not %found;
019500240614          clear transFile;
019600240614           otrst = ptrst;
019700240614            osub# = psub#;
019800240614             oacct = pacct;
019900240614              ocarrier = incarrier;
020000240614              odesc = 'UHC';
020100240614             ouser = user;
020200240614            odate = %dec(%date);
020300240614           otime = %dec(%time);
020400240614          //write transFile;
020500240614         endif;
020600240614
020700240614         endif;
020800240614
020900240614         if %found(caraccp);
021000240614          if castatus <> 'Y';
021100240614           cacid6 = 'GBSEDIPRIME';
021200240614            cacid8 = 'OE';
021300240614             cacid9 = 'F';
021400240614            castatus = 'Y';
021500240614           update acctFile;
021600240614          endif;
021700240614
021800240614          chain (incarrier : ptrst : psub# : pacct) transFile;
021900240614          if %found;
022000240614           delete transFile;
022100240614          endif;
022200240614         endif;
022300240614
022400240614         pprocessed = 'P';
022500240614         exsr writeNew;
022600240614
022700240614        endif;
022800240614
022900240614       endsr;
023000240614
023100240614      //========================================================================
023200240614      // canceled
023300240614      //========================================================================
023400240614
023500240614       begsr see_ifActive;
023600240614
023700240614        active = 'N';
023800240614
023900240614        setll (ptrst : psub# : pacct : plplan) comfile;
024000240614        reade (ptrst : psub# : pacct : plplan) comfile;
024100240614        dow not %eof;
024200240614
024300240614         if cmcan = 0;
024400240614          active = 'Y';
024500240614          leavesr;
024600240614         endif;
024700240614
024800240614         if cmcan > %dec(%date);
024900240614          active = 'Y';
025000240614          leavesr;
025100240614         endif;
025200240614
025300240614        reade (ptrst : psub# : pacct : plplan) comfile;
025400240614        enddo;
025500240614
025600240614       endsr;
025700240614
025800240614      //========================================================================
025900240614      // get group
026000240614      //========================================================================
026100240614
026200240614       begsr getGroup;
026300240614
026400240614        fndcurrent = 'N';
026500240614        fndfuture = 'N';
026600240614
026700240614        setll (ptrst : psub# : plplan) rateFile;
026800240614        reade (ptrst : psub# : plplan) rateFile;
026900240614
027000240614        dow not %eof;
027100240614
027200240614        if today >= frmdat;
027300240614         if today <= todat;
027400240614          fndcurrent = 'Y';
027500240614          leave;
027600240614         else;
027700240614          group# = ' ';
027800240614         endif;
027900240614        endif;
028000240614
028100240614        reade (ptrst : psub# : pplan) rateFile;
028200240614        enddo;
028300240614
028400240614        if fndcurrent = 'N';
028500240614         setll (ptrst : psub# : plplan) rateFile;
028600240614         reade (ptrst : psub# : plplan) rateFile;
028700240614
028800240614         dow not %eof;
028900240614
029000240614         if  frmdat > today;
029100240614          fndfuture = 'Y';
029200240614          leave;
029300240614         else;
029400240614           group# = ' ';
029500240614         endif;
029600240614
029700240614         reade (ptrst : psub# : pplan) rateFile;
029800240614         enddo;
029900240614        endif;
030000240614
030100240614        if fndcurrent = 'Y' or fndfuture = 'Y';
030200240614         exsr getCategory;
030300240614        else;
030400240614         cpcid7 = 'ERROR';
030500240614        endif;
030600240614
030700240614       endsr;
030800240614
030900240614      //========================================================================
031000240614      // get category
031100240614      //========================================================================
031200240614
031300240614       begsr getCategory;
031400240614
031500240614        wrong_plncat = ' ';
031600240614
031700240614        select;
031800240614         when plncat = 'PMM';
031900240614          cpcid7 = %subst(group#:1:7);
032000240614          pos = %scan('(':pdescr:1);
032100240614          if pos > 0;
032200240614           pos2 = %scan(')':pdescr:pos);
032300240614
032400240614            if pos2 = 0;
032500240614             exsr planError;
032600240614             wrong_plncat = 'INV';
032700240614             leavesr;
032800240614            endif;
032900240614
033000240614            lenght = pos2 - pos - 1;
033100240614           pos = pos + 1;
033200240614           planvar = %subst(pdescr:pos:lenght);
033300240614          else;
033400240614           planvar = 'ERROR';
033500240614           wrong_plncat = 'INV';
033600240614          endif;
033700240614
033800240614         when plncat = 'PDN';
033900240614          planvar = 'ERROR';
034000240614          cpcid7 = %subst(group#:1:7);
034100240614          pos3 = %scan('   ':group#:1);
034200240614          pos2 = %scan('  ':group#:1);
034300240614          pos = %scan(' ':group#:1);
034400240614
034500240614          if pos > 0;
034600240614           planvar = %subst(group#:pos + 1 : 5);
034700240614           leavesr;
034800240614          endif;
034900240614
035000240614          if pos2 > 0;
035100240614           planvar = %subst(group#:pos2 + 2 : 5);
035200240614           leavesr;
035300240614          endif;
035400240614
035500240614          if pos3 > 0;
035600240614           planvar = %subst(group#:pos3 + 3 : 5);
035700240614           leavesr;
035800240614          endif;
035900240614
036000240614         when plncat = 'PDV' or plncat = 'PVS';
036100240614          planvar = 'ERROR';
036200240614          cpcid7 = %subst(group#:1:7);
036300240614          pos3 = %scan('   ':group#:1);
036400240614          pos2 = %scan('  ':group#:1);
036500240614          pos = %scan(' ':group#:1);
036600240614
036700240614          if pos > 0;
036800240614           planvar = %subst(group#:pos + 1 : 5);
036900240614           leavesr;
037000240614          endif;
037100240614
037200240614          if pos2 > 0;
037300240614           planvar = %subst(group#:pos2 + 2 : 5);
037400240614           leavesr;
037500240614          endif;
037600240614
037700240614          if pos3 > 0;
037800240614           planvar = %subst(group#:pos3 + 3 : 5);
037900240614           leavesr;
038000240614          endif;
038100240614
038200240614         other;
038300240614          wrong_plncat = 'INV';
038400240614
038500240614        endsl;
038600240614
038700240614       endsr;
038800240614
038900240614      //========================================================================
039000240614      // plan error
039100240614      //========================================================================
039200240614
039300240614       begsr planError;
039400240614
039500240614        ptrste = ptrst;
039600240614        psub#e = psub#;
039700240614        paccte = pacct;
039800240614        pplane = pplan;
039900240614        pdescre = pdescr;
040000240614
040100240614        write errorFile;
040200240614
040300240614       endsr;
040400240614
040500240614      //========================================================================
040600240614      // write new
040700240614      //========================================================================
040800240614
040900240614       begsr writeNew;
041000240614
041100240614        ptrstn = ptrst;
041200240614        psub#n = psub#;
041300240614        pacctn = pacct;
041400240614        pplann = pplan;
041500240614        pdescrn = pdescr;
041600240614
041700240614        write newFile;
041800240614
041900240614       endsr;
042000240614
042100240614      //===========================================================================
042200240614      // history
042300240614      //===========================================================================
042400240614
042500240614       begsr history;
042600240614
042700240614         clear diaryFile;
042800240614         nhkey = %editc(catrst:'X') + %editc(casub#:'X') + %editc(caacct:'X');
042900240614         nhcode = 'WFT';
043000240614         nhaddt = %dec(%date);
043100240614         nhadti = %dec(%time);
043200240614         nhadus = user;
043300240614         nhsubj = 'UHC-TRANSMISSION TURNED ON';
043400240614
043500240614         write diaryFile;
043600240614
043700240614         clear histFile;
043800240614         hkey = %editc(catrst:'X') + %editc(casub#:'X') + %editc(caacct:'X');
043900240614         trcode = 'UHM';
044000240614         hprgnm = proc_name;
044100240614         hstrst = catrst;
044200240614         hssub# = casub#;
044300240614         hsacct = caacct;
044400240614         hsdltd = 'A';
044500240614         trdate = %dec(%date);
044600240614         hstrtime = %time;
044700240614         hoper = user;
044800240614         ck#not = 'UHC-TRANSMISSION TURNED ON';
044900240614
045000240614         write histFile;
045100240614
045200240614       endsr;
045300240614
045400240614
045500240614      //========================================================================
045600240614      // exit
045700240614      //========================================================================
045800240614
045900240614       begsr exit;
046000240614
046100240614        *inlr = '1';
046200240614        return;
046300240614
046400240614       endsr;
046500240614
046600240614      //========================================================================
046700240614      // init
046800240614      //========================================================================
046900240614
047000240614       begsr init;
047100240614
047200240614        unique = '0000000290';
047300240614        runique = '9000000290';
047400240614        incarrier = 17;
047500240614        option = 'A';
047600240614        inhistory = 'Y';
047700240614        today = %dec(%date);
047800240614
047900240614       endsr;
048000240614
048100240614      //========================================================================
>>>>>>> 0c0ef3c Commit to GH/JT
