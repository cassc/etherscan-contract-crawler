// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LBBREAD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    HarmonySage    //
//                   //
//                   //
///////////////////////


contract HTI is ERC721Creator {
    constructor() ERC721Creator("LBBREAD", "HTI") {}
}