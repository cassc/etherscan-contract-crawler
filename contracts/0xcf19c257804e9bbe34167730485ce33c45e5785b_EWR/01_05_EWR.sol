// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EditionswithRaaj
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    EWR    //
//           //
//           //
///////////////


contract EWR is ERC721Creator {
    constructor() ERC721Creator("EditionswithRaaj", "EWR") {}
}