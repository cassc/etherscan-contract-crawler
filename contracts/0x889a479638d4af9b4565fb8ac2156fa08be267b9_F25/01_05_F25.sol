// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 25Frames
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    25Frames by minigogy    //
//                            //
//                            //
////////////////////////////////


contract F25 is ERC721Creator {
    constructor() ERC721Creator("25Frames", "F25") {}
}