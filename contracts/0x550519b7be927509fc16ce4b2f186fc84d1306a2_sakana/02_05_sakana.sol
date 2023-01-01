// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sakana
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    .sSSSSSSSs. .sSSSSs.    .sSSS  SSSSS  .sSSSSs.    .sSSSs.  SSSSS .sSSSSs.        //
//    S SSS SSSS' S SSSSSSSs. S SSS SSSSS   S SSSSSSSs. S SSS SS SSSSS S SSSSSSSs.     //
//    S  SS       S  SS SSSSS S  SS SSSSS   S  SS SSSSS S  SS  `sSSSSS S  SS SSSSS     //
//    `SSSSsSSSa. S..SSsSSSSS S..SSsSSSSS   S..SSsSSSSS S..SS    SSSSS S..SSsSSSSS     //
//    .sSSS SSSSS S:::S SSSSS S:::S SSSSS   S:::S SSSSS S:::S    SSSSS S:::S SSSSS     //
//    S;;;S SSSSS S;;;S SSSSS S;;;S  SSSSS  S;;;S SSSSS S;;;S    SSSSS S;;;S SSSSS     //
//    S%%%S SSSSS S%%%S SSSSS S%%%S  SSSSS  S%%%S SSSSS S%%%S    SSSSS S%%%S SSSSS     //
//    SSSSSsSSSSS SSSSS SSSSS SSSSS   SSSSS SSSSS SSSSS SSSSS    SSSSS SSSSS SSSSS     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract sakana is ERC721Creator {
    constructor() ERC721Creator("sakana", "sakana") {}
}