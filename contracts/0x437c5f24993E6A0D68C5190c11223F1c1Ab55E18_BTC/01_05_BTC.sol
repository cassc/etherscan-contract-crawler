// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BURN4BTC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    BURN FOR ORDINAL     //
//                         //
//                         //
/////////////////////////////


contract BTC is ERC721Creator {
    constructor() ERC721Creator("BURN4BTC", "BTC") {}
}