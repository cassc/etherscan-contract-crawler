// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Luv Luv Edition!
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//       `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `      //
//                                 ...JggggJ.,                                                               //
//                   ..         .(MMMMMMMMMMMMMm,                                                    `  `    //
//      ` `  ` `  ` MMMp `  ` .dMMB=  .JMMMMMMMMMp ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `          //
//              .MMMMMMM,    [email protected]` .MMMM"=`   TMM#                                                           //
//               7MMMMMMF    JM# .MM#=       .JMMa.+ggNNNNNNgg&(...   .(gNNNNgJ..-....              `  `     //
//      `  `  `     ?"HD   ` -MMMMM^    ..+MMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMMMMMMMMMMMMMNa,`  ` `  `          //
//                       ..MMMMMMMMa..gMMMMMMMMMMH"""7!!````~?7"T"MMMMMMMMMMMMMMMMMMN/THMMMa,                //
//        `  `   `     .dMMMMMMMMMMMMMMMMMMY=                        7WMMMMMMMMMMMMMMN,  ?MMMN,    `  `      //
//      `             .MMMMMMMMMMMMMMMMM"`        MMa.        ..        (YMMMMMMMMMMMMN    ?MMMx       `     //
//            `   `  [email protected]`.+,        -MMMMN&,   ,MMN,         TMMMMMMMMMMM-    .MMM[ `          //
//        `  `    .JMMMMMMMMMMMMMMMD   MMF    `    dMMMHMMMN,  TMMm.  `      TMMMMMMMMM]     .MMM.  `        //
//      `        .MMMMMMMMMMMMMMMD    .MM\         .MMM[ ?HMMN, ,MMM,         .UMMMMMMM] `    dMM]    `      //
//             .dMMMMMMMMMMMMMMM^     dM#  `   `    MMMN.  .WMMN, TMMm  ..,     (MMMMMM%   `  ([email protected]      `    //
//         `  .MMMFJMMMMMMMMMMF      .MMF           (MMM]    ,MMMN,JMMN.?MMN,    .MMMMp       -MM#           //
//            MMMF (MMMMMMMMMD      .MMM]           .MMMN      ?MMMN,MMN  TMMm     WMMMb      .MM#           //
//           JMMF   WMMMMMMM$       dMMM\           .MMMM_       TMMMMMMb  ,MMN,    MMMMb     (MM#           //
//          .MMM`    TMMMMMF   .MM[-MMMM[            MMMM)        ,HMMMMM[  .MMM,   .MMMM]    (MM#           //
//          (MMF     .MMMMF    .MMhMMMMM]            MMMM]          (T"MMN    WMM,   (MMMM,   .MMM           //
//          dMM]     dMMMM`    -MMMMM4MMN            MMMM\             (MM|    MMN,  .MMMMb    MMM]          //
//          MMM]    .MMMMF     JMMMMF.MMMb.....J+gggMMMMM`             .MMb    .MMb  .MMMMN    -MMM,         //
//          MMM]    (MMMM`     dMMM#  [email protected]               [email protected]     dMMa.dMMMM#     (MMMp        //
//          dMMN    MMMM#      MMMM'   [email protected]""""""7!                    MM#     .MMMMMMMMMF      ,MMMN.      //
//          (MMM.  .MMMMF      MMMF   ..+.                        .     MMF      MM#  TMM#         WMMN      //
//          .MMM[  .MMMM]      MMMF   MMMM.                    [email protected]   .MMF      MM#  .MMM          MMMb     //
//           MMMF  .MMMM]      [email protected]   dMMM|             ..gMMMMMMM"    .MM>     .MMMMb.MMM          JMM#     //
//           MMM#  .MMMM]      MMMN   JMMM]             XMMW""""!      MMF      dMM"=.MMMF          JMM#     //
//           dMM#  .MMMM]      dMMM.  .MMMF                           JMM<(Mb..dMM$ .MMMM`          MMMF     //
//           MMMF   MMMMb      JMMM[   ?""`                         .dMMMMMMMMMMMNMMMMMB`          .MMM]     //
//          .MMM]   MMMM#      .MMMF               .MMc            .MMMMM"T"MMMMMMMMMB^            (MMM`     //
//          .MMM!   dMMMM.     .MMMN          [email protected]             dMMMMD    _""""MMMh.            (MMN.     //
//          dMM#    .MMMMMb     MMMM-          7"""=             .MMMM#!          .HMMMNx.         .MMMb     //
//         .MMM]     MMMMMMN..a.(MMM]                         .gMMMM#'              (YMMMN.         MMMM[    //
//         (MMM`     (MMMMMMMMMN.MMMN,.                  ..JMMMMMM"`                 .JMMM^        .MMMM]    //
//         MMMF       TMMMBMMMMMNMMMMMMMNg...........JgMMMMMMMM"`                   .MMM#!        .MMMMM`    //
//        .MMM]           MMM?"MMMMMMFTMMMMMMMMMMMMMMMMMM#"=                       JMMMD        .MMMMM#`     //
//        .MMM)          .MMF  .WMMMMN     ?7""""""7!`                            dMMM^       .dMMMMMD       //
//         MMM]          .MM]     7MM#                                           -MMM^     ..MMMMMMP`        //
//         ?MMM,         .MMF                                                    MMMF    .uMMMMMMD`          //
//          ?MMMMNJ..    .MM#                                                    MMMb  .MMMMMM#=             //
//            ?YMMMMMMa.  MMM.                                                   MMMM,[email protected]!               //
//                 ?YMMM, dMM]                                                   [email protected]`                 //
//                   ,MMN.JMM]                                                     7MMMMM#                   //
//                    dMM{JMMF                                                       ,MMMt                   //
//                   .MMM`dMM\                                                                               //
//                   JMMF.MMF                                                                                //
//                  .MMMMMMD                                                                                 //
//                  ?MMMY"                                                                                   //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LLE is ERC721Creator {
    constructor() ERC721Creator("Luv Luv Edition!", "LLE") {}
}