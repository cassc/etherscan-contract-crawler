// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: another me
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    I See You    //
//                 //
//                 //
/////////////////////


contract AME is ERC721Creator {
    constructor() ERC721Creator("another me", "AME") {}
}