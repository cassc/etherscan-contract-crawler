// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frenzy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Frenzy    //
//              //
//              //
//////////////////


contract Eth is ERC721Creator {
    constructor() ERC721Creator("Frenzy", "Eth") {}
}