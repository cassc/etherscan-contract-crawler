// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GODTAIL EDITION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    GODTAIL    //
//               //
//               //
///////////////////


contract GTE is ERC721Creator {
    constructor() ERC721Creator("GODTAIL EDITION", "GTE") {}
}