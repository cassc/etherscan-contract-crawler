// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nanzbonanz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    :)     //
//           //
//           //
///////////////


contract NZB is ERC721Creator {
    constructor() ERC721Creator("Nanzbonanz", "NZB") {}
}