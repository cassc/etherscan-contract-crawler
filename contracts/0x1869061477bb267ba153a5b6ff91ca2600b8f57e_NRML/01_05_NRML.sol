// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Normal Map
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Normal Map    //
//                  //
//                  //
//////////////////////


contract NRML is ERC721Creator {
    constructor() ERC721Creator("Normal Map", "NRML") {}
}