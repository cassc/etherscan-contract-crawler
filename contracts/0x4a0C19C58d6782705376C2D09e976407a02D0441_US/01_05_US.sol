// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: untitled season
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//                    //
//     | | | / __|    //
//     | |_| \__ \    //
//      \___/|___/    //
//                    //
//                    //
//                    //
////////////////////////


contract US is ERC721Creator {
    constructor() ERC721Creator("untitled season", "US") {}
}