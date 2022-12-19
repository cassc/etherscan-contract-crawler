// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kino_Nae's season collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    N.K    //
//           //
//           //
///////////////


contract KSC is ERC721Creator {
    constructor() ERC721Creator("Kino_Nae's season collection", "KSC") {}
}