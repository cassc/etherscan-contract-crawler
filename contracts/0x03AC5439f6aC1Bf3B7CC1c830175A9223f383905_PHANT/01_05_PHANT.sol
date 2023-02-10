// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phantasmic
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//     .-.       //
//    (o o)      //
//    | O \      //
//     \   \     //
//      `~~~'    //
//               //
//               //
///////////////////


contract PHANT is ERC721Creator {
    constructor() ERC721Creator("Phantasmic", "PHANT") {}
}