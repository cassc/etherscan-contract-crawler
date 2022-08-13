// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored AFRO APE Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Bored AFRO APE Club    //
//                           //
//                           //
///////////////////////////////


contract BAAC is ERC721Creator {
    constructor() ERC721Creator("Bored AFRO APE Club", "BAAC") {}
}