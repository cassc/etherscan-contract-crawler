// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OTONE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//        .gMMMMMNa,.   .NNNNNNNNNNNNN]   ..gMMMMMNg,.     (NNm.       NNN|  jNNNNNNNNNNNN]    //
//     .JMMMM""""MMMMm. .MMMMMMMMMMMMMt .+MMMM""""MMMMm.   JMMMM,      MMM]  dMMMHHHHHHHHH5    //
//    .MMMB`      .WMMN,     .MMM~     [email protected]`      .MMMN.  JMMMMMh.    MMM]  dMMF              //
//    dMM#          [email protected]     .MMM~     dMM#          MMMb  JMM]7MMM,   dMM]  dMMb.........     //
//    MMMF          JMMN     .MMM~     MMMF          dMM#  JMMF .HMMh. dMM]  [email protected]     //
//    dMMN          dMMF     .MMM~     MMMN          MMMF  JMMF   7MMN,JMM]  dMMF              //
//    .MMMN.      .(MMM'     .MMM~     ,MMMh.      .JMMM`  JMMF    ,MMMMMM]  dMMF              //
//     .WMMMNg..JMMMM#!      .MNM~      [email protected]`   JMMF      TMMMM]  dMMNgggggggggg    //
//        THMMMMMM#"!        .MMM~        .THMMMMMM#"`     JMMF       ,MMM\  dMMMMMMMMMMMMM    //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract OTONE is ERC1155Creator {
    constructor() ERC1155Creator("OTONE", "OTONE") {}
}