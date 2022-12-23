// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The coming of the holy night
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    SIMIZU    //
//              //
//              //
//////////////////


contract SIMIZU is ERC721Creator {
    constructor() ERC721Creator("The coming of the holy night", "SIMIZU") {}
}