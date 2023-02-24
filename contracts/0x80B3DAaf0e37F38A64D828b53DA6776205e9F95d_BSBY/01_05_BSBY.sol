// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BASEBOY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    BASEBOY    //
//               //
//               //
///////////////////


contract BSBY is ERC721Creator {
    constructor() ERC721Creator("BASEBOY", "BSBY") {}
}