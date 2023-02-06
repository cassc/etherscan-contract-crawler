// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blurred Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    vvvvvvvv    //
//                //
//                //
////////////////////


contract pixel is ERC721Creator {
    constructor() ERC721Creator("Blurred Checks", "pixel") {}
}