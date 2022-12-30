// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rinoceronte by Lucio Di Capua
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Rinoceronte by     //
//    4 1/2 Year old     //
//    Lucio DI Capua     //
//                       //
//                       //
///////////////////////////


contract LD is ERC721Creator {
    constructor() ERC721Creator("Rinoceronte by Lucio Di Capua", "LD") {}
}