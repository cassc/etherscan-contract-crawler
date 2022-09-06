// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lakeside by Shane Rocheleau
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    LAKESIDE BY SHANE ROCHELEAU    //
//    IMAGES © SHANE ROCHELEAU       //
//    ALL RIGHTS RESERVED            //
//                                   //
//                                   //
///////////////////////////////////////


contract LAKE is ERC721Creator {
    constructor() ERC721Creator("Lakeside by Shane Rocheleau", "LAKE") {}
}