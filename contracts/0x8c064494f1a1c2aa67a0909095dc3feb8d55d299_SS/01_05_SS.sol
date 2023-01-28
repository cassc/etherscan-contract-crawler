// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soul Snatcher
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Soul Snatcher    //
//                     //
//                     //
/////////////////////////


contract SS is ERC721Creator {
    constructor() ERC721Creator("Soul Snatcher", "SS") {}
}