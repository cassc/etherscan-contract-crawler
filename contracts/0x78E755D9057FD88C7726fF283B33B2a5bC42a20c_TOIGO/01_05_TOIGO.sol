// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I’m In Toigo’s Door
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    :-)    //
//           //
//           //
///////////////


contract TOIGO is ERC721Creator {
    constructor() ERC721Creator(unicode"I’m In Toigo’s Door", "TOIGO") {}
}