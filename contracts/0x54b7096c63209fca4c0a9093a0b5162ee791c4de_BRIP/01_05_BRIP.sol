// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brain Pain
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                     ....          .                    .             .                          ...                                          //
//                                      ..           .                   . .            .                          ...                                          //
//                                    . . .         ....                  ..           . .              ..         ..                                           //
//                                   .   .           .::                  :v            i:             ...          j.                                          //
//                                      JQ            i7.                 B5.:         .q.j            :u          .B                       . .                 //
//                                      dB7           ..:.              .vL1rE:       iPi:Ki         .:sXr         2Q                     ....                  //
//                                      BEBi          : rSL             i2iiXLP.      Pv2Js5        :.i7rE      ..7BS      .            ...                     //
//                                 ..  rBv1B     i.  .15L2bjr.          r5PX.sqR     vP7XEdb:      :v.P. R     .:vri:     ..           ...                      //
//                                 ..  b5r  R   iBg2  ruvu: :v7:.r:     BEUPBsqQQ    b7iudU sY     v:dBX P7   ri.. r.     ...         ...                       //
//                                   . BLr7:DJ   QSr  .i   7.  :rUqL   JB.LBQs :gZ  i7u :Z2r jU.  Pi ::  sB  7M.  .v      ...        ....                       //
//                             ..      BQ.PgLiB :Mi:   r uBBBBI.  iME  Q  u1j7i iM: :jv i:rKi KBMMs :     QE2r5   r.      ...   .   ..r..                       //
//                             ..:     PBv:dS.JriB:..iB i BBQBQBR. .vBBg :urY71r iqI:U i27:Y  .1QB  : QQ: :BsJ:  L2.      ...   ..   .:7                        //
//                             ..r     iBY1iI.JBY:J.. 7 i: BZi:i7SL  rQB:    BbUs 7Zbi 7QBB. jDg sR: 7BBB 7B.2  LqXr      :i.  ....   .v7                       //
//                          :    i.    .BgPY  7UQ  ruu v:U. ..:i7PU. ::J27 .qMJ1P: .uI  BS:  MP   RB:..B. BgU: rs:7:  .. .7v   . ..   .LS.                      //
//                          .i:  .:     IBIr E.SB.  .BJ.r : :rJvr.: rr : rS:..::2B ri  7Bqr MJ 7i 7:...  ZrJX D   7   .QDv s    ...   .Jq.                      //
//                            LU  uQu   :QU rQ.Bq: uS 7Lr B51MPgBB  i   .  i Kr:LY v.  Kr: Qi DB .  :.  5R L :Bu ..  rbB:  X   .g...  .7v.                      //
//                             :viDB.    7Bj Q.g: .QBr . :YS7   :QD.  :QBQQr.v: B:  L.iB. 7..::Er :Bd:  B  ::.DDY..  7: rr 7ii gb   .  gX                       //
//                               KQ5:     2B. .5   Brr7i.i27 .j.  vBE 7BBri:.K rMi 7D:i.   :r  i:.iBQXr7....i DDBBBBML BB i7S iBi   .:vD                        //
//                               .QEvr7.   BQ  Y. .s:QB7:LJ  ZBdi  ir EBr   Ri ::r.  .7r PBBu .r:. :qBBXr1:.r BQi7EBB:gB :r71riBr    :iJ ..                     //
//                                MBrJDg   rBv S.IS:YQb.rBB. i: .rdB. ...IjQg  ...   Jri YZvQr ri: .YB5  gS ..BLrrrP bBu v:bXS Br    .:P7:                      //
//                                Kgj:JBg7  QK.7: i .1Y..rBB  ..vr: . r  7BRAIN-PAIN X:     g7rvr: YBq:.dBB. ivKrMgIEQq: ii:  .7r    1BL                        //
//                                iD5u :BBP :Ki.i Ur ..PBQBB  2BU:. . BD:.      :Pr  :qB77 .r JBZBirBJvBQ1.   7JYPMBB    .:.  :rr  :vPg.                        //
//                                .E.r  .dBBrXL.s B:   .PPr:: rB: i   BB77  Qi  .:Z:XBBPr: :  .PQQu  .LBB7 iZv .. 7QB . PXv  ..7i  :Jjb                         //
//                                .B5r:  27XBM5:g.7::     :gr  ..iZB.:BI. iBr..   QBBP..   jd7 ibg. .:iLv gBb. . .rBM . BB7  ::v    sQS                         //
//                                ..sQv  u   iQYB .     .7  BdirLIRBBBB  dB  DB.  .P..2Qi17 BBQ.  :u:Lj  :EB   :i.5Bi  .5B  : d     YBP                         //
//                                 .iqg. v.   7IP rD:   :qq: PBBMBBBBg .BBi. KB: . ::rQB.:r  bBBB7.i r:   bi sDSSgBB : :qg   Q2 Qi  5IE                         //
//                                  uP7  5:  :::S 7Pqrri rBQI :qBQBM: uBQ: .L..i ru rE7 r: r  .QB.         .UgDZEQB. . vB:i XQ BB. :Yq2                         //
//                             .     gQ  Br  :::r 5B2BQRs .BBg: :BX.rBME. IBDggBr BX . QY iQBR. :..      rQBqX1SDBg .  ig ::g iBB  L2g.                         //
//                              .    .Bs QQ  ::Id 5BMXKXBQ  uBBY..igB2Y.2BBg:. sI  QjiB: dBQBBBi Pj      BBBBBBQBB.  5 Lr Lb :BBI :5YY                          //
//                              ...   .B..B. .i2B DBBQgMBBBr rBB1ugBvi:qBBP:::ivPZ .BB  BBPULY5BP      v: iBBBBBBB   J.Z  B2 ZsBD P:i:                          //
//                              ....   :D rq  rJP QBBBBBBBBBQ .uBBBr .i:     vBBP vQ.PB  gQSEBBB. QBd 5BB7  QBBBBBq77 Pr LBi :RB.:S v                           //
//                              ....    rI g. iI  QBBBBBBBBBd iBQdPQ7  rL:i1sBBr Xq . 5B. BBBBQ  BBYvS:rBBQ. LBBBBBB vb  i:v ZBb 1r:7                           //
//                              ....     ruJi rB. .PBBBBBBBiiQBb i1DBQ. bBPBBq  :. gBU .U iQBs rBP.  :Y iRBBP  BBBB :B:  i7i.BB5 i:L.                           //
//                               .:BJ      757JB .   :iSBQ.LBBi jdvi1BBY :BBr    JBBBBRi  .Br UBj  MQ .j : XBP. .   Bi  :ug:MBB  7rr                            //
//                                 iB2iP.r.  rig:v7 :   v.PBB  RBBgr.:XBB:      gBBBBBBBd  . QBY  QBBM  i   ..r  :S1D:  qUsDBMQ  Y7                             //
//                                . Ib.RBPUgQ:KY 5M.r   :BBD  BBBBBBBJ.iBB    YBQBBBBBBBBBY :B. iBr  BQsr  i dL  7QbR7 :qissrBB.idi                             //
//                          .U      .P  :ubib1Qvirid7  7BBs :BBBBBBBBBB7v7.. RBBBBBBBQBBBQB .. ZD.   DBBB. Q YK rQBvP. .:.ui M525P                              //
//                          BB7      Rq   :b .Krvi BQ ..BY iBBBKQMi2BBBBQ  7::BBBBBBBBBBBg    :BB. q: BBBB sd.vMPBi:U.. i.dr 7 PIi                              //
//                         dBrB:     :B:   7I .KIv  Bi    . BBr7    BQBQi ...   .vBBBQBQBB :I YQQB .B  57.iKBQK:SRu.v : 27Z  Uvir                               //
//                        .B. rB      Qr    i..RQ:  MD. Xd :QBvSL:. BBBB..B7 .    BBQBBBQBq B. . .iiXB:::IgBQi 7 B: S    rv :Q:7r.                              //
//                        Y5   BB     RS   .. .5Zv  gBBvBB iLLr7rB: 1PPB7 BU ..r KBriQB   .:BB5Y22ZQQ:E    2:7   g .E .rP...Q5.gr                               //
//                        ..vQ DB.    IB.  .:  PDB  2r .XBEr:5J52BBYs5:.i.ZB  Sg :. . r vvSB71QL   vP ir   g .i UI LYi2BU LPIsUS                                //
//                          5Bi BB    :EP  .i  ZEg. rQ  jrB.  rqZQMQ. iUbJ2EZ.EL  Y7r5  QB..  E    KK  X  vS .v B. QdBPi .B2iRD                                 //
//                          27:: BB    :ZP..i  D Ku  B  g vB   Ed.rRu B5.d..QEBB Y.. iL:BB i  :7   u2  g. gr :r d iPPQi rijJvR                                  //
//                           U.L iQ     iLXr.i S::g. 71 R  BI rZb  DP..b:Q  iU.BP1 BB  gjL.1 q 2.Q Pi  Q. B. i:iL 27Mi:v. L7Qv                                  //
//                           22 :. i     :72:v.vr q7  Q.d.. B.vMs  .BK usR . j.dRJ Bdr B.:Lv B I. .R  .g Y1  :.D :Q2Q7:  vj5IL                                  //
//                .I5BBBEI7  i2i :iX.      UB..qr gi  7X2 Q JdLZr   PB: 7Q:1 rir D 7:r i :K iB :. X.: iR.Q : uB. Bi:7.  rKR rs                                  //
//                 rQ:LBbsQBr ULL :.s.      vg IY vg   QK jR XKZ:   :B2 iR.d2 sr     .g: :R 2B.  72 B 7Bg 7s R. qS ui  iKQ: rU                                  //
//                  .:   iUBI . B:.I r  .r   7.r5 .Qb  :R.jiq.BD .v. rS.:g:PQ g: BBb .BQL d QB: .5 iB iQi B    Yg.1vv :MY   vU                                  //
//                         :BBX rB.:u iv:XI. . rq5. BI  .:M 11uQ BB: .ZU.PiXB dL BQBP BBQ . QB i:I BB..q iBQd :Br.:i .BY    Yu                                  //
//                           QBq D7 vQ .Y 7Z ri.BBB uQs  :B .Qig u:.. iE LLiB:.Z Q: . BBB  iBg RB. :B.  .QBBs B5r  : Bi     uL                                  //
//                            BB U1 gBBi  :i .uPY2BM XuU .B  q7DX  vK  XriU BP 7 B1:  SBB  bB5 Q. r ZB :QBBS gXK  i1I.rY    1J                                  //
//                             QQ i.:BBBBJ .:  .J.7BL 1vIiB ..DrU  77j  Z55 .  .5QB .  B. v Br   .2: BBQBBQ 2Rs  :BL..ui    rs                                  //
//                              BB d LBBBBBY..g7:v: B1 JBPB . Bi . L.7r .QK  U sQBq Y PBi B LB.i 2:r BBBQB .QS. rB.::.Qi     s                                  //
//                              :Bi Z BBBBBQBQBBK i  QX IBB7  Lu7B Ki Bi  1  sv BQQ g vB5 XJ BBB g . dBBBr BB:  Yvi. PI .   .g                                  //
//                               BQ :i YgBBBBBBBDBj.rBBS :PBX :DY: Pir.B r: .IQ :BQ gX BD Y1 iQ JY : 7BBB sBY 7.X:   7i7    .B                                  //
//                               BBB i:  .BBBBBBERDBBBBBB.uBBdJK. iP B Ku BY:7rZ BQ 7R KB irr : B .. rBQr BJ X :.:  isD.    .R                                  //
//                                 RQ i7:  L5BBBPYQBBBBBQBvI:BBBY  I Bd q:  :L .7 1 .i.r2 .X2  B.ig  JBB :B iB:.Q: rSD:     .B                                  //
//                                  .. iri:.. 7BBPBBBQBBBB77  2BBu J gBi 77..:ii.v .r i. : rY..E BB  .r YB iBBBQR I1U.      gB:                                 //
//                                    .7:. :22  1BBBQBBBBBrr..  BBMJ sBBJ.Uri 2B :r:7. 7:i .:iL  BBL i:.i vBBBBZ 7s:        :7                                  //
//                                 .KgBbMBZJ..7r  rQBBBBBB2: 1B. vBBr RBB7 SM ...r .Y:B:.Y :  .YBB .BB: 7MBBBBBq  .:.                                           //
//                                .L7i    .PQB:.:rsi.SBBBBqqDRBBS .BB  .7B52B  : BBLU5BB   BBBBB7 :BB: BBBBBQBB: iv7.                                           //
//                                      :2.  r: 7:5X.7.XBBBQB1BQBP .Bg5Rirgr72   BQP57r.:j  7:. r:7  :BQBBBQBB. 7Jv                                             //
//                                      i.5. ...7gSdgEi .qZBBLZBBBZ IBY7XQq1i7E. ::7PIvIUJirsbuY:  .BBBBBBBBj  u7.                                              //
//                                      . iB. ...:PJ:SgBS rKBBBQBBBi QY7  .:uBBBBgQSYv r. ....::IQQBBBBBBBBQ  Ur                                                //
//                                         BB7    77 u:rgSS.iriBQBBL L vj: Ur uiv  SjUqRBPvEBBQBBBBBBBBBBBBM XD                                                 //
//                                         KBQB. iBQDI: ijYKv:i ::Q1 : LL. BB :  . 5BQBKBBBBBBgBBQBQBBBBBQX iY                                                  //
//                                        7BJPR. jPBQBKu.7.2isJ:.7 Lr r.  .    ...v  gr.gBBBQBgBBBBZBBBBu..Ls.                                                  //
//                                        :       P.PQBBBDEBMvr:7Yur. vYri.. :...sPY rPr:.iPBBMqi    BY :77.                                                    //
//                                                Q  :U  : :J 7BBL.q5i.7j2BBMQQBBSr.   i7:r. :.  :.  . ..                                                       //
//                                                R  .P  2 r.   .ur   :i7.::75Bji.        .:iir.si:r.. .r..                                                     //
//                                               .Q  .Q    Q                    .r7vrisXLvr7YJBBdBBgqjU5:                                                       //
//                                               .B   u                             ..::. .LKgQBg1vvr.                                                          //
//                                               :BU  r                                      .u                                                                 //
//                                                57  i                                       B                                                                 //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BRIP is ERC721Creator {
    constructor() ERC721Creator("Brain Pain", "BRIP") {}
}