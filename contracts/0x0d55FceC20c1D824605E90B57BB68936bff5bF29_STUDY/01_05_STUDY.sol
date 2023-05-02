// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STUDIES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    STUDIES    //
//               //
//               //
///////////////////


contract STUDY is ERC721Creator {
    constructor() ERC721Creator("STUDIES", "STUDY") {}
}