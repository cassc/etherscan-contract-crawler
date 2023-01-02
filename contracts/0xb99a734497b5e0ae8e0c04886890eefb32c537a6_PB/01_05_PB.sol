// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: punkbill
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    punkbill ERC721    //
//                       //
//                       //
///////////////////////////


contract PB is ERC721Creator {
    constructor() ERC721Creator("punkbill", "PB") {}
}