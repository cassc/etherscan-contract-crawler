// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    KDM    //
//           //
//           //
///////////////


contract KDM is ERC721Creator {
    constructor() ERC721Creator("KD", "KDM") {}
}