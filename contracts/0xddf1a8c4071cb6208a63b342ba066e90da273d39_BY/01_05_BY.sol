// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bonesyaga
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    new lights new times.    //
//                             //
//                             //
/////////////////////////////////


contract BY is ERC721Creator {
    constructor() ERC721Creator("Bonesyaga", "BY") {}
}