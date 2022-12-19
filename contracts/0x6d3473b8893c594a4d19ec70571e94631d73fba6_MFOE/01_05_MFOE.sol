// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mystic Forest - Open Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    Mystic Forest - Open Editions    //
//                                     //
//                                     //
/////////////////////////////////////////


contract MFOE is ERC721Creator {
    constructor() ERC721Creator("Mystic Forest - Open Editions", "MFOE") {}
}