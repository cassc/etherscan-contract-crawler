// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mochi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    mochiisi    //
//                //
//                //
////////////////////


contract MO is ERC721Creator {
    constructor() ERC721Creator("Mochi", "MO") {}
}