// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VELMIX
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                           .(ga,                                                          //
//                                          .MMMMMb                                                         //
//                                         .MMMMMMF                                                         //
//                 ...,         `    `   `.MMMMMM#   `    `                                                 //
//             `  JMMMMN.  `             .MMMMMMM`           `  `  `  `  `  `  `  `  `  `  `  `  `  `       //
//        `      .MMMMMMb     `    `     JMMMMMM^                                                      `    //
//           `    dMMMMMM[           `  .MMMMMMF     `  `                                                   //
//                 HMMMMMM,     `      .MMMMMM#  `         `                                        `       //
//                 .MMMMMMN.           JMMMMMM'               `   `   `   `   `    `   `   `   `            //
//       `          ,MMMMMMN.        `.MMMMMMF       `          ...,                                        //
//          `        (MMMMMMh     `   MMMMMM#      .MMNJ `     .MMMMN,          `                `   `      //
//             `      ?MMMMMMb  `    .MMMMMM%     dMMMMMb     .MMMMMMb   `  `      `  `  `  `               //
//       `         `   TMMMMMMb     .MMMMMMF     .MMMMMM#     MMMMMMMN.                        `       `    //
//                      4MMMMMMb    (MMMMMM`    .MMMMMMMM   `JMMMMMMMM[      .MMMa.            .+NNa.       //
//          `  `         4MMMMMMb  .MMMMMMF     (MMMMMMMM;  [email protected]     (MMMMMN           JMMMMMN       //
//                `       4MMMMMMb dMMMMM#     .MMMMMMMMM]  MMMMMMMMMMM.    -MMMMMMb   `  ` .MMMMMMMF       //
//       `                 4MMMMMMNMMMMMM'     dMMMMMMMMM# .MMMMMMMMMMM]     WMMMMMM,      .MMMMMMMF        //
//           `       `      4MMMMMMMMMMMF     [email protected]     .MMMMMMN     .MMMMMMM3         //
//         `    `  `    `    4MMMMMMMMMM`     MMMMM(MMMMMMMMMMMM!JMMMMMM.     -MMMMMM]  .dMMMMMM#`     `    //
//       `                    UMMMMMMMMF     .MMMMt MMMMMMMMMMMF ,MMMMMM]  `   WMMMMMM,.MMMMMMMF            //
//                             UMMMMMM#  `   MMMM#  JMMMMMMMMM#   MMMMMMN      .MMMMMMNMMMMMMM3             //
//            `    `    `   `   UMMMMM^     .MMMM\  ,MMMMMMMMMt   JMMMMMM.      (MMMMMMMMMMMH!       `      //
//       `                       .""=       MMMMF    MMMMMMMM#    .MMMMMM]       MMMMMMMMMMD                //
//                                         .MMMM\    JMMMMMMM]     HMMMMMN       .MMMMMMMMD                 //
//              `       `                  dMMM#     .MMMMMMM      -MMMMMM;   `  .MMMMMMM%          `       //
//          `       `                     .MMMM\      MMMMMM#       MMMMMMb     (MMMMMMMMN                  //
//                   ..     `             .MMM#       -MMMMM^       JMMMMMM.   dMMMMMMMMMM[      `          //
//                  -MMMNJ.     `         gMMM]         .?`         .MMMMMM\ .MMMMMMMMMMMMN                 //
//                  .MMMMM#'              dMMM`                      ?MMMMD .MMMMMMMBMMMMMMb        `       //
//              .&g-.MF                    7"!                             .MMMMMMM3 WMMMMMM,  `            //
//          `   MMMMMMF              `                         `          .MMMMMMM^  .MMMMMMb               //
//               TMMMMF        ....J++J...                         `     .MMMMMMM'    JMMMMMMc     `        //
//                .TMM]    .+MMMMMMMMMMMMMMNJ.       `                  .MMMMMM#`      MMMMMMN              //
//                   `  .dMMM#"!      ...?TMMMN,         `             .MMMMMM#        ,MMMMMM]  `          //
//                    .MMMMNMMMN,   .M#"MN, .TMMN,           `       `[email protected]          WMMMMMM,     `      //
//                  .dMMD([email protected](g,4M,  MF-MN(M]  .WMMe   `           `  (MMMMMMD           .MMMMMMb            //
//          `      .MMM' M# MMF(M!  JM,T#!M#    TMM[           `    JMMMMMMF             (MMMMMM]           //
//                 MMM`  WN,..dMD    ,HNNM#^     MMN      `        JMMMMMMF               WMMMMMM,          //
//              ` -MM\    ?"H""`                 JMM_             JMMMMMMF           `    .MMMMMMN   `      //
//                dMM                            JMM`        `   JMMMMMMF                  -MMMMM#          //
//                dMM.                          .MM#     `      JMMMMMMF                    ."MH"           //
//          `     .MMb                         .dMM'           JMMMMMMF       `    `                        //
//                 (MMN,                      .MMM^           (MMMMMMF                 `                    //
//                  .WMMNJ.              ` ..MMMD        `   (MMMMMMF                               `       //
//                    .TMMMMMNggJ((....JgMMMMM"             JMMMMMMF       `   `    `                       //
//                        _""WMMMMMMMMMMMY"=           `   JMMMMMMF                        `     `          //
//          `                                             (MMMMMMF                     `                    //
//              `                                         .MMMMMD       `   `   `   `          `     `      //
//                                                   `       ?!                             `               //
//                                                `                                                         //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VMX is ERC1155Creator {
    constructor() ERC1155Creator("VELMIX", "VMX") {}
}