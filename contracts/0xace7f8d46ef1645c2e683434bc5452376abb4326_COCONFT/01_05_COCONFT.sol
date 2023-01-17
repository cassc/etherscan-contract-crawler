// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cocomaru
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    COCONFT    //
//               //
//               //
///////////////////


contract COCONFT is ERC721Creator {
    constructor() ERC721Creator("cocomaru", "COCONFT") {}
}