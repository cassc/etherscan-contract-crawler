// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Pepe Pass    //
//                 //
//                 //
/////////////////////


contract pepe is ERC721Creator {
    constructor() ERC721Creator("Pepe Pass", "pepe") {}
}