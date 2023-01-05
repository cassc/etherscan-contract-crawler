// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Xeniia
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//     / /            / /         //
//    (_/_  ___  ___      ___     //
//     /  )|___)|   )| | |   )    //
//    /  / |__  |  / | | |__/|    //
//                                //
//                                //
//                                //
////////////////////////////////////


contract X3D is ERC721Creator {
    constructor() ERC721Creator("Xeniia", "X3D") {}
}