// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: She-is-MAFIATH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    MU-3    //
//            //
//            //
////////////////


contract MAFIATH is ERC721Creator {
    constructor() ERC721Creator("She-is-MAFIATH", "MAFIATH") {}
}