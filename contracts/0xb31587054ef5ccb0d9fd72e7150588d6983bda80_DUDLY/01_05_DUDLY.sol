// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dudly
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                              //
//                                                                                                                                              //
//                                                                                                                                              //
//                                                 .:i7jPggQQBBBBBBBBBBBQQggPJ7i:.                                                              //
//                                         .LXMBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBgSv.                                                      //
//                                   .rPBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQqi                                                 //
//                               :1BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBJ.                                            //
//                           .sBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQv                                         //
//                        .XBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBI.                                     //
//                      1BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBs                                   //
//                   :QBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBg.                                //
//                 rBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi                              //
//               iBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBRQBBBq7ri:.JBBBBBu.:ir7qBBBQQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB:                            //
//              BBBBBBBBBBBBBBBBBBBBBBBBBBBQqjr.     :BBB      .BBBBB:      BBB      .7uPBBBBBBBBBBBBBBBBBBBBBBBBBBBM                           //
//            YBBBBBBBBBBBBBBBBBBBBBBBBv.            iBBB:     iBBBBBr     :BBB.            .sBBBBBBBBBBBBBBBBBBBBBBBB7                         //
//           QBBBBBBBBBBBBBBBBBBBBBBB.       .Y.     rBBB:     iBBBBBr     :BBB:     :v.       :BBBBBBBBBBBBBBBBBBBBBBBZ                        //
//          BBBBBBBBBBBBBBBBBBBBBBBB      BBBBB2     rBBB:     iBBBBBr     :BBB:     DBBBBB      BBBBBBBBBBBBBBBBBBBBBBBB                       //
//         BBBBBBBBBBBBBBBBBBBBBBBBB      BBBBBv     rBBB:     iBBBBBr     :BBB:     IBBBBB      BBBBBBBBBBBBBBBBBBBBBBBBB                      //
//        BBBBBBBBBBBBBBBBBBBBBBBBBB      BBBBB7     rBBB:     iBBBBBr     :BBB:     2BBBBB      BBBBBBBBBBBBBBBBBBBBBBBBBB                     //
//       XBBBBBBBBBBBBBBBBBBBBBBBBBB      BBBBB7     rBBB:     iBBBBBr     :BBB:     UBBBBB      BBBBBBBBBBBBBBBBBBBBBBBBBBY                    //
//       BBBBBBBBBBBBBBBBBBBBBBBBBBB      BBBBB7     rBBB:     iBBBBBr     :BBB:     UBBBBB      BBBBBBBBBBBBBBBBBBBBBBBBBBB                    //
//      PBBBBBBBBBBBBBBBBBBBBBBBBBBB      BBBBB7     rBBB:     iBBBBBr     :BBB:     2BBBBB      BBBBBBBBBBBBBBBBBBBBBBBBBBBJ                   //
//      BBBBBBBBBBBBBBBBBBBBBBBBBBBB      BBBBBJ     rBBB:     7BBBBBY     :BBB:     PBBBBB      BBBBBBBBBBBBBBBBBBBBBBBBBBBB                   //
//      BBBBBBBBBBBBBBBBBBBBBBBBBBBB      BBBBB7     rBBB:     iBQMQBi     :BBB:     1BBBBB      BBBBBBBBBBBBBBBBBBBBBBBBBBBB                   //
//      BBBBBBBBBBBBBBBBBBBBBBBBBBBB                 iBBB.                 .BBB.                .BBBBBBBBBBBBBBBBBBBBBBBBBBBB                   //
//      BBBBBBBBBBBBBBBBBBBBBBBBBBBBBq:              rBBB:                 :BBB:              idBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                   //
//      BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                   //
//      SBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB2      .BBBQ ..... BBBBBB       JBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBL                   //
//       BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBv       BBBX       gBBBBB       7BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                    //
//       uBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBJ       BBBb       BBBBBB       vBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBr                    //
//        BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBJ       BBBd       BBBBBB       vBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBg                     //
//         BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBJ       BBBP       ::...:       LBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                      //
//          BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBJ       BBBS                    vBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQ                       //
//           dBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBY      .BBBQ .......:.:iY       7BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBS                        //
//            rBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBv      .BBBBBBBBBBBBBBBBB       LBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB:                         //
//              ZBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                    PBBB      :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP                           //
//               .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBDi                 IBBB   .JBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQ.                            //
//                 :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBMEPPPPPPPPqKBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBR.                              //
//                   .bBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBK                                 //
//                      7BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBr                                   //
//                         LBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB7                                      //
//                            igBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBEi                                         //
//                                7ZBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBdr                                             //
//                                    :JDBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBdY:                                                 //
//                                         .ivbBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP7:                                                       //
//                                                    .:i77Ljj125SXS52ujuL7ri:.                                         DUDLY2022               //
//                                                                                                                                              //
//                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DUDLY is ERC1155Creator {
    constructor() ERC1155Creator("Dudly", "DUDLY") {}
}