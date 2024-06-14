      *================================================================================
     H option(*noDebugIo)
      *================================================================================
      * UHC010RD - UHC - Correct to actual term date - UNET
      *================================================================================
      * Date        Int   Description
      * ----------  ---   -------------------------------------------------------------
      * 07/31/2020  jt    Original creation
      * 06/13/2025  jt    Test new repo
      * 06/13/2024  jt    Test a merge to RDi
      * 06/13/2024  jt    One more time
      * 06/13/2024  jt    Test again for DK
      * 06/13/2024  jt    Test merge in RDi
      * 06/13/2024  jt    test test
      * 06/13/2024  jt    test test test
      * 06/13/2024  jt    tttt
      * 06/14/2024  jt    testing merge
      * 06/14/2024  jt    2nd merge of 06/14
      * 06/14/2024  jt    Syncronize
      * 06/14/2024  jt    Test push
      * 06/14/2024  jt    test synch again
      * 06/14/202   jt    Learn synch/merge
      *================================================================================

     fuhcdtlxu  uf   e           k disk    rename(uhcr:uhcDetail)

     fuhctrml1  if   e           k disk    rename(uhctr:termFile)

     fmember    if   e           k disk    ExtFile('F.MEMBER')

      *================================================================================
      *   xxx = %editc( %dec(%char(%date(numericdate:*iso):*mdy0):8:0):'X')
      *   opcode to convert yyyymmdd to mmddyyyy
      *================================================================================

     d today           s              8  0
     d ktrst           s              3  0
     d ksub#           s              3  0
     d kacct           s              4  0
     d outDate         s              8

     d lastday         pr                  extpgm('LASTDAY2')
     d  ctrust                        3    const
     d  csub                          3    const
     d  cplan                         4    const
     d  inDate                        8    const
     d  outDate                       8    const

      //==================================================================
      // mainline
      //===================================================================

       exsr init;
       exsr main;
       exsr exit;

      //===================================================================
      // main
      //===================================================================

       begsr main;

        setll *loval uhcDetail;
        read uhcDetail;

        dow not %eof;

         exsr process;

         //update uhcDetail;

        read uhcDetail;
        enddo;

       endsr;

      //===================================================================
      // exit
      //===================================================================

       begsr process;

        exsr getTSA;

        setgt (ktrst : ksub# : kacct : mbssno : today) termFile;
        readpe (ktrst : ksub# : kacct : mbssno) termFile;
        dow not %eof;

         if ttype = 'MED';

          if dmtrmdate > ' ';
           lastday(%char(ktrst):%char(ksub#):tplan:%char(ttermdt):outDate);
           dmtrmdate = outDate;
           drtrmdate = outDate;
          endif;

         endif;

         if ttype = 'DEN';

          if ddtrmdate > ' ';
           lastday(%char(ktrst):%char(ksub#):tplan:%char(ttermdt):' ');
           ddtrmdate = outDate;
          endif;

         endif;

         if ttype = 'VIS';

          if dvtrmdate > ' ';
           lastday(%char(ktrst):%char(ksub#):tplan:%char(ttermdt):' ');
           dvtrmdate = outDate;
          endif;

         endif;

        readpe (ktrst : ksub# : kacct : mbssno) termFile;
        enddo;

       endsr;

      //===================================================================
      // get tsa
      //===================================================================

       begsr getTSA;

        ktrst = 0;
        ksub# = 0;
        kacct = 0;

        setll (%dec(dmssn:9:0)) member;
        reade (%dec(dmssn:9:0)) member;

        dow not %eof;

         if cnclcd <> 'C';
          ktrst = mbtrst;
           ksub# = mbsub#;
           kacct = mbacct;
          leavesr;
         endif;

        reade (%dec(dmssn:9:0)) member;
        enddo;

       endsr;

      //===================================================================
      // exit
      //===================================================================

       begsr exit;

        *inlr = '1';
        return;

       endsr;

      //===================================================================
      // init
      //===================================================================

       begsr init;

        today = %dec(%date());
        ttermdt = 0;
        ttermdt = 0;

       endsr;

       //==============================================================
