// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BIG LUV!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//        `  `  `  `  `  `  `  `  `  `  `  `  `....(J&ggggg&&J..... `  `  `  `  `  `  `  `  `  `  `  `       //
//                                        ..gMMMMMMMMMMMMMMMMMMMMMMMNg,.                                     //
//                                    ..MMMM#"=`               ?7THMMMMMNa,                             `    //
//       `                         .+MMMB"                           7HMMMMNJ.                               //
//          `  `  `  `  `  `  `  .MMM"!      ..(gMMMMMMMMMMMMMNag...    ?WMMMMm,  `  `  `  `  `  `  `        //
//                             .MMM"     .JMMMMMMMMMMMMMMMMMMMMMMMMMMNJ,   TMMMMN,                     `     //
//                           .dMMY    .MMMMMMY"^              ?7""MMMMMMMN,  ?MMMMm.                         //
//       `                  .MM#`  .(MMMM#=                         -THMMMMN,  /MMMMNNNNg,,                  //
//          `  `  `  `  `  .MMF   .MMMM=                                TMMMMN.gMMMMMMMMMMMMa.  `  `  `      //
//                     ....MMF  .MMMM=                                    TMMMMMM#"!  .JMMMMMM,              //
//                  .dMMMMMMMMN.MMMD                     `                 .MMMMb   .MMD` .MMMMb             //
//       `        .MMM"[email protected] .MMMMM$       ....    `  `     ..ggNgJ,          MMMM,.M#= .gMM"?MMM]            //
//          `  ` .MMt  .MF .M#MMM^     .MMMMMMMm,        .dMMY"""MMN,        ,MMMMB'..MM#!   MMMN   `  `     //
//              JMM!  .MF [email protected]    .MMB'....TMMp      .MMF.dMMN,?MM,        WMMMagM#=,Mh.  dMMM`           //
//             .MM!  .MF [email protected]     dMF MMMMM],MMgNNMNNMMM MMMMMM_MMF         MMMMY    .MN. dMMM`           //
//             MMF  .MF [email protected]`     MMb.MMMMMF.MM=!!!!!?MMx?MMMMD.MM%         (MMMb     .MN.MMM#            //
//            .MM} .MF [email protected] .MM%      ,MMe.TH"".dMF       -MMN,.(.JMMD           MMMN       TMMMM%            //
//            .MM[.M# .MMN,dMM        ,WMMNggMMM"          7HMMMMM"`            dMMMNa,....MMMM%             //
//             MMNJM'.MM`?WMMF           ?""""!                                 (MMMMMMMMMMMMD               //
//             ,MMM].MM!  .MMF                                                  .MMMFT"MM""'                 //
//              ,MMMMM\ ..MMM%                                                  .MMMF                        //
//                ?MMMMMMMMMM:                                             .g.  .MMMb                        //
//                   ?"""`MMM`                                             .M]  .MMM#                        //
//                       .MMM  .g,                         .&a,.           .M#   MMMN                        //
//                       .MMM  .MF            .MMN.       .MMMMMa.         .MM.  MMMM.                       //
//                       .MMM  [email protected]          .MMMMMMN,    .MMMMMMMMm.        MM|  dMMM}                       //
//                       (MMM. (M#        .dMMMMMMMMMh. .MMMMMMMMMMMNJ      MMb  JMMM[                       //
//                       JMMM` dM#       .MMMMMMMMMMMMMaMMMMMMMMMMMMMMN,    dMN  JMMM]                       //
//                       dMMM  dMN      .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF   JMM} JMMM%                       //
//                       MMM#  MMN     .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM`   (MM] dMMM)                       //
//                      .MMMF  MMM_    -MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM`    JMM] -MMMb                       //
//                      MMMM`  MMM)     ,MMMMMMMMMMMMMMMMMMMMMMMMMMMM#`     dMM]  MMMMN.                     //
//                    .JMMMt   MMM]       TMMMMMMMMMMMMMMMMMMMMMMMMMF     ..MMM]   7MMMMa.                   //
//                 ..MMMMMt    dMMb        (MMMMMMMMMMMMMMMMMMMMMMM^  ..MMMMMMM'    ,HMMMMMa,.               //
//            ..gMMMMMMMD      ,MMM,         TMMMMMMMMMMMMMMMMMMMD  dMHMMMMMN.        (YMMMMMM,              //
//            MMMMMMY"`        MMMMMMNNggg-.  .WMMMMMMMMMMMMMMMMb          ,MM,    ..    .MMMM!              //
//            dMN     .JN,    .MM%7HMMMH""!     (MMM"""""""""""MMMNgggggggg..MM,  [email protected]`               //
//            (MM, ..MMMM#    dMM.MM"         .MMM^             .""""""""""MMMMNgNMM7YMMMMD                  //
//             ?MMMMM"!MMNNNagMMFdML.....(++gMMM"                             ?"""7                          //
//                      ?""""WM" ,WMMMH"""""""!                                                              //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BLV is ERC1155Creator {
    constructor() ERC1155Creator("BIG LUV!", "BLV") {}
}