// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Arbinauts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    The Arbinauts    //
//                     //
//                     //
/////////////////////////


contract ARB is ERC721Creator {
    constructor() ERC721Creator("The Arbinauts", "ARB") {}
}