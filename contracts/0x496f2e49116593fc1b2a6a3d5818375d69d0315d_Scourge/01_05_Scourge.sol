// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Scourge
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    The Scourge    //
//                   //
//                   //
///////////////////////


contract Scourge is ERC721Creator {
    constructor() ERC721Creator("The Scourge", "Scourge") {}
}