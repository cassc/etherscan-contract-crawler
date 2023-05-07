// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions X Mia Forrest
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Mia Forrest    //
//                   //
//                   //
///////////////////////


contract MFeditions is ERC721Creator {
    constructor() ERC721Creator("Editions X Mia Forrest", "MFeditions") {}
}