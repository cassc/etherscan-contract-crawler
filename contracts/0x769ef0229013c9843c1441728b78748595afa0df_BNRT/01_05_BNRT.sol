// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BALLOON RABBIT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                             ......                                                                                            //
//                                                                                                       ..+MMMMMMMMMMMNg,.                                                                                      //
//                                                                                                     .MMMMMMMMMMMMMMMMMMMNa,                   ..,                                                             //
//                                                                    `     `     `     `      `     .MMMMMMHyyyyyyyyyQMMMMMMMN,          .     dMMMN,                                                           //
//                                                                                                 .MMMMMHyyyyyyyyyyyWMMMMMMMMMMN,      .MMMa.  .WMMMMp                                                          //
//         `   `   `   `   `   `   `   `   `   `   `   `   `   `   `     `     `     `     `       MMMMNyyyyyyyyyyyyyyWMMyyyyMMMMMh.  ` ?MMMMM,   /MMMMb   `   `   `   `   `   `   `   `   `   `   `   `   `     //
//                                                                    `     `     `     `      `  .MMM#yyyyyyyyyyyyyyyyyyyyyyWQMMMMM,     TMMMMb   ,MMMM[                                                        //
//                                                                `..JgMMMMMNgJ,                  JMMMkyyyyyyyyyyyyyyyyyyyyyMMMMMMMMMp     ,MMMMb   (MMMN.                                                       //
//       `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `   .dMMMMMMMMMMMMMMMm,  `     `      (MMM#yyyyyyyyyyyyyyyyyyyyyMMMMHWMMMMp     ,MMMM,   MMMM)   `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `      //
//                                                           .(MMMMMMMHWyyyyWMMMMMMm.          `   MMMNkyyyyyyyyyyyyyyyyyyyyyyyyyyyMMMM[     dMMMb   MMMM]                                                       //
//                                                          .MMMMMHyyyyyyyyyyQNNMMMMN,  `          ,MMMNKyyyyyyyyyyyyyyyyyyyyyyyyyyWMMMM,    ,MMMN   .T""                      ..gNa.                            //
//                                                        .MMMMMWyyyyyyyyyyyWMMMMMMMMN     `  ..ga, ,MMMMNyyyyyyyyyyyyyyyyyyyyyyWMMMMMMMb    ,MMMM                       `..gMMMMMMM]                            //
//         `    `    `    `    `    ` ...    `    `    ` .MMMMNyyyyyyyyyyyyyyWMHHHMMMM]   ...gMMMMM)  TMMMMmyyyZyyyZyyyZyyyZyyyyWMMMMMMMM,    ?"9'             `    `..(MMMMMMMMMMMM]     `    `    `            //
//      `     `    `    `    `    .(MMMMMMNJ.   `    `  .MMMMHyyyyyyyyyyyyyyyyyyyyWMMM@ .MMMMMMMMMF    ,WMMMMmyyyyyyyyyyyyyyyyyyyyyyyWMMMb                `  `    .gMMMMMMMMMMMMMMMM]  `     `    `    ` `  `    //
//                               .MMMMMMMMMMN...       .MMMMHyyyyyyyyyyyyyyyyyyWWyVMMM# ?MMMMMMMMMMa,    ,WMMMMmyyyyyyyyyyyyyyyyyyyyyyMMMN                        dMMMMMB"`.dMMMMMMM]                            //
//                              .MMMMBuuXMMMMMMMMN,    JMMMNyyyyyyyyyyyyyyyyyWMMMMMMMM#   ???MMN?WMMMN,    ,HMMMNKyyyyyyyyyyyyyyyyyyyyMMMM                         ?"!    .MMMM#MMMM]                            //
//                           .(MMMMMNuuuuuMMMMMMMMMp  .MMM#yyyyyyyyyyyyyyyyyyyMMMMMMMMF     .MMM  .TMMMm.    (MMMMNyyyyyyyyyyyyyyyqMMNMMMM~           `.JgJ              .MMMM@ MMMM]                            //
//                         `.MMMMMMMMSuuuuuuuuudMMMM. dMMMHyyyyyyyyyyyyyyyyyyyyyyyMMMM!     .MMM    ,HMMN,     UMMMNyyyZyyyZyyyyyyMMMMMMMM~           .MMMMN,           .MMMMF  MMMM]                            //
//                         .MMMMBUHHXuuuuuuuuuuXMMMM{.MMM#yyyyyyyyyyyyyyZyyyyyyyyWMMMF      .MM#      TMMMgMMMMMMMMMNyyyyyyyyyyyyyyyyyMMMM`          .MMMMMMN,         (MMMMD   MMMM[                            //
//                         ,MMMMkuuuuuuuzuuuuuQMMMM# .MMM#yyyyyyyyyyyyyyyyyyWQmmgMMMM'      (MMF     .(MMMMMMMMMMMMMMNkyyyyyyyyyyyyyyyMMMM          dMMMMTMMMMe      .MMMMM^    MMMM{                            //
//                          WMMMMNNNNNkuuzuMMMMMMM#` (MMMHyyyyyyyyyyyyyyyyyyMMMMMMMMN.&gNNggMMMt   .JMMMMMMMHqqqqMMMMMMNkyyyyyyZyyyyyWMMM#        .MMMMM! ?MMMMb    .MMMMB`     .T"^                             //
//                           7MMMMMMMM#uuudMMMMMMt   JMMMHyyyyyyyyyyyZyyyyyyWMMMMMMMMMMMMMMMMMMNa,.MMMMMqMMMMMNHqkqqMMMMMKyyyyyyyyyyyWMMM]       .MMMM#`   ,MMMMN. JMMMMD                                        //
//                             .7TMMMMXuuQMMMMMMMMe  JMMMHyyyyyyyyyyyyyyyyyyyyQMMMMMMMMqqqHMMMMMMMMMMMqMMMMMMMMHqqkqqqMMMMkyyyyyyyyyyMMMM`      .MMMMD      .MMMMNMMMMM^                                         //
//                                MMMMMMMMMMM@7MMMMNdMMMMHyyyyyyyyyyyyyyyyyyWMMMMMMqqqqMMMMMMMqMMMMMMqqMMMMMMHqqkqqqqkHMMMNyyyyyyyyyWMMMF      .MMMMF         UMMMMMMD                                           //
//                                 TMMMMMMMM=   UMMMMMMMM#yyyyyyyyZyyyyyyZWNMMMMMqW9WHqMMMMMMMNqHMMMNqkkqqkqqqkqqkqqkqqMMMMyyyyyyyyyMMMM'     .MMMMF           7MMMM=                                            //
//                                   _7""!     .MMMMMMMMMNyyyyyyyyyyyyyyyyWMMMMMH0rrrrXqqMMMMMMqHMMMMqHSrrrUqqqkqqkqqqqMMMMyyyyZyyyWMMMMa,   .MMMMF             .7"                                              //
//                         ..,               .dMMMMMqqMMMMkyyyyyyyyyyyyyyyWMMMNqHwrrrrdqkqqqqqqqHMMMNqRrrrrrWqqqqqqkqkqMMM#yyyyyyyyWMMMMMMMm.MMMMF                                                               //
//                       .dMMM]   .gMN,     .MMMMMHqkqMMMM#yyyyZyyyyyyZyyyWMMMNqqqmmQWqqqkqkqqkqqMMMMHHyvvwdqqkqkqqqqqMMMMNyyyyyyyyyyyyHMMMMMMMMF                                                                //
//                       dMMM#!  .MMMMF    .MMMMMqqkqqqMMMMkyyyyyyyyyyyyyyWMMMNkqqqqqqqkqqqqkqqkqHMMMMNqqqqqqqqkqkqkHMMMMMyyyyyyyyyyyyyyyyMMMMMM,          .gMMN&,                                               //
//                      -MMM#`  .MMMMF     dMMMMqqqqqkqHMMMNyyyyyyyyyyyyyyyMMMMNqkqkqkqqkqqkqqqqHMMMMMMNHqqkqkqqqqHNMMMMNyyyyyyyyyyyyyyyyyyyWMMMMN,       gMMMMMMMp     ..,                                      //
//                      MMMM%   JMMMF     .MMMMHqkqqkqqqMMMMNyyyyyyZyyyyyyyyMMMMNqkqqqkqqkqqkqqNMMMMMMMMMMMNNNNNMMMMMMMWyyyyyyyyyyyyyyyyyyyyyyMMMMMe     .MMMMTMMMM;  .JMMM@                                     //
//                     .MMMM    MMMM\     (MMMNqqkqqqqkqqMMMMRyyyyyyyyyyyyyyyMMMMMNHqqqqqqqqHNMMMMMWyyWMMMMMMMMMMMMMMyyyyyyyyyyyZyyyyyyyyyyyyyyWMMMMb     WMMMMMMMMh+MMMMMM^         .gNa,                       //
//                     .MMMM.  .MMMM_     dMMMNqkqqkqqkqkqMMMMNyyyyyyyyyyyyyyyWMMMMMMMMMMMMMMMMMMHyyyyyyyyWHHMMHHyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyMMMMb     7MMMMMMMMMMMMM"           dMMMMm.                     //
//                      MMMMb   MMMM;     JMMMNqqqkqqkqqqkqMMMMNyyyyyyyyZyyyyyyyyWMMMMMMMMMMMMHyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyZyyyyyyyyyyyyMMMMb...   .TMMMMMW"=       .gg,    ?MMMMN,                    //
//                      -MMMM   dMMMN     .MMMMNqqqqkqqqqqqqMMMMNkyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyZyyyyyyyyyyyyyyyyyyyyyMMMMMMMMN, .MMMM          .MMMMMe    WMMMN.                   //
//                       .""`    TM#^      qMMMMNkqqqkqkHMMNHMMMMMNyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyMMNyyyWMMKyyWMMkyyWMNyyyWMMMMMMMMMMMMMMNNgJ,.      .TMMMMN,   HMMMb                   //
//                                       .JMMMMMMqqkqqqqMMMMNqqMMMM#yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyZyyyyyMMNyyyWMM#yyWMMHyyWMMHyyyMMMMy?HMMMMMMMMMMMMMN,       UMMMM,  ,MMM#                   //
//                                      (MMMMMMMHMMMNkqqHMMMMHMMMMMyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyWQNNMMNNNmkyyWQNNMMMMMMMMMMMMMMMMMMMMNMMMmkyyWMMMb??zHMMMHBYWMMMMMMN,      TMMMN.  ,""`                   //
//                                 ....MMMMMMkqqHMMMMqqkqqkqqMMMMMyyyyyyZyyyZyyyyyyyyyyyyyyyyyyyyyyyWNMMMMMMMMMMMMMNdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMyyWMMM#????????gNNe?vMMMMMx      MMMM]                         //
//                `..,         .gMMMMMMMMMMqqqkqqMMMMqqqkqqqMMMM#yyyyyyyyyyyyyWkyyyyQNRyyyWNNWyyyyWMMMM#"`      ?WMMMMMM.   MMMR:::<+dMn<:+MMMdMMNyyWMMM#dMMR???zMMM#=??dMMMM,     JMMM^                         //
//                .MMMN     .JMMMMMMMMMMMMHkqqqqqqqqqqkqqkqqMMMMWyyyyyyWMNkyyWMM#yyyMMNyyyWMMHyyyWMMM@`            TMMMMb   ,MMMm+N2HMMM@+MMM5MMM#yyWMMM#MMMM=?=??HBC?=??MMMMMMe.                                //
//                -MMM#   `.MMMMMB=~~JMMMNqqkqkqqqqkqqqkqqkHMMM#yyyyyyyWMM#yyyMMNmgNMMMNNNNMMNNNNMMMF               ?MMMMb   ,MMMMN&JdN+MMMMBMMMMyyyWMMM@?7Y1?=????1=??=?zTMMMMMMNg,                             //
//               .MMMMt   (MMMM5~~~:~JMMMNqqqkNMMMNHqkqqqqHMMMM#yyyyyyWgMMMMMMMMMMMMMMMMMMMMMMMMMMMM                 MMMMMN,   (WMMMMMMMMMBjMMMMyyyyMMMMD=1gge??=uMMMb=??=??zMMMMMMMMa,                          //
//             `.MMMMN.  .MMMM3~:~:~~(MMMMNqqqMMMMMMMMNNMMMMMMM#yyyyyyMMMMMMHWMMMYC<<::jNc::+MMMMMMN                 dMM#MMMMa,.   ?7"7~.gMMMMHyyyyWMMM#??dMMMMMMMMMM8?=??=uggMMMMMMMMMN,                        //
//          `..MMMMMMMMNxdMMMF~:~~:~~:?MMMMNHqkqMMMMMMMMMMMMMMM#yyyyyyMMMN    WMMN+:++MMMMN<dMMFMMMMc                MMM] ?HMMMMMMNNNMMMMMMMMMNWyyyMMMMD??=TMMMMMMM81?1agMMMMMMMMMMMMMMM%                        //
//           MMMMM#TMMMMMMMMM$~~~:~~:~~?MMMMMNNHqqqHMMMMMMMHMMMNyyyyyyWMMMp    UMMMmd5:?M6+MMM#(MMMMN,              (MM#   . ?TWMMMMMMM""! -MMM#yydMMM#??=????=??=uggMMMMMMMMMMMHHHMMMMF                         //
//           ?MM"!    TMMMMMMP~:~~:~~~~~:TMMMMMMMMMMNHqqqqqqMMMMkyyyyyyWMMMm.   (HMMMMMMMMMMM".MMMWMMMm,          .MMMM!  -MF  .g,  .,  JM] MMMMyMMMM#=???=?=uggMMMMMMMMMMMHHHHHHHMMMM#                          //
//                  ..MMMMMMMMN/~:~(Jgg,~~~?TMMMMMMMMMqkqqqqMMMMNyyyyyyyWMMMMa.    ?TWMMH""!.dMMM% .WMMMNaJ....JNMMMMD         .=   T"      JMMMMMMM@??==ugNMMMMMMMMMMHHHHHHHHHHH#MMMM^                          //
//                .JMMMMMMMMMMMMe~(MMMMM[~:~~~~(MMMMMH"!?4qkqMMMMNyyyyyyyMMMMMMNg...   ...gMMMM@`    .TMMMMMMMMMMMB=          ..+J,..MMMm,  JMMMMMMMMggMMMMMMMMMM#HHHHHHHHHHHH#HHMMMMF                           //
//               .MMMMM5<~~:TMMMMmJMMMMMR,~:~:(MMMMMqb   .qqqqMMMMNyyyyyWMMM@TMMMMMMMMMMMMMM#"             ???!              .MMMMMMMMMMMN  MMMM#"MMMMMMMMMMMHHHHHHHHHHHHHHH#HHHMMMMM`                           //
//              .MMMM@~~~:~~~?MMMMRWMMMMMMp~~~JMMMMqkqHQdqkqqqqMMMMNRyyyWMMMF ...?"""""""^`  (M[           .&ggJ,.MN.        (MMHqMMMMqMM# .MMMF  .MMMMMMHHHHHHHHHHHH#HH#HH#HHHHMMMMF                            //
//              MMMMF~:~:~~(_~?MMMM>MMMMMMF~:~dMMMNqY` ?HqqkkqqqMMMMMNmkyMMMN TM!  jN.  dM}   `           .WMHMMMMM^          MMMNHMMHMMM'.MMM#    .MMMMMHHHHH#HH#HH#HHHHHHHHHHMMMMM`                            //
//             .MMMM<~~:~(MMMNe?WB3~~7HMH5~~:~JMMMMq;   dqqqqkqqqqMMMMMMMMMMMb      `     .(J                   MM]            TMMMNNMMM'.MMMM!     ,MMMMHHHHHHHHHHHHH#HH#HH#HHMMMMF                             //
//             .MMMMc~~~:MMMMMN~~~~:~~~~~~:~~:(MMMMNqHWqHHkqqqkqkqqqHMMMMMMMMMp      (Ng,.MM@                   ?"               ?YMMMD .MMM#!       dMMMMHH#HH#HH#HHHHHHHHHH#HMMMM!                             //
//              dMMMN-~:~dMMMMMMm:~~:~:~:~~:~~~?MMMMNqq%   4qqqkqkqkqqqqHMMMMMMm.    ("MMMM#                                          .MMMMF          MMMM#HHHHHHHH#HH#HH#HHHHMMMM#                              //
//              .MMMMN,~~~TMMMMMM3~:~((J-~~:~~:~?MMMMNHh. .dqkqqqqkqqkqqqMMMMMMMMJ     .MMMMMm.      `                             .JMMMM#'           -MMMMHH#HH#HHHHHHHHH#HHHMMMM%                              //
//                WMMMMNgJ_?WMMM8~:(MMMMM;~~:~~~~?MMMMMNNHqqqqkqqqqmHHHHHMMMM?WMMMMa, .MMF  T"                             `   ..&MMMMMM'              MMMMHHHHHHH#HH#HH#HHH##MMMM                               //
//                 (MMMMMMMMx~:~~~(MMMMM#<~~:~:~~((dMMMMMMMMMMMMMMMMMMMMMMMM#  ,WMMMMMag3                                 ...gMMMMMMMMMM]              JMMMMHH#HHHHHHHHHHHHHHMMMMF                               //
//                   .THMMMMF~~:~~:?T">~~~:((+gMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF     7HMMMMMMNa+....       `  ` .......JgNMMMMMMMMMMMMHHMMMM.             ,MMMMHHH#HH#HH#HH#HH#HMMMM%                               //
//                     .MMMM>~:~~:~~~~((+MMMMMMMMMMMMMMMMMMHHHHHHHHHHHHHMMMM]        (THMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMHHHHHHHMMMMb             .MMMMHHHHHHHMYWMHHHHH#MMMM`                               //
//                      MMMM[~~:~~:(+MMMMMMMMMMMHHHHHHHHHHHHHHHHHHHHHHHHMMMM\            dMMMMMMMMMMMMMMMMMMMMMMMMMMMM#HHHHHHHHHHHHHHHMMMN              MMM#7HH#HHF    4HHHHMMMM#                                //
//                      dMMMN,~:(+MMMMMMMMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMMM:            JMMM#HHHHHHH#HHHHHHHHHHHHHHHHHHHHH#HH#HH#HHHHMMMM;             MMM#  WHH#]    -HH#HMMMMF                                //
//                       UMMMMNMMMMMMMMHHHHHHHHHHHHHH#HH#HH#HH#HH#HH#HHHMMMM`            ,MMMMHHHHHHHHH#HHHHHHHHH#HHMY"7??7TM#HHHHH#HHMMMMb             MMM#  .HH#\    -HHHHMMMM\                                //
//                        (HMMMMMMMMHHHHHHHH#H""""7????"WHHHHHHH#@=`    dMMM             .MMMMHHHHH##""WHH#HH#HHHHY          ?HH#HHH#MYMMMM.           .MMMF   qHH}    -HHH#MMMM                                 //
//                          .MMMMMMHHHHHH#HHF            /#HH#HH@       dMMM              MMMMHHHHH]    (MHHHHH#H%            (HHHHHP  ,MMMb           dMMM!   .MH!    (HH#MMMM#                                 //
//                            TMMMMMHH#HHHHH]             HHHHHHb       dMMM_             MMMMHH#HH]     dHH#HHH#      ...     MHH##    ZMMMb         .MMMF     JH`    J#HHMMMMF                                 //
//                             ,MMMMMHHH#HH#N     Qg,     ,H#HHH#     ,HMMMM[             MMMMHHHH#]     dHHHHHH@      (HH|    (HHH]     WMMMN,     .(MMM@ -     M     JHHHMMMM\                                 //
//                              .MMMMMHHHHHHH;    -HN      MHHH#M     ,HMMMMb        `    MMMMHHHHH]     dHH#HH#@      -HHb    .HH#\     HMMMMMNg(+MMMMMF  (.    (     dHH#MMMM                                  //
//                                MMMMM#HH#HHb     MH[     dHHHHH_    .7"WMMM,    `      .MMMMHH#HH]     dHHHHHHN      -HH@     M#H!     HHHMMMMMMMMMMD`   J]          WHHMMMM#                                  //
//                                .MMMMMHHHH#H,            "YHHHH)       .MMMN,         .MMMMHHHHHHb     JHH#HHHM.     ,HHN     dHH_     MHHF  ?""MMH]     JN.         HHHMMMMF                                  //
//                                 ,MMMMMHHHHHb              .MH#]        ,MMMMa.      .MMMMMHHH#HH@     JHHH#HH#[     .HHN     JHH_     dHH]     HHHF     gH]        .HHHMMMM\                                  //
//                                  (MMMM#HHHHH;              ,HHb     mmp  TMMMMNg(.gMMMMMMHHHHH#HN     JHHHHHHHN      (MD     JHH)     JHH\    .HHHb     dHM,       (HH#MMMM                                   //
//                                   WMMMMH#HH#N     (gg       MHN     HHN    TMMMMMMMMMH4HHHH#HHHHM     (#HH#HH##L             dH#b     .W3     .H#HHm, ..HHHH#MNQQHHHHHMMMM#                                   //
//                                   .MMMMMHHHHH[    .MHL      JHM     HH#_    dHMMM#"!   7?!~` 7MHH.    .?7"""WHHHp           .HHHH,            dHHHHHHH#HHHH#H##HHHHHHHMMMM]                                   //
//                                    JMMMMHHHHHN     JHM.     .#H     JHH[    dHHHHM.           (HH[           JHH#N,        .MHHH#M,          .HHH#HH#HHHH#HHHHHHHHHHHHMMMM!                                   //
//                                     MMMMMH#HHH]     !       ,HH,    .HHHN+gMHHHHHHN.        ..MHHN,         .JHHHH##H+...+MHHHHHHH#N+......(MHHHHHHHHHHHHHHHHHH#HH#HHMMMM#                                    //
//                                     ,MMMMHHHHHN.          .dHH#N+..dHH#HHHHHHH#HHHH#mJ.JgMHHHHHHHHHHMNmmmHMHHHHHHHHHHHHHHHHHHH#HHHHHHHHHHHHHHHMMMHWYYYYYWHMMMH#HHHH#HMMMMF                                    //
//                                      HMMMMH#HHHh,     ..dHHHHHHHHHHHHHHHHHHHHHH#HHHHHHHHHHHHHHHHHHHMMYY"WMHH#HH#HHHHH#HHHHHHH#HH#HH#HH#HHHH#!                 .M#HHH#MMMM!                                    //
//                                      ,MMMMHHHHHHHH#HHHHHMY""!     ?H#HH#HH#MY""77777"YMHHHHHHHM"!         (M#HHH#H#HHMY""""WMHHHHHHM"` _THHb                   JHHHHMMMMF                                     //
//                                       dMMMMH#HHHHHHHHM^             ?HHHHHH'           7#HH#HM!            .MHHHHHM"         .WHH#HF     JHH,                 .HHH#HMMMM%                                     //
//                                       ,MMMM#HHH#HHHHHF         .     (HH#HH-            XHHHHM.     .+,     ,HH#HH%            4HHHb     ,HH##HH#H)     ,#H#HHHHHHHMMMM#                                      //
//                                        dMMMMHHHHH#HHHb      .dHHb     J#HHH]     ,H]    .H#HH#[     ,H#`    .HHHHH]    .HN,    .HH#N      HHHHHHH#]     ,HHHHHHH#HHMMMM]                                      //
//                                        .MMMMMH#HHH#HHN      MH#HH;    .HHHHb     .Y"     dHHHHb             ,#HH#H]    ,HH#     MHHM.     WHHH#HHHF     ,HHH#HHHHHMMMM#                                       //
//                                         dMMMMHHHHHHH#H-     ?"""7     .#HH#N             .H#HHH.             .HHHH]      `     .HHHH|     JHH#HHHH@     -HH#HH#HH#MMMM$                                       //
//                                          MMMMMHH#HHHHHb              `JHHHHM.             dHHHH]              .HHHF            HHH#Hb     ,#HHHH#HN     JHHHHHH#HMMMM#                                        //
//                                          (MMMMHHH#HHHHN              JHHHHH#|     (HM[    .#HH#N     -#HN      dHHb             WHHHN.    .HHHHHHHN     J#HH#HHH#MMMM^                                        //
//                                           MMMMMHHH#H#HH[              7MHHHH]     ,#HN     WHHHH[    .HHH|     dHH@     da..     MHH#]     HH#HH#HH     dHHHHHHHMMMMF                                         //
//                                           ,MMMMMHHHHH##b     .J.        THHHb     .HHH[    ,#HHHN     ??!      MHHN     JHHF     dHHHN.    JHHHHH#H.    dHH#HH#MMMM#                                          //
//                                            dMMMMHHHHHHHH,     M#Hm,                                                                                                                                           //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BNRT is ERC721Creator {
    constructor() ERC721Creator("BALLOON RABBIT", "BNRT") {}
}