// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The MOB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//       _____   ________ __________     //
//      /     \  \_____  \\______   \    //
//     /  \ /  \  /   |   \|    |  _/    //
//    /    Y    \/    |    \    |   \    //
//    \____|__  /\_______  /______  /    //
//            \/         \/       \/     //
//                                       //
//                                       //
///////////////////////////////////////////


contract MOB is ERC721Creator {
    constructor() ERC721Creator("The MOB", "MOB") {}
}