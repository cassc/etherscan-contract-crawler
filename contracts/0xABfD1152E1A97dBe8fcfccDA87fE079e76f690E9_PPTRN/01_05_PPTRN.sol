// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepettern
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    FEELS SOOTHING MAN    //
//                          //
//                          //
//////////////////////////////


contract PPTRN is ERC721Creator {
    constructor() ERC721Creator("Pepettern", "PPTRN") {}
}