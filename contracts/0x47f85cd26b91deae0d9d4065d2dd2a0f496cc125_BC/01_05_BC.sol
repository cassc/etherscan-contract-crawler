// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: benecat
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                          ....,       .ggg,.                                           //
//                                        .MMB""WMb   .M#^ ?TMN,                                         //
//                                      .MM^     ,M[  M#      TM,                                        //
//                                      dM`      .M%  M#       M#                                        //
//                                      MN.     [email protected]   dM,     .M#                                        //
//                                      .YMMMN. [email protected]  MMMM"                                         //
//                                          (M;            M#                ..,                         //
//                        .MMh              ,M) .ga. ..J, .MF             ..M#TM[                        //
//                       [email protected],Mb             ,M] "!?' J^_9 dM             .MB!  MN                        //
//                      .M#  ,Mb             Mb          gM'           .dM^    (M;                       //
//                      JM'   ,Mb       ?""""YMM"_   ,"WMM80A,        [email protected]       [email protected]                       //
//                     .Mt     ,Mb       ZTT""TMNe.. TMM"""YYT       JMt        dM.                      //
//                    .MF       ,MR           .dMMMMMMMN,          .dM'         ,M]                      //
//                    dM`        ,MN.        .MD  7"=  TMp         dM!          .MF                      //
//                   .M]          .MN,      .MF         dM,       JM'            M#                      //
//                   d#             WM,     (MMMMMe [email protected]      .M\             dN                      //
//                   MF              ?MNg++JMMN..(MNM#..MMN     .MF              JM_                     //
//                  .M]                _???777""""""""""[email protected]`              -M)                     //
//                  .M}                                                          ,MN,                    //
//                  dM                                                             ?WMm,                 //
//                 [email protected]                                                                7MMa.              //
//                .MF                    ...((...                                       .TMm.            //
//               .M$                  .gMMB""""WMN,             ..MMMMMMMa,               .HN,           //
//              -M\                  jM"         TMb          .JMD!      7MN,               TMe          //
//             .MF                  dM'     .,    ,Mb        .M#!          TM|               ?Mp         //
//             JM`                 .MF    .MMMN    dM.       JM:   .MMN,    MN                ?Mc        //
//            .MF                   MN     TMMD    dM`       dM.   JMMMt    JM~                MN        //
//            -M:                   JMe           .MF        (M[     !     .M#                 ,M[       //
//            M#                     ?MN,.     ..MMt          TMe.        .MM!                  Mb       //
//            MF                       7WMMMMMMMB=             ,WMN-....JMM"                    M#       //
//           .MF                                      .Jg,.       ?""""""`                      M#       //
//            MN                                     .MMMM#                                    .MF       //
//            dN.                                     7MMM=                       ...`        `.M\       //
//            ,M]                                      ,M_        ??77777777?!`               .MF        //
//             MN            ?????777777777777777      ,M_                          ..       [email protected]         //
//             ,M]                                     ,M_        .....(--<??7777!`       ` [email protected]          //
//              WN.          .....--<?777777?!`        ,M_                                 .MF           //
//              .MN                                    ,M_                               .dM=            //
//               ,Mb                                    =                               [email protected]`             //
//                ,MN,                           .(gMMMMMMMNg,.                      `.MM^               //
//                  TMNJ.                    ..MM#"!        ?YMN,                   .MM=                 //
//                    .TMNJ.                 79^               ?W$               .gMB^                   //
//                       .TMMa,.                                              .JM#"                      //
//                           ?TMMNa,.                                      .+MM"                         //
//                                ?TMMMNg...                        `...gMMB=                            //
//                                      ?""HMMMMNNggJ(....(JJ&ggNNMMMM""^                                //
//                                                ~?777""777??!`                                         //
//                ..,                                                                                    //
//                MM)                                                                  ,MM               //
//                MMl(gg,     .Jggg,    .gg.gga.     .gggJ,     ..gNag,   ..ggNgJ.   .ggMMggg            //
//                MM#=?MMb   [email protected]!?TMN   .MMF?WM#   .MM"~?MM[   .MMD!?"%   ."!` 7MN   -?zMM???            //
//                MM\  -M#  .MMNNNMMM:  .MM  -M#   JMMNNNMM#   dMF        .MMMMMMM     .MM               //
//                MMb  JM#   MM|    .   .MM  .M#   (MN.    .   JMN.   .   MMF  .MM     ,MM               //
//                MMMMMM#'   ,WMMMMM#   ,MM  .M#    7MMMMMM]    TMMMMM%   ?MMNMMMM      WMMMM            //
//                               `                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                              `   `   `   `   `   `    //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
//                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BC is ERC721Creator {
    constructor() ERC721Creator("benecat", "BC") {}
}