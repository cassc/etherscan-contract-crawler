// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Letter to my mother
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    nftlisa    //
//               //
//               //
///////////////////


contract LTM is ERC721Creator {
    constructor() ERC721Creator("Letter to my mother", "LTM") {}
}