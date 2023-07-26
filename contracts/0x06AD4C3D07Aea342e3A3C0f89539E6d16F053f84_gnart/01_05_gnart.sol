// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gnars.jan.22
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    lights. camera. shoot.    //
//                              //
//                              //
//////////////////////////////////


contract gnart is ERC721Creator {
    constructor() ERC721Creator("gnars.jan.22", "gnart") {}
}