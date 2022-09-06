// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wiv_ian
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    -------    //
//    Wiv_ian    //
//    -------    //
//               //
//               //
///////////////////


contract wiv is ERC721Creator {
    constructor() ERC721Creator("Wiv_ian", "wiv") {}
}