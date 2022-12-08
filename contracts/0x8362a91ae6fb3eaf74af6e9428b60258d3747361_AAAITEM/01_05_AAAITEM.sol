// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TANAKA's items
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//               MMMMMMMMMMMMMF          JMM,           Mh.       [email protected]           .MM]           dMF     .MMM!          JMM,           MM)     MMMMMMMMMMMMM#     .MMMMMMMMMM#     .MMMx        .MM]    //
//               MMMMMMMMMMMMMF         .MMMb           MMN.      [email protected]           MMMN.          dMF    .MMM^          .MMMb           MM)     MMMMMMMMMMMMM#     .MMMMMMMMMM#      ,MMM,      .MMM]    //
//               MMMMMMMMMMMMMF        `dMMMM,     `    MMMN,     [email protected]          .MMMM]          dMF   .MMM^           dMMMM,          MM)     [email protected]     .MMMMMMMMMM#       ,MMM,    .MMMM]    //
//                    .MM              .MMFMMN          MMMMM,    [email protected]         .MMFdMN.         dMF  .MMM'           .MMtMMb          MM)          .MM`                              ,MMM,  .MMMMM]    //
//                    .MM              dM# (MM|         MMMMMMx   [email protected]         -MM!.MMb         dMF .MMM!            MM# (MMc         MM)          .MM`           ....                -MMM,.MMM$dM]    //
//                    .MM             .MM%  MMN         MM)JMMMp  [email protected]        .MMF  dMM,        dMF.MM#`            .MM\  MMN         MM)          .MM`          .MMMN                 (MMNMMMD dM]    //
//                    .MM             MMF   ,MM]        MM) ,MMMb [email protected]        JMM`   MMb        dMFdMMb             MMF   ,MM[        MM)          .MM`          .MMMN                  JMMMMF  dM]    //
//            `       .MM            .MM'    WMN.       MM)  ,[email protected]       .MMF    JMM,       dMF UMMh           -MM'    HMN        NM)          .MM`          ."""9                   ?MMF   dM]    //
//                    .MM`          .MMF     .MM]       MM)   [email protected]       dM#      MMN       dMF  TMMN.        .MMF     .MM]       MM)          .MM`                                   ?F    dM]    //
//                    .MM       `   (MM!      dMN.      NM)     [email protected]      .MMt      -MM[      dMF   TMMN.       (MM`      dMN.      MM)          .MM`          ............                   dM]    //
//                    .MM          .MMF       .MMb      MM)      [email protected]      dM#        HMN      dMF    ?MMN.     .MMF       .MMb      MM)          .MM`          .MMMMMMMMMMM                   dM]    //
//                    .MM          JMM`        JMM,     MM)       [email protected]     .MM\        .MM]     dMF     ?MMN,    JMM         dMM,     MM)          .MM`          .MMMMMMMMMMM                   dM]    //
//                     ??          ??'          ??!     ??`        ?"     _?!          ??'     _?'      _??!    ??'          ??!     ??`           ??           .???????????                   ??'    //
//            `                                                                                                                                                                                       //
//                              `                                                                                                                                                                     //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AAAITEM is ERC1155Creator {
    constructor() ERC1155Creator("TANAKA's items", "AAAITEM") {}
}