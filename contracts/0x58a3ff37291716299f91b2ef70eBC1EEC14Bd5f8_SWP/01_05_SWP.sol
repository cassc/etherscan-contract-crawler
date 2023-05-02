// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stand With PEPE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    STAND FOR PEPE    //
//                      //
//                      //
//////////////////////////


contract SWP is ERC721Creator {
    constructor() ERC721Creator("Stand With PEPE", "SWP") {}
}