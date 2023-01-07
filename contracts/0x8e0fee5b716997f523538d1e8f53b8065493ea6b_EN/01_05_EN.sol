// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: o.collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    ○○○    //
//           //
//           //
///////////////


contract EN is ERC721Creator {
    constructor() ERC721Creator("o.collection", "EN") {}
}