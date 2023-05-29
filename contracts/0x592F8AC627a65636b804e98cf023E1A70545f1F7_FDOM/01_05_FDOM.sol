// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: .+FREEDOM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                               ...........                    //
//                                                                                                                                                                          ..NMMMMMMMMMMMMMMMa,.               //
//                                                              ...(+ggg+(...                                                                                            .MMMMMMMMMMMMMMMMMMMMMMMN,             //
//                                                         ..gMMMMMMMMMMMMMMMMMNJ,                                                                                    .JMMMMMMY"!           ?TMMMMMN,           //
//                                                       .MMMMMMMMMMMMMMMMMMMMMMMMMN,                                                                                (MMMMM"!                  .TMMMMN,         //
//                                                  `  .MMMMMMMH""!       ?7"HMMMMMMMMa,                                                                           .MMMMM"                       .WMMMMx        //
//                                               `   .MMMMMMB^                 .TMMMMMMMm.                                                                        [email protected]                      .... ?MMMMp       //
//                                          `       .MMMMMB!        ..J-,         .TMMMMMMp                                                                       MMMMF                      JMMMM[ (MMMM,      //
//                                                 .MMMMM$       .JMMMMMMMm.         TMMMMMN,                                   ...gMMMMMMMMMMMMNgJ..            -MMM#                       4MMMM$  dMMMN      //
//                                  `  `      `   .MMMMMt        dMMMMMMMMMN          .HMMMMM,  `  `  `  `  `  `  `  `  `  `..MMMMMMMMMMMMMMMMMMMMMMMMNg,.  `    MMMMt              `         .""`    MMMM]     //
//                           `  `         `       MMMMMF        .MMMMMMMMMMM:           TMMMMMx                          ..MMMMMMMMMMMMH"""""HMMMMMMMMMMMMNa,   .MMMM      `    `      `  `    ...,   JMMM#     //
//        `  `  `  `  `  `                       .MMMM#      `   [email protected]             ?MMMMMx                       .dMMMMMMM#"!               _"YMMMMMMMMMa,-MMM#   `                     .MMMMb  ,MMMM     //
//                                 `         `   dMMMMF           TMMMMMMM"    `          ?MMMMM,                    [email protected]^                        ?YMMMMMMMMMMM#         `    `          ,MMMM#  .MMMM`    //
//                          `         `  `       MMMMM!              ?7^          `        vMMMMN.   `  `  `  `  `  .MMMMMM"                              .TMMMMMMMMN                         .MMMM#  .MMMM     //
//       `                     `                .MMMMM     `                        ..(.,   WMMMMb                 JMMMMMD   ..gNNa,   `                     ?HMMMMMM[    `           `  `   .MMMMM]  -MMM#     //
//          `  `  `  `  `         `         `   ,MMMM#        `              `   .JMMMMMMMm..MMMMM,               dMMMMM^  .dMMMMMMMN,    `  `  `  `           .TMMMMN       `  `  `        [email protected]   MMMMF     //
//                                              .MMMMN                           dMMMMMMMMMN dMMMMN              dMMMMM`   dMMMMMMMMMM,              .JMMMMN,    .MMMMb                   [email protected]   .MMMM      //
//                                              .MMMMM             `             MMMMMMMMMMM .MMMMM,            JMMMMM`    MMMMMMMMMMM\             .MMMMMMMMN,   ,MMMMb                 MMMMMMMD   .MMMM%      //
//                                         `     MMMMM;     ..JggJ,              ?MMMMMMMMMF  dMMMMb           .MMMMM!     ([email protected]             .MMMMMMMMMMN    ,MMMMN,               MMMMM"    .MMMMF       //
//                                               dMMMM]    .MMMMMMMN,             (MMMMMMM"   ,MMMMN          .MMMMMt       ,YMMMMM#=              .MMMMMMMMMM#     .HMMMMa.              .?`    .MMMMMt        //
//                                               ,MMMMN   (MMMMMMMMMM,      `        _?!       MMMMM|         (MMMM#                                TMMMMMMMMM'       7MMMMMa,                [email protected]`         //
//                                                MMMMM]  MMMMMMMMMMM]                         dMMMMb        .MMMMM\                                 .TMMMMY"           TMMMMMMg,.        ..+MMMMMMB'           //
//                                         `      -MMMMN. -MMMMMMMMMM`                         ,MMMM#        .MMMM#                                                       ?MMMMMMMMMMMMMMMMMMMMMM"              //
//                                                 WMMMMb  ,WMMMMMMD                           .MMMMM.       dMMMMF                                                         HMMMMMMMMMMMMMMMM9^                 //
//                                                 .MMMMMc     ``           ` ..gg-.            MMMMM{       MMMMM:                  .(gMNa..                                MMMMMMMMMMMMN.                     //
//                                                  JMMMMN.                 JMMMMMMMN,          dMMMM]      .MMMMM                 .MMMMMMMMMp                              .MMMMMMMMMMMMMN.                    //
//                                         `         WMMMMb                dMMMMMMMMMM;         JMMMMF      .MMMM#                 MMMMMMMMMMM[               .....        .MMMMMMMMMF HMMMb                    //
//                                               `    MMMMMb               MMMMMMMMMMM]         ([email protected]      -MMMM#                 MMMMMMMMMMM]             .MMMMMMN&     .MMMMMMMMMMMMMMMMM]                   //
//                                                    ,MMMMM[              JMMMMMMMMMM` ..gMMMMMMMMMMMN&,.  (MMMMF                 ,[email protected]             dMMMMMMMMMb    dMMMFMMMMMMMMMMMMMF                   //
//                                         `           -MMMMM,              .TMMMMMM8(MMMMMMMMMMMMMMMMMMMMNa(MMMMF                   ?WMMMM#= ..gg,        MMMMMMMMMMM   .MMMM{JMMMMF~~???7^                    //
//                                                      ?MMMMM,                 `~.dMMMMMMM#""7?!??"TWMMMMMMMMMMMF           ....+ggggJ...    dMMMMp       UMMMMMMMMMF   .MMMM JMMMM]                           //
//                                                       TMMMMM,                .JMMMMM#"               [email protected]       ..NMMMMMMMMMMMMMMMNa.MMMMMMm.      7MMMMMMMD    -MMM# dMMMM%                           //
//                                               `        TMMMMM,        `     [email protected]`                    TMMMMM#    ..MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNJ       .7""!      (MMM#.MMMMM`                           //
//                                         `               TMMMMM,            .MMMMM^                        WMMMMp .JMMMMMM#"!          7YMMMMMMMMMMMMMa,               (MMMNMMMMMF                            //
//                                                          ?MMMMMp          .MMMMM`                          WMMMMJMMMMM#=                 .TMMMMMMMMMMMMNa.            ,[email protected]                             //
//                                                  `        ?MMMMMb        `dMMMM'                           .MMMMMMMM#'                      ?MMMMMMMMMMMMMMNJ..      ..MMMMMMMD                              //
//                                                            ,MMMMMN.   `  .MMMMF                             MMMMMMM3                          TMMMMN/YMMMMMMMMMMMMMMMMMMMMMMM=                               //
//                                         `     `    ..gMMMMMMMMMMMMN.,.   JMMMM`                             dMMMM#`                            ,MMMMN, .TMMMMMMMMMMMMMMMMMM]                                 //
//                                                ..MMMMMMMMMMMMMMMMMMMMMMN.MMMM#                              [email protected]                               ,MMMMN      ?7T""HMH"""MMMMF                                 //
//                                              .MMMMMMMMM"""7777""[email protected]                                ?`                                 (MMMM]                [email protected]                                 //
//                                         `  .MMMMMM#"                [email protected]                                                                    MMMM#                -MMMN                                 //
//                                          .dMMMMM"                       (TMMM^                                                                    dMMMM                .MMMM                                 //
//                                         .MMMMMD                                                                                                   JMMMM                .MMMM                                 //
//                                       `.MMMMM'                                                                                                    dMMMM                .MMMM`                                //
//                                       .MMMM#`                                                  .            ...,   ..+J.          .MMN,          .MMMMN,               .MMMM                                 //
//                                       MMMMM`                          ...,          .JMMN,  .MMMM&         .MMMMb  MMMMMe       .gMMMMM          JMMMMMMe              .MMMN                                 //
//                                      -MMMM%                          .MMMMN,       .MMMMM#  ,MMMMMN,     .MMMMMM3  7MMMMMN,    .MMMMMM^         .MMMMMMMMp             (MMM#                                 //
//                                      MMMM#                           .MMMMMMN,    [email protected]    ,HMMMMMN,  .MMMMMB`    .WMMMMMN,.JMMMMMF          .MMMMMMMMMM,            dMMMF                                 //
//                                     .MMMMF                             ?MMMMMMm..MMMMMM$       ?MMMMMMmMMMMMM$        (MMMMMMMMMMMM^         [email protected] JMMMMN           .MMMM\                                 //
//                                     ,MMMM]                      `        TMMMMMMMMMMM#!          TMMMMMMMMMB`           ?MMMMMMMMF          .MMMMMF   MMMMM.          .MMM#                                  //
//                                     .MMMM]                `                TMMMMMMMMD             .HMMMMMMF              .MMMMMMN,        .MMMMMMMMMMMMMMMM)          dMMMF                                  //
//                                      MMMMb          `                       .MMMMMMN,            .JMMMMMMMMm.          .MMMMMMMMMMh.     .MMMMMMMMMMMMMMMMMMN,.      .MMMM!                                  //
//                                      dMMMM,                               .dMMMMMMMMMN,         .MMMMMMMMMMMM,        (MMMMM#7MMMMMMa     ,""""7???7"""MMMMMMMMN,    MMMMF                                   //
//                                      .MMMMN.                 `           .MMMMMMTMMMMMMa.     .MMMMMMD  TMMMMMN,    .MMMMMM"   TMMMMMN,                  .TMMMMMMN, -MMMM`                                   //
//                                       JMMMMN,                         `.dMMMMMF   TMMMMMM,   .MMMMMH^    ,MMMMMMp  [email protected]`     .HMMMMM-                    .TMMMMMgMMMMt                                    //
//                                        JMMMMMe.     `     `           .MMMMMM^     .UMMMMM] ,MMMMM"        7MMMMF  TMMMM^         ?MMMD                       .WMMMMMMMF                                     //
//                                        MMMMMMMMm,               `     ?MMMMD         ,[email protected]   ("H"`           ?"'     ~`                                         7MMMMM#                                      //
//                                       .MMMMMMMMMMMNg-...........       .77`                                                                                      ?MMMMb                                      //
//                                       .MMMMM(YMMMMMMMMMMMMMMMMMMb                                                                                                 WMMMM,                                     //
//                                        MMMMM.  ."WMMMMMMMMMMMMMMF                              ..J+++J(.....                                                      .MMMMb                                     //
//                                        dMMMMb         ~?7MMMMM#!                              .MMMMMMMMMMMMMMN.                                                    dMMMN                                     //
//                                        ,MMMMM,         .MMMMMD        `                       .MMMMMMMMMMMMMMM\                                                    (MMMM_                                    //
//                                         UMMMMN.        dMMMM%                                          `?7"""'                                                     (MMMM:                                    //
//                                          WMMMMN,      (MMMM$                                                                                                       JMMMM`                                    //
//                                           WMMMMMa    .MMMMF                                                                                                        MMMM#                                     //
//                                            TMMMMMN,  -MMMM\              `                                                                                        -MMMMt                                     //
//                                             ,HMMMMMMadMMMM            `                                                                                          [email protected]                                      //
//                                               /MMMMMMMMMMN                                                                      ...                             .MMMMM`                                      //
//                                                 .TMMMMMMMM.                                                                    dMMMMN.,                       .MMMMM#`                                       //
//                                                    ."WMMMM]                                                                    MMMMMMMMMNg...              .JMMMMMMD                                         //
//                                         `             MMMMN,    `     `                                                        JMMMMMMMMMMMMMMMNag+JJJ&gMMMMMMMMMD`                                          //
//                                                       ,MMMMN.                            ` ..,                                 (MMMM`_"WMMMMMMMMMMMMMMMMMMMMMM#=                                             //
//                                                        JMMMMN,                           .MMMMb                                dMMMM  .MMMMMMMMMMMMMMMMMMY""`                                                //
//                                                         JMMMMMe          `            `.MMMMMMM,                               MMMMNdMMMMMMMMMMMMMMM]                                                        //
//                                         `                ,MMMMMMa.                 ` .MMMMMMMMMN.                             .MMMMMMMMMMM"^   JMMMMF                                                        //
//                                                            ?MMMMMMN.. `        ` [email protected]?MMMMN,                           [email protected]      (MMMMF                                                        //
//                                               `              7MMMMMMMMNag(...+gMMMMMMMMM"   JMMMMM,                         .MMMMMMMMMMM!      JMMMM]                                                        //
//                                                     `          .TMMMMMMMMMMMMMMMMMMMM"!      ,MMMMMN,                    `.dMMMMMMMMMMMMN      MMMMMb                                                        //
//                                         `                        .MMMMMMMMMMMMMM""^            TMMMMMN&,              ` .MMMMMMD _"WMMMMM     .MMMMMM[                                                       //
//                                                  `              .MMMMM%                         .TMMMMMMMNJ... `  ...&MMMMMMM#'      ("^      dMMMMMMN                                                       //
//                                                                 -MMMM#                             TMMMMMMMMMMMMMMMMMMMMMMMD`                .MMMMMMMM]                                                      //
//                                               `                 MMMMM\                                ?"MMMMMMMMMMMMMMMY"`                  .MMMMMMMMMN                                                      //
//                                         `                      .MMMM#                                       ?74MMMM#                       .MMMMM$MMMMM;                                                     //
//                                                           `    dMMMM]                                         .MMMMM,                    .dMMMMM3 JMMMMb                                                     //
//                                                     `         .MMMMM!                                          qMMMMN,                 .-MMMMMM'  ,MMMMN                                                     //
//                                         `                     .MMMM#                                            TMMMMMN,.            .uMMMMMMD     MMMMM;                                                    //
//                                               `               (MMMMF                                                                                                                                         //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FDOM is ERC721Creator {
    constructor() ERC721Creator(".+FREEDOM", "FDOM") {}
}