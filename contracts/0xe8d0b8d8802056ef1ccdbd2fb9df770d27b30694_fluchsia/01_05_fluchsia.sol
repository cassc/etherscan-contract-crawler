// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fluchsia
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Mia Forrest    //
//                   //
//                   //
///////////////////////


contract fluchsia is ERC721Creator {
    constructor() ERC721Creator("Fluchsia", "fluchsia") {}
}