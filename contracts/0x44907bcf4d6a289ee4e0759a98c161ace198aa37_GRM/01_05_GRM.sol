// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GRANMAS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    GRANMAS    //
//               //
//               //
///////////////////


contract GRM is ERC721Creator {
    constructor() ERC721Creator("GRANMAS", "GRM") {}
}