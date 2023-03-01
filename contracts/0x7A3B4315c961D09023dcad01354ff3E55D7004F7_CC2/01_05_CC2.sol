// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CC2 Ventures - in Anime Form
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Who dis?     //
//                 //
//                 //
/////////////////////


contract CC2 is ERC721Creator {
    constructor() ERC721Creator("CC2 Ventures - in Anime Form", "CC2") {}
}