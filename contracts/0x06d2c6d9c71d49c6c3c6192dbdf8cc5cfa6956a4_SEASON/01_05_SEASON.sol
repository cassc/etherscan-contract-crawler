// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Satsuki Minato Season Collection!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//      `                     `                 `          `          `            `           `            //
//         `  `  `    `  `       `  `  `             `        `          `      `     `           `    `    //
//                `         `                 `         `          `                        `               //
//     `  `   `      `  `               `      `  `        `          `    `       `           `    `       //
//         `      `   `      `   `  `                `        `          `      `     `           `    `    //
//                        `                   `                    `                        `               //
//     `  `   `  `            `        `                `  `          `            `   `       `            //
//         `      `  ``  `   `   `  `     `   `  ` `          `          `      `                 `         //
//                   ..MB"  ..MB^    .gmTTTTTQg,    .JJJ+g,        `  .M#            qN,    `          `    //
//     `  `   `  ` .M8> ...d#^       .MF     dM:        (M%  [email protected]   ...MMa.,  WMx   `  WM,   .(MY"`  `       //
//         `       dM,MLMF   .M#=    [email protected]""TCwMM~       .MN....MF     -Mt      .WN,     [email protected]^               //
//      `        `  ?~M#7`..MD`   `  .Mb.....dM~    (M"OMF`  (MF7`  .MF     MM  ("5    .MM8                 //
//        `  ` `   ?7dMNc!    .gR_   ,M]     dM`  `(M\ dM    .M]   .M#  .(xgMN,       JM!      `  ` `  `    //
//                 .d#M#W8 [email protected]'     ,M]     dM    (M].Mt    JM!      .M"  .M#?Hm,    MN,                   //
//     `   `      ` `.MF  (M"        .M\    .dM`    ?"7     .MF       HMJ..M#'  -"'    7"MMHmQkW"^          //
//            `                  `                                 `     `                             `    //
//      ` `  `  `  `      `  `  `  `    `  `   `  `       `              `         `          `   ` `       //
//         `         `   .....    .,    .,         ` `  ..,   `    `  `               `   .                 //
//               `   """M#       .ML...(M-...  `     .JT=     ?"""""""=    (+<<<<??<ge   (#      `     `    //
//     `  `       `.??qMMMN277' .MF Mb."'J#`      .JW#        +&++???1gg          .M=    d#   `             //
//         `  `    .JB&.Mb.dN,   dN"TM%M#"7N]  .g"` J#    `          JB`        .#^      d#4+..     `       //
//      `      `        dMP! ("  dN-(M\MF .M]       dF  `    `     .MF   ` `  .M"N,   `  dF    ?"      `    //
//         `     ` ,"""""M#"""^  [email protected](N, MF?T"\       dF            .M$       .M=   ?N,    MF                 //
//                     ?"""      T"'.! "5       `   ?t     `     ."^       d"       ?5`  T$       `         //
//     `  `   `   `                                           `                                     `  `    //
//         `          `                                               `  `                    `             //
//                `      `   `                 `        `  `                       `  `          `          //
//     `  `     `     `           `     `          `          `                  `          `               //
//         `       `      `                     `                  `  `  `                     `    `       //
//            `       `      `      `                   `  `                          `                `    //
//     `  `      `      `        `     `      `      `        `            `    `  `        `     `         //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SEASON is ERC1155Creator {
    constructor() ERC1155Creator("Satsuki Minato Season Collection!", "SEASON") {}
}