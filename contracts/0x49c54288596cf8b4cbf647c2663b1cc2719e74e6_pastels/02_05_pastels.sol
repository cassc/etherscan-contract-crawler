// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pastels - Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    pastels    //
//               //
//               //
///////////////////


contract pastels is ERC721Creator {
    constructor() ERC721Creator("Pastels - Edition", "pastels") {}
}