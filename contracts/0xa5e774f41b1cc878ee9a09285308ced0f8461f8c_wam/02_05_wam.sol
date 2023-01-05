// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bacchanalia of the Mfers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    nngmi    //
//             //
//             //
/////////////////


contract wam is ERC721Creator {
    constructor() ERC721Creator("Bacchanalia of the Mfers", "wam") {}
}