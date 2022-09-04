// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Roam Bird
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Roam Bird | roam design    //
//                               //
//                               //
///////////////////////////////////


contract RBIRD is ERC721Creator {
    constructor() ERC721Creator("Roam Bird", "RBIRD") {}
}