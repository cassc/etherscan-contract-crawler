// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BEYOND THE REACH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    capturing love&light.    //
//                             //
//                             //
/////////////////////////////////


contract BTR is ERC721Creator {
    constructor() ERC721Creator("BEYOND THE REACH", "BTR") {}
}