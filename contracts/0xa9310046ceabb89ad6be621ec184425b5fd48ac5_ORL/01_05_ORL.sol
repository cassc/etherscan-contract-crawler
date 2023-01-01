// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Orange Lights
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Art by Leni Amber    //
//                         //
//                         //
/////////////////////////////


contract ORL is ERC721Creator {
    constructor() ERC721Creator("Orange Lights", "ORL") {}
}