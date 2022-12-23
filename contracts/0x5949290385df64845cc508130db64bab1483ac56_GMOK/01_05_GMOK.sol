// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM Factory
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//        GGGGGGGGGGGGG     MMMMMMMMMMMMMMMMMMM      //
//        GGGGGGGGGGGGG     MMMMMMMMMMMMMMMMMMM      //
//        GGG       GGG     MMMM    MMM    MMMM      //
//        GGG               MMMM    MMM    MMMM      //
//        GGG               MMMM    MMM    MMMM      //
//        GGG     GGGGG     MMMM    MMM    MMMM      //
//        GGG     GGGGG     MMMM    MMM    MMMM      //
//        GGG       GGG     MMMM    MMM    MMMM      //
//        GGGGGGGGGGGGG     MMMM    MMM    MMMM      //
//        GGGGGGGGGGGGG     MMMM    MMM    MMMM      //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract GMOK is ERC1155Creator {
    constructor() ERC1155Creator("GM Factory", "GMOK") {}
}