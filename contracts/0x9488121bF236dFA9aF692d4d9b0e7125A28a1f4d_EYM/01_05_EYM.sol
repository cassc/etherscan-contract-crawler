// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EXPLORE_YOUR_MIND
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//                                       //
//    ________________.___.  _____       //
//    \_   _____/\__  |   | /     \      //
//     |    __)_  /   |   |/  \ /  \     //
//     |        \ \____   /    Y    \    //
//    /_______  / / ______\____|__  /    //
//            \/  \/              \/     //
//                                       //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract EYM is ERC721Creator {
    constructor() ERC721Creator("EXPLORE_YOUR_MIND", "EYM") {}
}