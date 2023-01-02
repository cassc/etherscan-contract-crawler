// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TOILART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    TOILART    //
//               //
//               //
///////////////////


contract TLRT is ERC721Creator {
    constructor() ERC721Creator("TOILART", "TLRT") {}
}