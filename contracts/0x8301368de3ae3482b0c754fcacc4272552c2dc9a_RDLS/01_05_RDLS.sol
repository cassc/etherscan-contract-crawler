// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Red Lights
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Art by Leni Amber    //
//                         //
//                         //
/////////////////////////////


contract RDLS is ERC721Creator {
    constructor() ERC721Creator("Red Lights", "RDLS") {}
}