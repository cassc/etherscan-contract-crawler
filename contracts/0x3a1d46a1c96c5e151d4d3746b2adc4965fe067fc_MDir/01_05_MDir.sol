// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Malko Diris
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    MDir    //
//            //
//            //
////////////////


contract MDir is ERC721Creator {
    constructor() ERC721Creator("Malko Diris", "MDir") {}
}