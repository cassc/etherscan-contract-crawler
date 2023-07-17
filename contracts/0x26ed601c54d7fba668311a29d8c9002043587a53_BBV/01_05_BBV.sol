// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bing Bong Vegas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    BBV    //
//           //
//           //
//           //
///////////////


contract BBV is ERC721Creator {
    constructor() ERC721Creator("Bing Bong Vegas", "BBV") {}
}