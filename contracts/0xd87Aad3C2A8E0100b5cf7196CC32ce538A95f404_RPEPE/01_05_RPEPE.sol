// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rubiks Checkpe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    RUBIKSPEPE    //
//                  //
//                  //
//////////////////////


contract RPEPE is ERC721Creator {
    constructor() ERC721Creator("Rubiks Checkpe", "RPEPE") {}
}