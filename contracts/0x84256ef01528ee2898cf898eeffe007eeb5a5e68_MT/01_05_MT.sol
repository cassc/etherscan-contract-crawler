// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MANITEST
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//              MMMMMMM;        .MMMMMM#         .MMMMMN.        .MMMMk.         [email protected]     dMMMM`             //
//              MMMMMMMb        dMMMMMM#         dMMMMMMb        .MMMMMN,        [email protected]     dMMMM`             //
//              MMMMMMMM;      .MMMMMMM#        .MMM#MMMMc       .MMMMMMN,       [email protected]     dMMMM`             //
//              MMMMZMMMN      MMM#JMMM#       .MMMM\,MMMN.      .MMMMMMMMp      [email protected]     dMMMM`             //
//              MMMM)dMMM|    .MMMF(MMM#       [email protected]  dMMMb      .MMMMrMMMMk.    [email protected]     dMMMM`             //
//              MMMM[.MMM#    MMM#`(MMM#      (MMMM!  .MMMM[     .MMMM) WMMMN,   [email protected]     dMMMM`             //
//              MMMM] dMMM[  .MMMF (MMM#     .MMMMF    dMMMN.    .MMMM[  7MMMN,  [email protected]     dMMMM`             //
//              MMMM] .MMMN  MMM#  JMMM#   ` dMMM#      MMMMb  ` .MMMM]   ?MMMMp [email protected]     dMMMM`             //
//              MMMM]  dMMM[.MMMt  gMMM#    .MMMMNNNNNNNMMMMM[   .MMMM]    ,MMMMR([email protected]     dMMMM`             //
//              MMMM]  .MMMNMMM#   dMMM#   .MMMMMMMMMMMMMMMMMN.  .MMMM]      [email protected]     dMMMM`             //
//              MMMMF   JMMMMMM%   dMMM#   dMMMM"""""""""7MMMMb  .MMMM]       [email protected]     dMMMM`             //
//    ..........MMMMb....MMMMM#....dMMMN..(MMMMb.......   dMMMMa.+MMMMNgg+.,   ?MMMMMb.....dMMMM-.........    //
//    MMMMMMMMMMMMMMMMMMMMMMMM](MMMMMMMMMMMMMMMMMMMMMM{   .MMMMMMMMMMMMMMMMMMN, ,MMMMMMMMMMMMMMMMMMMMMMMM#    //
//    MMHHHMHHHMMMMMMHHHHHHHHM\(MMMMMMHHHHHHHHHHHHHHHM!   .MMMMM9=`     _7WMMMMN,-MMHHHHHMMMMMMMHHMHHHHHMB    //
//             .MMMM]          ([email protected]                     .MMMMY             TMMMM,         (MMMN              //
//             .MMMM]          ([email protected]                   ` dMMM#               dMMMN.        (MMMN              //
//             .MMMM]          ([email protected]                     dMMMM,              .""""!        (MMMN              //
//             .MMMM]          ([email protected]                     ,MMMMMN,.      `                  (MMMN              //
//             .MMMM]          (MMMN................      ,HMMMMMMMNNgJ...                 (MMMN              //
//             .MMMM]          (MMMMMMMMMMMMMMMMMMM#        .TMMMMMMMMMMMMMMNJ,            (MMMN              //
//             .MMMM]          ([email protected]             ?"TWMMMMMMMMMMNe          (MMMN              //
//             .MMMM]          ([email protected]                  `                  _7TMMMMMN.        (MMMN              //
//             .MMMM]          ([email protected]                    ` ...                TMMMMb        (MMMN              //
//             .MMMM]          ([email protected]                   ,MMMMb                 MMMMN        (MMMN              //
//             .MMMM]          ([email protected]                    MMMMN,               .MMMM#        (MMMN              //
//             .MMMM]          ([email protected]                    ,MMMMN,`            .dMMMM'        (MMMN              //
//             .MMMM]          (MMMN((((((((((((((((((,  .MMMMMNJ,.`     ..gMMMMM^         (MMMN              //
//             .MMMM]          (MMMMMMMMMMMMMMMMMMMMMM#    ?WMMMMMMMMMMMMMMMMM#=           (MMMN              //
//              """"^          ("""""""""""""""""""""""       _"THMMMMMMMMB"^              ,""""              //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MT is ERC1155Creator {
    constructor() ERC1155Creator("MANITEST", "MT") {}
}