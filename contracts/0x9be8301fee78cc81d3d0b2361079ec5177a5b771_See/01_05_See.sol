// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sebeth editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Sebeth editions    //
//                       //
//                       //
///////////////////////////


contract See is ERC721Creator {
    constructor() ERC721Creator("Sebeth editions", "See") {}
}