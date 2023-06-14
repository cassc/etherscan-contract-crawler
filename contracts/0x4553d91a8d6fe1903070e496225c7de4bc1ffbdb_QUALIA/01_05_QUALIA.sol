// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Qualia
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    QUALIA    //
//              //
//              //
//////////////////


contract QUALIA is ERC721Creator {
    constructor() ERC721Creator("Qualia", "QUALIA") {}
}