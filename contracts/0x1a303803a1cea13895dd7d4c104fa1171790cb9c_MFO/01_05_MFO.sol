// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mystic Forg
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Mystic Forg    //
//                   //
//                   //
///////////////////////


contract MFO is ERC1155Creator {
    constructor() ERC1155Creator("Mystic Forg", "MFO") {}
}