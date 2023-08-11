// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JACOBLEWIS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Jacob Lewis    //
//                   //
//                   //
///////////////////////


contract JL is ERC721Creator {
    constructor() ERC721Creator("JACOBLEWIS", "JL") {}
}