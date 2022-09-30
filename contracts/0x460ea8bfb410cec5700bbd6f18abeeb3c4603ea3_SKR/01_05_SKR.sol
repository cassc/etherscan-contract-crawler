// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SAKURA
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//       `  `  `  `  `  `   `  `   `  `   `   `  `                                                          //
//                        `                        `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `        //
//           `   `                   `  `   `                                                         `     //
//       `          `        `  `  `           `                                                            //
//                      `                                                                                   //
//            `                             `      `  `  `   `  `  `  `   `  `  `  `  `  `  `  `            //
//         `       `      `     .MN     `                                                          `        //
//                     `     .JMMMMb           `                                                      `     //
//      `      `    `      .dMMMMMMM,     `      `  `     `          `  .............,                      //
//        `  `   `       .JMMMMMMMMMN. `    `          .....JggNMMMMMMMMMMMMMMMMMMMMMMN,  `  `  `           //
//                    ` .MMMMMMMMMMMMb       ...JgNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"""`             `  `     //
//                 `  .dMMMMMMMMMMMMMMu(gMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMY""`        `                    //
//      `  `  `  `   .MMMMMMMM#""!     MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM""!                        `           //
//                  .MMMY"=`           ,MMMMMMMMMMMMMMMMMMMMMMMY"!                        `  `         `    //
//       `  `      ,"`                  -MMMMMMMMMMMMMMMM#"=`                        `             `        //
//             `                   `     4MMMMMMMMMM#"^                          `      `                   //
//      `    `   `                        HMMMM#"^                         `  `                `      `     //
//        `             `    `  `    `    ."=                        `  `          ..........JJ;  `         //
//              `   `     `           .(MMMb                     ` .....JggNMMMMMMMMMMMMM#"=                //
//          `                    ..+MMMMMMMMb          ....JgNMMMMMMMMMMMMMMMMMMMMMMMMMMM             `     //
//                           ..gMMMMMMMMMMMMM[...ggMMMMMMMMMMMMMMMMMMMMMMMMMMM""! MMMMMM#                   //
//        `          `    .+MMMMMMMMMM"""!    WMMMMMMMMMMMMMMMMMMMMMMMMM#"=       MMMMMMF                   //
//            `       .(MMMMMM""7`             MMMMMMMMMMMMMMMMMMMMY"!           .MMMMMM]       `           //
//               `..dMH""!                     .MMMMMMMMMMMMMMY"!                .MMMMMM:                   //
//              ("^                             ,MMMMMMMMY"!                     (MMMMMM                    //
//        `  `                                   (MM#"^                          dMMMMM#  ....(gg]          //
//                                             ..+p                         `   .M"""^`.MMMMMMMMM^          //
//                                        `..gMMMMM|                  ....JgMMMMM      JMMMMM9^             //
//                             `       ..MMMMMMMMMMM,         ...+gMMMMMMMMMMMMM#      MM9=                 //
//          `               `     `..MMMMMMMMMMMMMMMM,..(gMMMMMMMMMMMMMMMMMMMMMMF   ..g                     //
//             `               ..gMMMMMMMMMMMMM""7`   MMMMMMMMMMMMMMMMMMMMMMMMMML.&MMM#                     //
//                    `    `.(MMMMMMMMMY""!           .MMMMMMMMMMMMMMMMMMMMMMB= dMMMMMF                     //
//        `        `     .gMMMMM""7`                   .MMMMMMMMMMMMMMMMMB=     MMMMMM]        `            //
//            `       .dMY""`                           ,MMMMMMMMMMMMB=        .MMMMMM{                     //
//                   !                                   ,MMMMMMMY"            .MMMMMM      `               //
//                                                        ,MMY"                (MMMMM#                      //
//        `  `   `                          `  `    `    .JR                   dMMMMMF   `     `            //
//                                   `  `            .JMMMMMb                  MMMMMM]                      //
//                              `                .JMMMMMMMMMMb             `   MMMMMM\                      //
//                   `      `                .JMMMMMMMMMMMMMMMb     `  `      [email protected]`       `  `            //
//          `  `        `          `     .JMMMMMMMMMMMMMMMMMMMMb              .MM"       `                  //
//                                   .(MMMMMMMMMMMMMMMMMMMMMMMMMb`            (`                            //
//                 `           `     ?YMMMMMMMMMMMMMMMMMMMMMMMMMMb        `                                 //
//        `                 `            ?TWMMMMMMMMMMMMMMMMMMMMMMR  `                `      `  `           //
//           `        `                        _7"""HMMMMMMMH""""!                `      `                  //
//               `               `                                     `   `  `                             //
//                        `          `                                                `                     //
//            `                `        `                            `           `          `  `            //
//        `        `  `                                                                  `                  //
//                          `      `        `                           `  `  `      `                      //
//                                     `       `               `   `              `                         //
//                                                                                                          //
//                                                                                                          //
//                   (NR      `    .gNNNNNNNNNNNNNNNNNNa   NNNNNNNNNNNNNNNNNNNP   (NNNNNNNNNNNNNNNNNN]      //
//                   JM#   `       MM#""""""4MM""""""TMM~  """"""""YMM"""""""""   J""""""""""""""""""^      //
//        ` ..,  `   JM#      ...  MMF      ,M#      .MM~          .M#             JMMMMMMMMMMMMMMMN,       //
//         .MM]      JM#      (MM` MMF      ,M#      .MM~          .M#             JMNggggggggggggMM[       //
//         .MM]      JM#      (MM` MMb......,M#.......MM~          .M#             JM#"""""4M#""""""        //
//         .MM]      JM#   `  (MM` MMMMMMMMMMMMMMMMMMMMM~          .M#             gMNgggggMMNgggggggm      //
//         .MM]    ` JMN      (MM` MMF      ,M#      .MM~          .M#          `  dMF?????dMF???????!      //
//         .MM]      gMN      (MM` MMF      ,M#      .MM~   `  `   .M#       `    .MM!    .MMMMMMMMMMb      //
//         .MM]      dMN      (MM. MMF      .M#      .MM~          .M#   `        (MF   .JM#`      MMF      //
//       ` .MMNNNNNNNMMMNNNNNNMMM` MMNNNNNNNMMMNNNNNNNMM~.NNNNNNNNNNMMNNNNNNNNNR .MH` .MMM"     .JJMM`      //
//          T""""""""""""""""""""  ?"""""""""""""""""""" ."""""""""""""""""""""" .=    7!       T"""^       //
//                                                                                                          //
//                                                                                                     `    //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKR is ERC1155Creator {
    constructor() ERC1155Creator() {}
}