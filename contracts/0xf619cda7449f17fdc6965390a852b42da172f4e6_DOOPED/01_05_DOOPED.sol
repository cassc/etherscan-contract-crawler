// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DoodlesParody
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    DOOPED    //
//              //
//              //
//////////////////


contract DOOPED is ERC721Creator {
    constructor() ERC721Creator("DoodlesParody", "DOOPED") {}
}