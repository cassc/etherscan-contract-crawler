// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BLACK IS BEAUTIFUL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    BIB    //
//           //
//           //
///////////////


contract BIB is ERC721Creator {
    constructor() ERC721Creator("BLACK IS BEAUTIFUL", "BIB") {}
}