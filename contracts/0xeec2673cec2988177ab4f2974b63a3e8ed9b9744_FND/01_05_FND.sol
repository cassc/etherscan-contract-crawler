// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Creators on Foundation
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    ▲●■    //
//           //
//           //
///////////////


contract FND is ERC721Creator {
    constructor() ERC721Creator("Creators on Foundation", "FND") {}
}