// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Suprephonic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Suprephonic by indie.    //
//                             //
//                             //
/////////////////////////////////


contract SPHON is ERC721Creator {
    constructor() ERC721Creator("Suprephonic", "SPHON") {}
}