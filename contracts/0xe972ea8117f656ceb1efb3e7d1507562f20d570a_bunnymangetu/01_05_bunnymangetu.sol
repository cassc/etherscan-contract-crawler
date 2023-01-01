// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: happy new year 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    (*'v'*)    //
//               //
//               //
///////////////////


contract bunnymangetu is ERC721Creator {
    constructor() ERC721Creator("happy new year 2023", "bunnymangetu") {}
}