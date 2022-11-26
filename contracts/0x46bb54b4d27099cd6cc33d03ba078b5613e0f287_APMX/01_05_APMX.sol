// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Apex Shift Music LE
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//     .r                                                                                                                                                       //
//      RBv                                                                                                                                              7X.    //
//       PBBY                                                                                                                                          5BB.     //
//        YBBBb.                                                                                                                                    7BBQb       //
//         7BBBBQi                                                                                                                               igBBBBi        //
//          rBBBBBBv                                                                                                                          :KBQBQBB          //
//           iBBQBBBQX                                                                                                                     .uBBBBBBBd           //
//            :BBQBBBBBR:                                                                                                                LBBBBBBBBBY            //
//             :BBBBBBBBBBv                                                                                                           rQBBQBBBBBQB:             //
//              .BBQBQBQBBBBK                                                                                                      :gBBBBBBBBQBBB               //
//               .BBBBBBBBBBBBg:                                                                                                .PBBBBBBBBQBBBBZ                //
//                .BBBBBBBBQBBBQBr                                                                                           .UQBBBBBQBBBBBBBBY                 //
//                  BBBBBBQBBBBBQBBI                                                                                       YBBBBBBBBQBQBBBQBB:                  //
//                   BBBBBBBBBBBBQBBBD:                                                                                 rQBBBBBBBBBBBQBQBBBB                    //
//                    BBBBBBQBQBBBBBBBQBr                                                                            iZBBBBBBBBBBBQBBBBBBBb                     //
//                     BBBBBBBBBBBBBBBBBBB2                                                                       .PBBBBBBBBBBBBBBBQBBBQBL                      //
//                      BBBBBBBBBBBBBBBBBBBBZ:                                                                 .UBBBBBBBQBBBBBQBBBBBBBBB:                       //
//                       QBBBBBBBBBBBBBBBQBBBBBr                                                             YBBBBBQBBBQBBBBBBBBBBBBBBB                         //
//                        QBBBBBBBBBQBQBBBBBBBBBB1                                                        rBQBQBQBBBBBBBBBBBBBBBBBBBBd                          //
//                         RBQBBBBBBBBBBBBBBBBBBBQBd.                                                  igBBBBBBBBQBBBBBBBBBQBBBBBBBQY                           //
//                          gBBBBBBBBBBBBBBBBBBBBBBBBBi                                             .PBBBBBBBBBBBBBBBBBBBBBBBBBBBBB:                            //
//                           ZBBBBBBBQBQBBBQBBBQBBBBBBBBu                                        .IQBBBBBBBBBQBBBBBBBBBBBBBBBQBBBB                              //
//                            dBBBBBBBBBBBBBBBQBBBBBQBQBBBd.                                   JBBBBQBQBBBBBBBBBQBBBBBQBQBBBBBBBP                               //
//                             KBBBBBBBBBBBBBQBQBBBBBBBBBBBBBi                               BBBBBBBBBBBBQBBBBBBBBBBBBBQBBBBBBB7                                //
//                              SBBBBBQBQBQBQBBBQBBBBBBBBBQBBBQJ                            XBBBBBBBBBQBBBBBQBBBBBBBBBBBBBBBBB.                                 //
//                               2BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBq.                         BBBBBBBBBBBBBBBBBQBBBBBBBBBBBQBQB                                   //
//                                1BBBQBBBBBQBBBBBBBBBBBBBBBBBBBBBBB.                      XBBBBBBBBBBBBBBBBQBBBBBBBBBQBQBBb                                    //
//                                 JBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                     .QBBBBBBBQBBBBBBBBBBBBBQBQBBBBBBL                                     //
//                                  LBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBq                    KBBBBBBBBBBBBBBBQBBBBBBBBBBBBBQ:                                      //
//                                   7BBBBBBBBBBBBBBBBBQBBBBBQBBBBBQBB:                   BQBQBBBBBBBBBBBQBBBBBBBBBBBBBB                                        //
//                                    rBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                  ZBBBBBBBBBBBBQBBBBBBBBBBBBBBBq                                         //
//                                     iBBBQBBBBBBBBBBBBBBBQBBBBBQBBBBBq                .BBBBBBBBQBBBQBBBBBBBBBQBBBBB7                                          //
//                                      iBBBBBBBBBBBBBBBBBBBQBQBBBBBBBBB:               gBBBQBBBQBBBBBBBBBBBBBBBBBBB.                                           //
//                                       :BBBBBBBBBQBBBBBBBBBBBBBBBQBBBBB              .BBBBBBBBBBBBBBBQBBBQBBBBBBB                                             //
//                                        :BBBBBBBBBBBBBQBBBBBBBBBBBQBBBBb             RBBQBBBBBBBBBBBBBQBBBBBBBBP                                              //
//                                         .BBBBBQBBBBBBBBBBBBBBBBBBBBBBBQi           :BBBBBBBBBBBBBBBBQBBBBBBBQv                                               //
//                                          .BBBBBBBBBBBBBBBBBBBBBBBQBBBBBB           QBQBBBBBBBBBBBBBBBBBQBBBB:                                                //
//                                            .r5MBBBBBBBBBBBQBBBBBBBQBBBBBd         :BQBBBBBBBQBQBBBBBBBBB1:                                                   //
//                                                  .LbBBBBBBBBBBBBBBBBBBBBBi        BBBBBBBBBBBBBBBBBgs.                                                       //
//                                                        i1MBBBBBBQBBBBBBBBB       rQBBBBBBBQBQBBbr.                                                           //
//                                                             .rqBBBBBBBBBBBg      BBBBBBQBBB2i                                                                //
//                                                                   :jEBBBBBBs    LBBBQBgJ.                                                                    //
//                                                                         rIBB.  .BQdr                                                                         //
//                                                                             .  ..                                                                            //
//                                                                          iZQ:   :r                                                                           //
//                                                                     .sDBQBBR    :BBBBK7.                                                                     //
//                                                                 :2BQBBBBBQB      7BBBBBBBBMji                                                                //
//                                                             rbBBQBBBQBBBBB2       ZBBBBBBBBBBBBBPv.                                                          //
//                                                        .LDBBBBBBBBBBBBBBBB         BBBBBBBBBBBBBBBBBBM5i.                                                    //
//                                                    :1BBBBBBBBBBBBBBBBBBBBj         iBBBBQBBBBBBBBBQBQBBBBBQZL:                                               //
//                                                 qBBQBQBBBBBBBBBBBBBBBBBBB           EBBBBQBBBBBBBBBBBBBBBBBBBBBBBK.                                          //
//                                               .BBBBBQBBBBBBBBBBBBBBBBBBBL            BBBBBBBBBBBBBBBBBBBBBQBBBBBBBB:                                         //
//                                              iBBBBBBBBBBBBBBBBBBBBBBBQBQ             iBBBBBBBBBBBQBBBQBBBBBBBBBBBBBBi                                        //
//                                             2BQBBBBBBBBBBBQBBBBBBBQBBBBv              PBBBBBBBBBBBQBBBBBQBBBBBBBBBBBBr                                       //
//                                            gBBBQBBBBBBBBBBBBBBBBBBBBBQB                BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBr                                      //
//                                          .BBBBBBBBBBBBQBBBBBBBBBBBBBBBr                :QBBBBBBBBBBBBBQBBBBBBBBBBBBBBBQ7                                     //
//                                         rQBBBBBQBBBBBBBBBQBBBQBBBBBBBB                  PBBBBBBBBBBQBQBBBBBBBBBBBBBBBBBBv                                    //
//                                        5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBi                   BBBBBBBBBBBQBBBBBBBBBQBBBBBBBBBBs                                   //
//                                       QBBQBBBQBBBBBBBBBBBBBBBBBBBBBBB                    :BQBQBBBBBBBBBBBQBQBBBBBBBBBBBQBQu                                  //
//                                     .BBBQBBBBBBBBBBBBBQBBBBBBBBBQBBB:                     KBQBBBBBBBBBQBBBBBBBBBBBQBBBBBBBBI                                 //
//                                    rBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBQ                       BBBBBBBBBBQBBBBBBBBBBBBBBBQBBBBBB5                                //
//                                   2BBBBBBBQBBBQBQBBBBBBBBBBBQBBBBBB:                        7BBBBBBBBBBBQBBBBBQBBBQBBBBBBBBBBK                               //
//                                  RBBBBBBBQBBBQBBBBBBBBBBBBBBBBBBBBQ                           :gBQBBBBBBBBBQBBBQBBBBBBBBBQBBBBP                              //
//                                .BBBBBBBBBBBBQBQBBBBBQBQBQBBBBBBBBB.                              XBBBBBBBBBBBBBBBBBBBBBBBBBBQBBd                             //
//                               rBBBBBBBBBBBBBBBBQBQBBBBBBBQBBBBBMr                                  vBBBBBBBBBBBBBBBBBBBBBBBBBBBBD                            //
//                              5QBBBBBBBQBBBQBBBBBBBBBBBBBBBBBQL                                       :MBQBBBBBBBBBBBBBBBBBBBBBBBQM                           //
//                             QBBBBBBQBBBBBQBBBBBBBBBBBBBBBB1                                             KBBBBQBBBBBBBQBBBBBBBBBBBBQ                          //
//                           .BBBBBBBQBBBBBBBBBBBBBBBQBBBBX.                                                 LBBBBBBBBBBBQBBBBBBBBBBBBB                         //
//                          rBBBBBBBBBBBQBBBBBBBBBBBBBBZ:                                                      iRBBBBBBBBBBBBBBBBBBBBBBB                        //
//                         IBBBBBBBBBQBBBBBBBQBBBBBBQi                                                           .PBBQBBBBBBBBBBBQBBBBBBB                       //
//                        QBBBBBBBBBBBBBQBBBBBBBBB7                                                                 LBQBQBQBQBBBQBBBBBBBBB                      //
//                      .BBBBBBBBBBBBBBBBBBBBBBj                                                                      :RBBBBBBBBBBBBBBBQBBB                     //
//                     7BBBBQBBBBBBBQBBBQBBBS.                                                                          .PBBBBBBBBBBBBBBBBBB                    //
//                    SQBBBQBBBBBBBBBQBBBP:                                                                                sBBBBBBBBBBBQBBBQB                   //
//                   QBBBBBBQBBBBBBBBBMr                                                                                     iQBBBBBBBBBBBBBQB.                 //
//                 .BQBBBBBBBBBBBQBBv                                                                                          .EBBBBBBBBBBBBQB.                //
//                rBBBBBBBQBBBBBBu                                                                                                sBBBBBQBBBBBBB.               //
//               SBBBBBBBBBBBBK.                                                                                                    rBBBBBBBBBBBB.              //
//              QBBBBBBBBBQE:                                                                                                         .EBBBBBBBBQB:             //
//            .QBBBBBBBBMi                                                                                                               uBBBQBQBBB:            //
//           7BBBBBBBB7                                                                                                                    rBBBBBBBBi           //
//          PBBBBBBs                                                                                                                         .EBBQBBBr          //
//         BBBBB5.                                                                                                                              UBQBBB7         //
//       :BBBZ:                                                                                                                                   7BBBBL        //
//      bBB7                                                                                                                                        .RBBS       //
//    .2g.                                                                                                                                             PBR      //
//                                                                                                                                                       Iv     //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract APMX is ERC1155Creator {
    constructor() ERC1155Creator() {}
}