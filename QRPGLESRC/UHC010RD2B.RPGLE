      *================================================================================
     H option(*noDebugIo)
      *================================================================================
      * UHC010RD - UHC - Correct to actual term date - UNET
      *================================================================================
      * Date        Int   Description
      * ----------  ---   -------------------------------------------------------------
      * 07/31/2020  jt    Original creation
      * 02/23/2021  jt    Changed some logic
      * 06/13/2021  jt    Test 2 separate comits
      *================================================================================

     fuhcdtlxu  uf   e           k disk    rename(uhcr:uhcDetail)

     fuhctrml2  if   e           k disk    rename(uhctr:termFile)

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
     d covType         s              3
     d cplan           s              4

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

        exsr getTSA;

        if dmtrmdate > ' ';
         covType = 'MED';
          exsr process;
           lastday(%char(ktrst):%char(ksub#):cplan:dmtrmdate:outDate);
          dmtrmdate = outDate;
         drtrmdate = outDate;
        endif;

        if ddtrmdate > ' ';
         covType = 'DEN';
          exsr process;
          lastday(%char(ktrst):%char(ksub#):cplan:dmtrmdate:outDate);
         ddtrmdate = outDate;
        endif;

        if dvtrmdate > ' ';
         covType = 'VIS';
          exsr process;
          lastday(%char(ktrst):%char(ksub#):cplan:dvtrmdate:outDate);
         dvtrmdate = outDate;
        endif;

         update uhcDetail;

        read uhcDetail;
        enddo;

       endsr;

      //===================================================================
      // exit
      //===================================================================

       begsr process;

        chain (ktrst : ksub# : kacct : mbssno : covType : today) termFile;
        if %found;
         cplan = tplan;
        endif;

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

         ktrst = mbtrst;
         ksub# = mbsub#;
         kacct = mbacct;
        leavesr;

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

       endsr;

       //==============================================================
