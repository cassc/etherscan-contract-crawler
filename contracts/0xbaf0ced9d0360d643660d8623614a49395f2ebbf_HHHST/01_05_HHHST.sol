// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Season's Tidings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//             .,                                      .,             //
//            .MMN,                                  .dMMb            //
//            dMMMMN.                              .JMMMM#            //
//        `   MMMMMMM, `  `  `  `  `  `  `  `  `  .MMMMMMN   `        //
//           .MMMMMMMMb                          .MMMMMMMM[    `      //
//      `    (MMM/WMMMMN.   `    `   `    `  ` .dMMMM#?MMMF           //
//        `  dMMM} /MMMMN,    `        `      .MMMMM3 .MMM#  `        //
//           MMMM]   TMMMN,       `        ` .MMMMF   .MMMN    `      //
//      `    MMMM]    ,MMMM,   `    `  `    .MMMM^    .MMMN           //
//        `  MMMMb      HMMM,            ` .MMM#`     JMMM#  `        //
//           JMMMN  -MN, MMMN,   `  `     .MMMM`.gM]  MMMMF     `     //
//      `    ,MMMM[ (MMMp.MMMN.       `   dMMM'.MMMF .MMMM\           //
//        `   WMMMN (MMMMh-MMMb   `      -MMMFJMMMMF dMMM#   `        //
//            ,MMMMb.MMMMMbHMMMc        .MMM#JMMMMM!.MMMM^            //
//         `   ?MMMM[?MMMMMkMMMN    `   dMMMWMMMMMF.MMMMF     `       //
//      `       UMMMMxUMMMMNMMMM]  `   .MMM#[email protected]    `   `     //
//          `    WMMMMbVMMMM#MMMN      [email protected]               //
//       `    `   UMMMMNJMMMMMMMM[    [email protected]   `   `        //
//                 ?MMMMMNMMMMMMMN&gggJMMMMMM#dMMMMMF                 //
//                  ,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM^                  //
//                   .WMMMMM#              WMMMMM#'        `          //
//                   .MMMM#'                .HMMMMx            `      //
//                  [email protected]                    UMMMMb                  //
//                 (MMMMF                      ?MMMMb                 //
//                .MMMMF                        ?MMMMb     `          //
//               .MMMMF  .M"TN,          .M"TN,  ?MMMM,               //
//               dMMMF  .MM,.MN          dM,.MM;  4MMMN               //
//              .MMMM`  -MMMMM#          MMMMMM]   MMMMx              //
//             .MMMM^   .MMMMM3          ,MMMMM^   ,MMMN.      `      //
//             (MMM#      7"!              .7"`     HMMMb  `          //
//             MMMM]             .+,.(,             (MMMN             //
//             MMMM\             .WMM#^             .MMMM             //
//             MMMMe              .MM\              .MMM#             //
//             ,MMMMm.       jNa.MMMMMNJ.MR        (MMMM%             //
//              (MMMMN,      ,""""^  ?""""^      .MMMMMD              //
//               (MMMMMN&.                    ..MMMMMM=               //
//         .Jgg-.  ?MMMMMMMNa..............(MMMMMMMM3  ..+gg,.        //
//      .dMMMMMMMMNMMMYHMMMMMMMMMMMMMMMMMMMMMMMM#UMMMgMMMMMMMMN,      //
//     (MMM^   ?WMMMMp   [email protected]^   .MMMM#=   (MMMb     //
//    .MMM`      .UMMMN.    ?""""""""T"""""^    .dMMMB!       MMM.    //
//    .MMF         4MMMN                        dMMMF         JMM)    //
//    [email protected]         .MMMMa..,    ... ..+g, .+MMMNMMMM:         JMM\    //
//     MMN.         MMMMMMMMN .MMMMNMM#MMN?"! TMMMMN         .MMM`    //
//     (MMN,       .MMMM% ([email protected]#D ,MM#.ggdMMMMMa.      .MMMF     //
//      ?MMMMa-..gMMMt   .MMMMMM`.MM] .MMMDTMMMMMm(MMMN...gMMMMD      //
//        ?WMMMMMMM"   .MMMB~MMN.dMMQMMM#(.J...MMM` 7MMMMMMM#=        //
//           .7""!   ([email protected]!    -7""!           //
//                   ?""""""^      ??`                                //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract HHHST is ERC721Creator {
    constructor() ERC721Creator("Season's Tidings", "HHHST") {}
}