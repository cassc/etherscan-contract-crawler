// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Feline Fight Club Beta
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    :-)    //
//           //
//           //
///////////////


contract CAT is ERC721Creator {
    constructor() ERC721Creator("Feline Fight Club Beta", "CAT") {}
}