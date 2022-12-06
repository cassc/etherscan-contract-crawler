// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DREAMY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//              //
//              //
//    DREAMY    //
//              //
//              //
//              //
//              //
//////////////////


contract DREAMY is ERC721Creator {
    constructor() ERC721Creator("DREAMY", "DREAMY") {}
}