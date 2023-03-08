// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PassCard Curated
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    Satoshi    //
//               //
//               //
///////////////////


contract PASS is ERC721Creator {
    constructor() ERC721Creator("PassCard Curated", "PASS") {}
}