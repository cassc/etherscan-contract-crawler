// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: La-minim
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//     ._ _  o ._  o ._ _   _. |     //
//     | | | | | | | | | | (_| |     //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract ML is ERC721Creator {
    constructor() ERC721Creator("La-minim", "ML") {}
}