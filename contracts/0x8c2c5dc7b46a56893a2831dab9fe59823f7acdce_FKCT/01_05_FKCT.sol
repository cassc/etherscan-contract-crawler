// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fake Creators
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                        dMMM]                                 //
//        `    `                `     `   `     `       `                                 MMMM]                                 //
//          `       `    `         `         `     `         `    `    `    `    `    `   MMMM]                                 //
//      `                   `     ....   ..(gggg+.,   `                                ...MMMMb....  `  `  `  `  `  `  `  `     //
//         `   `       `        ` MMMN .MMMMMMMMMMMMa.    `     `  ..ggNNNgJ           MMMMMMMMMMM#                             //
//                `               MMMNMMM#"=!_?"HMMMMN.      `  .dMMMMMMMMMF  `   `    ???MMMMF???!                             //
//      `  `   `     `      `     [email protected]`        ,MMMMb       .dMMMMMMMMMMB^     ,        MMMM]                                 //
//           `           `        MMMM#           dMMM#   `  .MMMMMMMMMMM#    .(MM[       MMMM]        `  `  `  `  `  `  `      //
//       `                     `  MMMM]           -MMM#      MMMMMMMMMMMMMN..gMMMMM,      MMMM]                                 //
//          `     `   `           MMMM[      `  ` -MMM#     .MMMMMMMMMMMMMMMMMMMMMM]      MMMM]                            `    //
//      `      `           `      MMMM[   `       -MMM# `   ,MMMMMMMMMMMMMMMMMMMMMM]   `  MMMM]    `  `                         //
//         `                  `   MMMM[           -MMM#      MMMMMMMMMMMMMMMMMMMMMM'      MMMM]          `  `  `  `  `  `       //
//                 `   `          MMMM[      `    -MMM#      ,MMMMMMMMMMMMMMMMMMMMD       MMMM]                                 //
//      `   `  `          `       MMMM[   `     ` -MMM#       .HMMMMMMMMMMMMMMMMM=        MMMMF   `                        `    //
//        `                       MMMM[           -MMM#  `      (WMMMMMMMMMMMMM"      `   dMMMN,...   `                         //
//                `  `       `  ` MMMM[      `    -MMM#            ?TWMMMMY"=             ,MMMMMMMM,     `  `  `  `  `  `       //
//      `   `  `        `         MMMM\  `        -MMME    `                                THMMMMM%                            //
//                         `                    `             `                      `  `                                  `    //
//       `   `                  ` b d.E-<.,...b (W"d.,.. .M.M..,...,.  jR  ..,...p ......,..,.,.d..,  `                         //
//         `     `  `  `          D  B,D-yF9,>5  ? ?.t8J .$97JJY4.%F(` 5d\ ? $5,^b ,!4J?L>T.$$,nV(d%     `  `  `  `  `  `       //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FKCT is ERC721Creator {
    constructor() ERC721Creator("Fake Creators", "FKCT") {}
}