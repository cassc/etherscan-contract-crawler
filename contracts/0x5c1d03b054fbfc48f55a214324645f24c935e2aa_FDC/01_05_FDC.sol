// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fodcoin
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Fodcoin FDC    //
//                   //
//                   //
///////////////////////


contract FDC is ERC721Creator {
    constructor() ERC721Creator("Fodcoin", "FDC") {}
}