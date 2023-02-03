// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xfaux Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    0xfaux Editions    //
//                       //
//                       //
///////////////////////////


contract faux is ERC721Creator {
    constructor() ERC721Creator("0xfaux Editions", "faux") {}
}