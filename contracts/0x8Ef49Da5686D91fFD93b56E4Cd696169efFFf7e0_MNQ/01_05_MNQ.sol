// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Medusa The nude Queen
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Medusa The nude Queen     //
//                              //
//                              //
//////////////////////////////////


contract MNQ is ERC721Creator {
    constructor() ERC721Creator("Medusa The nude Queen", "MNQ") {}
}