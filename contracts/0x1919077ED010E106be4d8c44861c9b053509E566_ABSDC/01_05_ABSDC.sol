// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABS in DC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    ABS    //
//           //
//           //
///////////////


contract ABSDC is ERC721Creator {
    constructor() ERC721Creator("ABS in DC", "ABSDC") {}
}