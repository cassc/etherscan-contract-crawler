// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MINT GUM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//         `                       `            `                      .....                                                    ...+gNNNNNNgJ..                                ....-J-....                      //
//            `                       `            `            ..gMMMMMMMMMMMMNg..                                         ..gMMMMMMMMMMMMMMMMMNa.                        ..MMMMMMMMMMMMMMNg,.                 //
//                `  `  `  `   `           `           `  `  .MMMMMMMMMMMMMMMMMMMMMNa.   `   `  `   `    `    `    `    ` .MMMMMMMMMMMMMMMMMMMMMMMMMa.                   .MMMMMMMMMMMMMMMMMMMMMN,               //
//        `                       `           `           .JMMMMMMMMMMMMMMMMMMMMMMMMMMN,                                .MMMMMMMMMHZuZuZuZuZWMMMMMMMMMm.               .MMMMMMM#9=<:~~?7TWMMMMMMMN,             //
//           `                       `  `        `  `    .MMMMMMMMUZZuuZuZZZZuZZWMMMMMMMN,            `     `         .MMMMMMMMZZZuZZuZuZuZuZZuZUMMMMMMN,  `  `  `  ` .MMMMMM5~~_.._:~::~::(TMMMMMM[  `  `      //
//              `           `              `           .MMMMMMMSZZZuXgNMMNmkuZuZZZZWMMMMMMN.     `       `      `    .MMMMMMHZuZuZZuZuZZuZZuZZZZZZXMMMMMMp           (MMMMM5~_.~~___:~~:~~:~::dMMMMM|           //
//       `         `  `  `     `  `                   .MMMMMMSZuZuXdMMMMMMMMNkuuZuZZuWMMMMMM,                       dMMMMMBuZuZuZuuZuZuZuZudMMMMMMMMMMMMMMp         (MMMMM3~____~:~:~::~::~~~:~JMMMMN           //
//          `                                 `   `  .MMMMMMZZuZuZdMMMMMMMMMMNZZuZuZZZXMMMMMMp      `              dMMMMMSuZuZuZZuZZuZZuZZXMMMMMMMMMMMMMMMM|       .MMMMM3~(fNm+MN;:~~_uNJ((J,:~MMMMM|     `    //
//                                   `  `            MMMMMMZuZZuZuMMMMMMMMMMMMSZZuZuuZZuMMMMMMp                   dMMMMMSuZZuZuZuZZuZuZuuZuXMMMMMMMMMMMMMMMN      .MMMMM5~_.(MMMM5:~::~TMMMMM5~~dMMMM]          //
//             `           `               `        -MMMM#ZuZuZuZZdMMMMMMMMMMMuuZuZZuuZZudMMMMML  `    `  `  `   .MMMMMSZZuZZuZuZuuZuZuZZuZuZZuZZuZZuZZMMMMM[     [email protected]:~:dMMMMMp~:~:(MMMMMm:~:dMMMM]          //
//       `  `     `  `  `     `  `             `   .MMMMMHuZZuZZuZuWMMMMMMMMMZZuZZuZZuZuZudMMMMM,               .MMMMMHZZuZuZuZZuZZuZZuZuZZuZuZuZuZuZZZMMMMMF   `(MMMM#:~..(T>:7B3:~:~?HB>dMM<:(MMMMM\   `      //
//                                  `              .MMMM#uZuZZuuZuZZZXWHHHXZuuZZuuZuZZuZuZZMMMMMN.              dMMMM#ZuuZuZuZuZuZZuZuZuZuZZuZuZuZuZuuZdMMMM#   .MMMMMC~:~::~:(ggJ-:~:~:~~::~:~(MMMM#           //
//             `                       `  `        dMMMM#ZuZuZuZZuZuZuZuZZuZZuuZuZQgNMMNmkZZMMMMMb   `         .MMMMMZZuZZuZZuZuZuuZuZuZuZuZQMMMMMMMMMMMMMMM#  .MMMMMD:~:~:~:~?MMMMMNaJ~::~~:~:dMMMMF      `    //
//                        `  `   `           `  `  MMMMMHuZuZuZuZZuZuZuZuZuZuZZuQMMMMMMMMMNZXMMMMM,     `  `   dMMMM#ZuZZuZuZuZZuZZuZZuZZuZuMMMMMMMMMMMMMMMMF [email protected]:~:~:~:~::~:~?THMB:~:~:~:(MMMMM`   `       //
//        `        `  `                           `MMMMMKZuZZQNNMNNkZuZZuZZuZuZZMMMMMMMMMMM#uMMMMMb           [email protected]~~:~:~:~:~~:~~:~:~:~:~:~:(MMMMMF            //
//           `                      `              MMMMMHuZqMMMMMMMMMRZuZuZuZuuZMMMMMMMMMMM#ZXMMMMM,          (MMMM#ZuZuZuZuZuZuZuuZuZuZuZuZuuuZuuZuuuXMMMMMMMMMMM5::~::~:~:~::~::~:~:~~:~:~~(MMMM#             //
//              `                      `           dMMMM#ZXMMMMMMMMMMMKZuZuZZZuZdMMMMMMMMMMHuuMMMMMb          MMMMMHuZuZuZuZuZuZZuZZuZZuZuZuZZuZuZuZZudMMMMMMMMM#<:~~:~~:~:~:~~:~~:~:~::~:~:(MMMMM\             //
//       `             `  `  `  `         `  `     -MMMMNZdMMMMMMMMMMM#uZZuZuZZuZVMMMMMMMMSZuZdMMMMN.  `     .MMMMMXuZZuZuZuZuZuZZuZZuZuZZuZZuZZZuZZuXMMMMMMMM#>:~:~::~:~:~:~::~::~:~:~~:~:~+MMMM#        `     //
//          `      `              `            `    MMMMMKXMMMMMMMMMMMSZuZZuZuuZuZuZUWWUZuZuZZZMMMMM|     `  .MMMMNZZuZuZZuZuZuZuZuuZuZZuZuQNNNNNNNNNMMMMMMM8<~:~:~:~~:~:~:~:~~:~~:~:~::~:~:MMMMM%     `        //
//             `                     `              dMMMMNZXMMMMMMMMMSZZuuZuZZuZZuZuuZuZuZuZuuZMMMMMF        .MMMM#ZuZuZuZuZZuZuZuZZuZuZuZZMMMMMMMMMMMMMMM5:~:~:~:~::~:~:~:~:~:~::~:~:~~:~:(MMMMM`              //
//                    `                `            .MMMMMKZuZWHMHWZZZuZZuZZuZZuZuZZuZZuZuZZuZudMMMMN....... (MMMM#[email protected]~:~:~((ggJ~:~::~:~:~:~:~~:~:~:~:~~(MMMMN               //
//        `        `     `  `    `          `   `    dMMMMNZZuZuZZuuZuZuZZQgMMMMNmZuZuZZXQgNNMMMMMMMMMMMMMMMMMMMMMNNNmkZuZZuZZuZuZuZuZuZuZZuuZuZuZXMMMMM<:~~:(MMMMMr~:~~:~:~:~:~::~:~:~:~::(MMMMM.              //
//           `                                        MMMMM#uZuZuZZuZuZuQMMMMMMMMMNmQgMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmkZuZuZZuZuZuZZuZuZZuZuZudMMMMMx~:(jMMMMMMt:~:~:((-:~:~:~:~:~:~:~~:MMMMM]              //
//                                  `                 ,MMMMMkZZuZuZZuZZZMMMMMMMMMMMMMMMMMMMMMMMMWBYM#4K4KYTHM#WHMMMMMMMMMMMNmZuuZuZZuZuZZuZuZZuZuXMMMMMMMMMMMMMMMMM<~:~(dMMMN_~:~:~(+J,:~:~:JMMMMN,             //
//        `    `               `       `       `  `    dMMMMNkZuZuuZuZuuMMMMMMMMMMMMMMMMBY>:([email protected]#7MagNaJMpWMMMMMMMNkZuZuZuZuXgNNNNNNNNMMMMMMMMMMMMMMMMMM[:~:(MMMMM<~:~:dMMMMr:~:~:dMMMMN             //
//                   `   `                  `           WMMMMNZZuZZuZuZZdMMMMMMMMMMMMB!~~:(M#,dMMMMMMMMNNNMMMMMMMM#dgMF:?MMMMMMRZuZuZuZMMMMMMMMMMMMMMM7THMMH9^dMMMMMgJdMMMMMN_~:~(MMMMMN:~:~~(MMMMM[            //
//                          `     `                      MMMMMNZZuZZuZuZZXMMMMMMMMM#!` _:~?3M#(MMMMMMMMMMMMMMMMMM#3?HQp~~~dMMMMMRZuZZuZdMMMMMMMMMMMMMF         UMMMMMMMMMMMMMNg+gMMMMMMMm:~::~JMMMMb            //
//         `  `                      `                   .MMMMMNZuuZZuZuuZuZZWMMMM#!`.:~:~:~?JM#u+2HWMMMMMMMH9TudNdMPTE:[email protected]           (WMMMMMMMMMMMMMMMMMMMMMMMm-:~:jMMMMF            //
//                 `                            `  `      ,MMMMMRZZuuZZuZuZuZdMMMMD_._:~~::~:~:(T9?M#(Mb(MrdNJMM3T=~:~:~:~..JMMMMNQkXXuuZZuZuZdMMMMM`              _7"MMMMMHMMMMMMM"?MMMMMMNNMMMMMM^            //
//                      `                   `              ,MMMMMRuZZuZZuZZuZMMMMMr_.:(+ggg,~:~:~:~:~?5:T8:?Y>~~:~~(JJJ-~:_`(MMMMMMMMMMMNmkXZXMMMMM%                 .MMM#`   ``     .TMMMMMMMMMMM3             //
//       `                 `     `  `  `                    ,MMMMMNZuZuZuZuZZdMMMMNJ(dMMMMMMN/:~:~::(JggJ-~~::~:(gMMMMMMN/__+MMMMMMMMMMMMMMMNMMMMMF                  MMMM`              7WMMMMM#"               //
//          `  `     `                                       ,MMMMMNZuZuZuZuZqMMMMMMMMMMMMMMMN/~:(+MMMMMMMm-~:~(MMMMMMMMMN_(MMMMM!`~?"THMMMMMMMMM#                  .MMMF                                       //
//                                             `  `     `     ,MMMMMNZZuZZuZqMMMMMMMMMMMBdMMMMN+(MMMMMMMMMMNJ~([email protected]%         TMMMMMMN,                 JMMM\                                       //
//                             `            `                  ,[email protected][           .TMMMMMm.               dMMM`                                       //
//        `             `   `     `  `                          ,MMMMMNXuZudMMMMF ,MMMMMMmydMMMMMMM#ItttdMMMMMMMMMEtOqMMMMMMMMMM!             .UMMMMN,              MMMM                                        //
//           `     `                               `  ...(gggNNggMMMMMMNkZZMMMMM    TMMMMMMNagHH90ttttttttZHMMMMWggMMMMMMMMMMMM^                JMMMMN,             MMMM.                                       //
//                                              ` ..gMMMMMMMMMMMMMMMMMMMNkXMMMMF      TMMMMMMMMMMMMMMNNNNNNNMMMMMMMMMMMMB7"""`                   ,MMMMN.            dMMM_                                       //
//        `    `      `               `     `  ..MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]        (TMMMMMMMMMMMMMMMMMMMMMMMMMMM9^                           -MMMMb            JMMM|                                       //
//                         `      `          .JMMMMMM#"!            ?THMMMMMMMM]             ?""""HMMMMMMMMMMM"""^`                                WMMMM.           -MMM]                                       //
//                                          .MMMMMH"                     7HMMMM%                                                                   ,MMMM[           .MMMb                                       //
//         `  `         `      `     `    .dMMMM#^                          ?!                                                                     .MMMMh.          .MMMN                                       //
//                 `                     .MMMMMD                                                                                                   .MMMMMN,          MMMN                                       //
//                          `      `    .MMMMM^                                                                       .            ..-.            JMMMMMMM,         MMMM.                                      //
//       `            `                 dMMMM^                                        .(J,   ..NNJ          .MMMN. .MMMMa         (MMMM]          .MMMMMMMMM,        dMMM~                                      //
//          `  `                       .MMMMF                         .dMMN,        .jMMMM]  JMMMMN,      .JMMMMM\ .MMMMMN,     .MMMMMM3          dMMMMMMMMMN        dMMM{                                      //
//                       `       `     MMMM#              `           ,MMMMMN,     .MMMMMM^  .HMMMMMN,   .MMMMMM^   ,HMMMMMN,  -MMMMMB`         .dMMMM#XMMMMM[       dMMM!                                      //
//                                  ` .MMMMF       `           `       ?MMMMMMm,  [email protected]      ?MMMMMMm.JMMMMMD       ?MMMMMMmMMMMMMt          [email protected]       dMMM`                                      //
//        `        `        `         .MMMM]            `                7MMMMMMmMMMMMMt         TMMMMMMMMMMM^          TMMMMMMMMMB`          .MMMMMBuZZdMMMM#       MMM#                                       //
//           `        `          `    .MMMM]    `                          TMMMMMMMMM#!           .WMMMMMMMD             .MMMMMMMF          .MMMMMMMMNNNNMMMM#      .MMM#                                       //
//                                    .MMMMb       `                        [email protected]              .MMMMMMMm.           .JMMMMMMMMm.       dMMMMMMMMMMMMMMMMMN.     .MMM]                                       //
//        `    `         `             MMMMN.                               .MMMMMMMMN,          .MMMMMMMMMMMe         .MMMMMMMMMMMMx      ,MMMMH""""HMMMMMMMMMNa.  dMMM!                                       //
//                             `   `   -MMMMb             `    `     `    .dMMMMMMMMMMMm.       (MMMMM#^TMMMMMN,     .MMMMMMF  TMMMMMN,                  .7WMMMMMMm.MMM#                                        //
//                 `        `           MMMMMb  `  `                     .MMMMMH' ?MMMMMMe    .MMMMMM"   ,MMMMMMm.  (MMMMM#'    ,MMMMMMp                     ?HMMMMMMMM%                                        //
//         `  `       `                 MMMMMMN,        `              .MMMMMMD     TMMMMMN. [email protected]`      ?MMMMM] .MMMMM"        7MMMMF                       (MMMMMM#                                         //
//                                 `    dMMMMMMMN,                     dMMMM#'       .WMMMM` .MMMM^          TMMD   .T""`           ?"!                          TMMMMN                                         //
//                       `            ` JMMMMMMMMMMNJ..                .TMH"            ?!                                                                        ?MMMMb                                        //
//       `                       `      .MMMMMMMMMMMMMMMMMMMMMMMMN,                          .gggggggg+J-........                                                  UMMMM[                                       //
//          `  `   `        `            dMMMMNZUMMMMMMMMMMMMMMMMMF                         JMMMMMMMMMMMMMMMMMMMMMMMMNNJ                                            MMMMN                                       //
//                    `                  .MMMMMRuuuZZXWMMMMMMMMMM=                          .TMMMMMMMMMMMMMMMMMMMMMMMMMM]                                           JMMMM;                                      //
//                               `  `     ,MMMMMNZZuZuZuuXMMMMMD                                     MMMM#rrvwXUVWMMMMM"                                            .MMMM]                                      //
//        `              `             `   (MMMMMNkuZZuZXMMMMM$                                     .MMMM#rrrrrrrvMMMM#                                             .MMMM]                                      //
//           `              `               ,MMMMMMmZuZZdMMMMF         `                             MMMM#rvvrrvrrMMMM#                                             .MMMM]                                      //
//                 `             `            WMMMMMMmXdMMMMF                      `                 MMMMNwrvrvrrdMMMMF                                             JMMMM:                                      //
//        `    `      `             `          (MMMMMMMMMMMM!                                        -MMMMNyrrvwgMMMMM!                                            .MMMM#                                       //
//                                               (HMMMMMMMM#                     `                    ?MMMMMMMMMMMMMM^                                             dMMMM^                                       //
//                       `     `       `           .TMMMMMM#           `   `            `       `      ,WMMMMMMMMMM"                                             .MMMMMD                                        //
//         `  `             `       `                 .MMMMN                                              ?T"""""`              .MMMNa,.                        .MMMMM$                                         //
//                   `                                 JMMMM,                                                                   ,MMMMMMMMNJ..                .+MMMMMM^                                          //
//                                            `        .MMMMb        `             `          `                                 .MMMMMMMMMMMMMNNg-.......(gMMMMMMMM3                                            //
//       `         `    `        `   `                  dMMMMb                               ..                                 [email protected]^                                              //
//          `  `            `               `    `       WMMMMb                  `      `  .MMMM,   `                           .MMMMMHHHMMMMMMMMMMMMMMMMMMM9"`                                                 //
//                                                        UMMMMN,          `             .MMMMMMb                               .MMMMMMMMMMMMMMMMMMMMb                                                          //
//                                `   `                    ?MMMMMN,    `               .MMMMMMMMMp                              MMMMMMMMMMMMMMMMMMMMM#                                                          //
//        `          `   `                     `   `        .UMMMMMNg,             ..gMMMMMMMMMMMMp                            JMMMMMMMMMMMY"^` .MMMMN                                                          //
//           `                 `            `                 .TMMMMMMMNg-......JgMMMMMMMMMHHHMMMMMm.                         JMMMMMMMMMM#      .MMMMM                                                          //
//                                 `  `                          ?WMMMMMMMMMMMMMMMMMMMMMMHHHHHHMMMMMN,                      .MMMMMMMMMMMM\      .MMMM#                                                          //
//        `    `   `        `                   `                  .MMMMMMMMMMMMMMMMMHHHHHHHHHHHMMMMMMMa.                 .MMMMMMMMMMMMMMM|     .MMMMM,                                                         //
//                      `                          `    `          JMMMMMHHHHHHHHHHHHHHHHHHHHHHHHHMMMMMMMMN-..       ..(MMMMMMMD`  ?TMMMMMt     MMMMMMN                                                         //
//                                 `        `                     .MMMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMMMMMMMMMMMMMMMMMMMMMMM"         ?!      .MMMMMMM[                                                        //
//         `  `      `                `         `                 dMMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMMMMMMMMMMMMMMMMY"`                  .MMMMMMMMN                                                        //
//                         `   `                                 .MMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMMMMMM%`                      .MMMMMMMMMM|                                                       //
//                                `                `      `      JMMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMMM|                      .MMMMMMMMMMMb                                                       //
//       `              `              `    `   `                MMMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMMMN                     (MMMMMMHMMMMMM.                                                      //
//          `  `   `                                    `       .MMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMMMN,                 .MMMMMMMHHHMMMMM]                                                      //
//                          `      `                            (MMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMMMMMN,            .JMMMMMMMHHHHHMMMMMb                                                      //
//                    `               `        `   `            dMMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMMMMMMNN&-...-&MMMMMMMMMMHHHHHHMMMMMN                                                      //
//        `                    `                                MMMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMMMMMMMMMMMMMMMMMMMMHHHHHHHHHHMMMMM.                                                     //
//           `           `         `        `             `    .MMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMMMMMMMMMMMMMMHHHHHHHHHHHHHMMMMM}                                                     //
//                 `                                                                                                                                                                                            //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MTGM is ERC721Creator {
    constructor() ERC721Creator("MINT GUM", "MTGM") {}
}