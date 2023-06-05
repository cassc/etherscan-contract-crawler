// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fractured Reflections
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ***FracturedReflections***    //
//                                  //
//                                  //
//////////////////////////////////////


contract FR is ERC721Creator {
    constructor() ERC721Creator("Fractured Reflections", "FR") {}
}