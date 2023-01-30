// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ManFish
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    💁‍♂️🐟    //
//               //
//               //
///////////////////


contract MFF is ERC721Creator {
    constructor() ERC721Creator("ManFish", "MFF") {}
}