// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DeanMade7
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    [Nostalgic:Notions]    //
//                           //
//                           //
///////////////////////////////


contract DM7 is ERC721Creator {
    constructor() ERC721Creator("DeanMade7", "DM7") {}
}